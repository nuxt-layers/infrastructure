[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[0-9][0-9a-zA-Z.+:~-]*$')][string]$PgBackRestVersion)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = 'nl-tr-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$image = "${project}:fixture"
$envFile = Join-Path ([IO.Path]::GetTempPath()) "$project.env"
$names = @('H1_BOOTSTRAP','H1_MIGRATION','H1_EXECUTION','H1_VISIBILITY','RECOVERY_REPO_SECRET','TEMPORAL_RECOVERY_IMAGE')
foreach ($name in ($names + @('COMPOSE_FILE','COMPOSE_PROFILES'))) {
    if (Test-Path "Env:$name") { throw "Unset $name before acceptance." }
}
$secrets = @{}
foreach ($name in $names) { $secrets[$name] = [guid]::NewGuid().ToString('N') }
$secrets['TEMPORAL_RECOVERY_IMAGE'] = $image
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.temporal-hardened.yaml'),'-f',(Join-Path $root 'compose/compose.temporal-recovery.yaml'))
$oldAddress = [Environment]::GetEnvironmentVariable('TEMPORAL_ADDRESS','Process')
function Invoke-Compose {
    & docker compose @compose @args
    if ($LASTEXITCODE -ne 0) { throw "Temporal recovery command failed: $($args[0])" }
}
function Sql([string]$query) {
    Invoke-Compose exec -T -u postgres postgres-temporal psql -X -At -U temporal_bootstrap -d postgres -v ON_ERROR_STOP=1 -c $query
}
function Sdk([string]$file,[string[]]$arguments) {
    Push-Location (Join-Path $root 'tests/temporal')
    try {
        & pnpm exec tsx $file @arguments
        if ($LASTEXITCODE -ne 0) { throw "SDK failed: $file" }
    } finally { Pop-Location }
}
function Connect-Fixture([switch]$Bootstrap) {
    for ($i=0;$i -lt 40;$i++) {
        $address = (& docker compose @compose port temporal 7233 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $address -match '^127\.0\.0\.1:\d+$') {
            $env:TEMPORAL_ADDRESS = $address
            try {
                if ($Bootstrap) { Sdk 'src/hardened-bootstrap.ts' @() }
                Sdk 'src/phase3-acceptance.ts' @('probe','readiness')
                return
            } catch { Start-Sleep -Seconds 2 }
        } else { Start-Sleep -Seconds 2 }
    }
    throw 'Temporal frontend readiness failed.'
}
try {
    $names | ForEach-Object { "$_=$($secrets[$_])" } | Set-Content -LiteralPath $envFile -Encoding utf8
    & docker build --build-arg "PGBACKREST_VERSION=$PgBackRestVersion" -t $image (Join-Path $root 'recovery/postgres')
    if ($LASTEXITCODE -ne 0) { throw 'Recovery image build failed.' }
    Invoke-Compose run --rm --no-deps prepare-recovery
    Invoke-Compose up -d --wait postgres-temporal
    Invoke-Compose run --rm --no-deps migrate
    Get-Content -Raw (Join-Path $root 'temporal/hardened/finalise.sql') | & docker compose @compose exec -T postgres-temporal psql -X -U temporal_bootstrap -d postgres -v ON_ERROR_STOP=1
    if ($LASTEXITCODE -ne 0) { throw 'Privilege finalisation failed.' }
    Invoke-Compose up -d temporal
    Connect-Fixture -Bootstrap
    $id = 'recovery-' + [guid]::NewGuid().ToString('N')
    Sdk 'src/phase3-acceptance.ts' @('suspend',$id)
    Invoke-Compose stop temporal
    # Archive a consistent full backup while database remains online and workers are drained.
    Invoke-Compose exec -T -u postgres postgres-temporal pgbackrest --stanza=fixture --pg1-user=temporal_bootstrap check
    Invoke-Compose exec -T -u postgres postgres-temporal pgbackrest --stanza=fixture --pg1-user=temporal_bootstrap --type=full backup
    Sql "SELECT pg_create_restore_point('temporal_fixture_target');"
    Sql "SELECT pg_switch_wal();"
    Invoke-Compose exec -T -u postgres postgres-temporal pgbackrest --stanza=fixture --pg1-user=temporal_bootstrap check
    Invoke-Compose stop postgres-temporal
    Invoke-Compose run --rm --no-deps restore-temporal --stanza=fixture --type=name --target=temporal_fixture_target --target-action=promote restore
    $compose += @('-f',(Join-Path $root 'compose/compose.temporal-recovered.yaml'))
    Invoke-Compose up -d --wait --force-recreate postgres-temporal
    Invoke-Compose up -d --force-recreate temporal
    Connect-Fixture
    Sdk 'src/phase3-acceptance.ts' @('resume',$id)
    Sdk 'src/phase3-acceptance.ts' @('verify',$id)
    Write-Host 'PASS: restored Temporal execution/visibility cluster and resumed durable workflow without repeated completed activity.'
} finally {
    [Environment]::SetEnvironmentVariable('TEMPORAL_ADDRESS',$oldAddress,'Process')
    if (Test-Path $envFile) {
        & docker compose @compose --profile recovery down --volumes --remove-orphans
        $cleanup = $LASTEXITCODE
        Remove-Item -LiteralPath $envFile -Force
        if ($cleanup -ne 0) { throw 'Temporal recovery cleanup failed.' }
    }
}
