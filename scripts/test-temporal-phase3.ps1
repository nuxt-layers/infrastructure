[CmdletBinding()]
param([ValidateSet('All','Startup','Execution','Recovery','Functional','Schedule','Heartbeat','Visibility','Separation','Crash')][string]$Stage = 'All')
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = 'nl-tp3-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$envFile = Join-Path ([IO.Path]::GetTempPath()) "$project.env"
foreach ($name in @('TEMPORAL_FIXTURE_PASSWORD','COMPOSE_FILE','COMPOSE_PROFILES')) {
    if (Test-Path "Env:$name") { throw "Unset $name before isolated acceptance." }
}
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.temporal-acceptance.yaml'))
$oldAddress = [Environment]::GetEnvironmentVariable('TEMPORAL_ADDRESS','Process')
function Wait-Frontend {
    for ($i=0; $i -lt 90; $i++) {
        & docker compose @compose exec -T temporal tctl --address temporal:7233 namespace describe default *> $null
        if ($LASTEXITCODE -eq 0) { return }
        Start-Sleep -Seconds 2
    }
    throw 'Temporal frontend failed readiness.'
}
function Set-FrontendAddress {
    $address = (& docker compose @compose port temporal 7233 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $address -notmatch '^127\.0\.0\.1:\d+$') { throw 'Frontend is not published to loopback.' }
    $env:TEMPORAL_ADDRESS = $address
    Write-Host "Published Temporal frontend: $address"
}
function Wait-HostFrontend {
    for ($i=0; $i -lt 12; $i++) {
        Set-FrontendAddress
        Push-Location (Join-Path $root 'tests/temporal')
        try {
            & pnpm exec tsx src/phase3-acceptance.ts probe readiness
            $ok = $LASTEXITCODE -eq 0
        } finally { Pop-Location }
        if ($ok) { return }
        Start-Sleep -Seconds 2
    }
    throw 'Published Temporal frontend failed host SDK readiness.'
}
function Invoke-Harness {
    param([string]$Mode,[string]$Id)
    Push-Location (Join-Path $root 'tests/temporal')
    try {
        & pnpm exec tsx src/phase3-acceptance.ts $Mode $Id
        if ($LASTEXITCODE -ne 0) { throw "Temporal harness failed: $Mode" }
    } finally { Pop-Location }
}
function Invoke-Functional {
    param([string]$Mode)
    $id = 'infra-phase3-' + [guid]::NewGuid().ToString('N')
    Push-Location (Join-Path $root 'tests/temporal')
    try {
        & pnpm exec tsx src/functional-acceptance.ts $Mode $id
        if ($LASTEXITCODE -ne 0) { throw "Functional harness failed: $Mode" }
    } finally { Pop-Location }
}
try {
    "TEMPORAL_FIXTURE_PASSWORD=$([guid]::NewGuid().ToString('N'))" | Set-Content -Encoding utf8 $envFile
    & docker compose @compose up -d --wait
    if ($LASTEXITCODE -ne 0) { throw 'Temporal fixture startup failed.' }
    Wait-Frontend
    $version = & docker compose @compose exec -T postgres-temporal psql -X -At -v ON_ERROR_STOP=1 -U temporal_fixture -d postgres -c 'SHOW server_version_num'
    if ($LASTEXITCODE -ne 0 -or ($version | Out-String).Trim() -notmatch '^18\d{4}$') { throw 'Expected PostgreSQL 18.' }
    foreach ($database in @('temporal','temporal_visibility')) {
        & docker compose @compose exec -T postgres-temporal psql -X -v ON_ERROR_STOP=1 -U temporal_fixture -d $database -c 'SELECT * FROM schema_version'
        if ($LASTEXITCODE -ne 0) { throw "Schema version unavailable: $database" }
    }
    Set-FrontendAddress
    foreach ($service in @('postgres-temporal','temporal')) {
        $id = & docker compose @compose ps -q $service
        if ($LASTEXITCODE -ne 0 -or -not $id) { throw "Missing container: $service" }
        & docker inspect --format '{{.Config.Image}} {{.Image}}' $id
        if ($LASTEXITCODE -ne 0) { throw 'Image identity inspection failed.' }
        $image = & docker inspect --format '{{.Image}}' $id
        if ($LASTEXITCODE -ne 0) { throw 'Image ID inspection failed.' }
        & docker image inspect --format '{{json .RepoDigests}}' $image
        if ($LASTEXITCODE -ne 0) { throw 'Image digest inspection failed.' }
    }
    Write-Host 'PASS: frontend, PostgreSQL major version, separate execution and visibility schemas.'
    if ($Stage -ne 'Startup') {
        Push-Location (Join-Path $root 'tests/temporal')
        try {
            & pnpm install --frozen-lockfile
            if ($LASTEXITCODE -ne 0) { throw 'Frozen SDK install failed.' }
        } finally { Pop-Location }
        Wait-HostFrontend
        $workflowId = 'infra-phase3-' + [guid]::NewGuid().ToString('N')
        if ($Stage -in @('All','Execution','Recovery')) {
            Invoke-Harness 'execute' $workflowId
        }
        foreach ($mode in @('Schedule','Heartbeat','Visibility','Separation')) {
            if ($Stage -in @('All','Functional',$mode)) {
                Invoke-Functional ($mode.ToLowerInvariant())
            }
        }
        if ($Stage -in @('All','Functional','Crash')) {
            $crashId = $workflowId + '-crash'
            Invoke-Harness 'suspend' $crashId
            & docker compose @compose kill -s SIGKILL temporal
            if ($LASTEXITCODE -ne 0) { throw 'Temporal abrupt stop failed.' }
            & docker compose @compose kill -s SIGKILL postgres-temporal
            if ($LASTEXITCODE -ne 0) { throw 'Persistence abrupt stop failed.' }
            & docker compose @compose up -d --wait
            if ($LASTEXITCODE -ne 0) { throw 'Crash restart failed.' }
            Wait-Frontend
            Wait-HostFrontend
            Invoke-Harness 'resume' $crashId
            Invoke-Harness 'verify' $crashId
            Write-Host 'PASS: abrupt server and persistence termination, suspended workflow replay and durable result.'
        }
        if ($Stage -in @('All','Recovery')) {
            $pendingId = $workflowId + '-pending'
            Invoke-Harness 'suspend' $pendingId
            # Restart in dependency order, retaining the existing persistence volume.
            & docker compose @compose stop temporal
            if ($LASTEXITCODE -ne 0) { throw 'Temporal stop failed.' }
            & docker compose @compose restart postgres-temporal
            if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL restart failed.' }
            & docker compose @compose up -d --wait
            if ($LASTEXITCODE -ne 0) { throw 'Restart readiness failed.' }
            Wait-Frontend
            Wait-HostFrontend
            Invoke-Harness 'verify' $workflowId
            Invoke-Harness 'resume' $pendingId
            Invoke-Harness 'verify' $pendingId
        }
    }
    Write-Host "PASS: selected Temporal Phase 3 stage $Stage (not complete Phase 3 acceptance)."
} finally {
    [Environment]::SetEnvironmentVariable('TEMPORAL_ADDRESS',$oldAddress,'Process')
    if (Test-Path $envFile) {
        & docker compose @compose down --volumes --remove-orphans
        if ($LASTEXITCODE -ne 0) { Write-Warning "Cleanup failed for $project; inspect before removing." }
        Remove-Item $envFile -Force -ErrorAction SilentlyContinue
    }
}
