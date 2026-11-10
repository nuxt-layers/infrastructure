[CmdletBinding()]
param([switch]$Temporal)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) { throw 'Missing .env.' }
$compose = @('--env-file', (Join-Path $root '.env'), '-f', (Join-Path $root 'compose/compose.yaml'), '-f', (Join-Path $root 'compose/compose.dev.yaml'))
if ($Temporal) { $compose += @('--profile', 'temporal') }
& docker compose @compose ps
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect Docker Compose services.' }
& docker compose @compose exec -T postgres-app sh -c 'pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
if ($LASTEXITCODE -ne 0) { throw 'Application PostgreSQL is not ready.' }
& docker compose @compose exec -T postgres-app sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT current_setting(''server_version'')"'
if ($LASTEXITCODE -ne 0) { throw 'Application PostgreSQL SQL probe failed.' }
if ($Temporal) {
    & docker compose @compose exec -T postgres-temporal sh -c 'pg_isready -U "$POSTGRES_USER"'
    if ($LASTEXITCODE -ne 0) { throw 'Temporal PostgreSQL is not ready.' }
    Write-Host 'Temporal service and UI status shown above; full workflow acceptance still pending.'
}
