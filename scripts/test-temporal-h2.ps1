[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = 'nl-th2-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$envFile = Join-Path ([IO.Path]::GetTempPath()) "$project.env"
$fixture = Join-Path ([IO.Path]::GetTempPath()) $project
$names = @('H1_BOOTSTRAP','H1_MIGRATION','H1_EXECUTION','H1_VISIBILITY')
foreach ($name in ($names + @('COMPOSE_FILE','COMPOSE_PROFILES','H2_PUBLIC_DIR','H2_SERVER_DIR'))) {
    if (Test-Path "Env:$name") { throw "Unset $name before isolated acceptance." }
}
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.temporal-hardened.yaml'),'-f',(Join-Path $root 'compose/compose.temporal-h2.yaml'))
$oldAddress = [Environment]::GetEnvironmentVariable('TEMPORAL_ADDRESS','Process')
$secrets = @{}
foreach ($name in $names) { $secrets[$name] = [guid]::NewGuid().ToString('N') }
function Invoke-Compose {
    & docker compose @compose @args
    if ($LASTEXITCODE -ne 0) { throw "Compose command failed: $($args[0])" }
}
function Invoke-Sdk {
    param([string]$File,[string[]]$Arguments)
    Push-Location (Join-Path $root 'tests/temporal')
    try {
        & pnpm exec tsx $File @Arguments
        if ($LASTEXITCODE -ne 0) { throw "SDK fixture failed: $File" }
    } finally { Pop-Location }
}
try {
    $names | ForEach-Object { "$_=$($secrets[$_])" } | Set-Content -LiteralPath $envFile -Encoding utf8
    $null = New-Item -ItemType Directory -Path $fixture
    & (Join-Path $PSScriptRoot 'new-temporal-h2-certificates.ps1') -Directory $fixture
    Add-Content -LiteralPath $envFile -Value @("H2_PUBLIC_DIR=$((Join-Path $fixture 'public').Replace('\','/'))","H2_SERVER_DIR=$((Join-Path $fixture 'server').Replace('\','/'))")
    Push-Location (Join-Path $root 'tests/temporal')
    try {
        & pnpm install --frozen-lockfile
        if ($LASTEXITCODE -ne 0) { throw 'Frozen SDK install failed.' }
    } finally { Pop-Location }
    Invoke-Sdk 'src/h2-acceptance.ts' @('keys',$fixture)
    Invoke-Compose up -d --wait postgres-temporal
    Invoke-Compose run --rm --no-deps migrate
    Get-Content -Raw (Join-Path $root 'temporal/hardened/finalise.sql') | & docker compose @compose exec -T postgres-temporal psql -X -U temporal_bootstrap -d postgres -v ON_ERROR_STOP=1
    if ($LASTEXITCODE -ne 0) { throw 'Privilege finalisation failed.' }
    Invoke-Compose up -d jwks
    Invoke-Compose up -d temporal
    $ready = $false
    for ($i=0; $i -lt 40; $i++) {
        $address = (& docker compose @compose port temporal 7233 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $address -match '^127\.0\.0\.1:\d+$') {
            $env:TEMPORAL_ADDRESS = $address
            try {
                Invoke-Sdk 'src/h2-acceptance.ts' @('bootstrap',$fixture)
                $ready = $true
                break
            } catch { Write-Host "Authenticated bootstrap attempt $($i+1) failed." }
        }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) { throw 'Authenticated namespace bootstrap failed.' }
    Invoke-Sdk 'src/h2-acceptance.ts' @('accept',$fixture)
    Write-Host 'PASS: H2 mutual TLS, signed JWTs, scoped authorisation and workflow execution.'
} catch {
    if (Test-Path -LiteralPath $envFile) {
        & docker compose @compose ps -a
        $logs = & docker compose @compose logs --no-color --tail 80 postgres-temporal temporal jwks 2>&1
        foreach ($line in $logs) {
            $message = [string]$line
            foreach ($secret in $secrets.Values) { $message = $message.Replace($secret,'[REDACTED]') }
            Write-Host $message
        }
    }
    throw
} finally {
    [Environment]::SetEnvironmentVariable('TEMPORAL_ADDRESS',$oldAddress,'Process')
    if (Test-Path -LiteralPath $envFile) {
        & docker compose @compose down --volumes --remove-orphans
        $cleanup = $LASTEXITCODE
        Remove-Item -LiteralPath $envFile -Force
        if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
        if ($cleanup -ne 0) { throw "H2 cleanup failed for $project" }
    }
}
