[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) { throw 'Missing .env.' }
$compose = @('--env-file', (Join-Path $root '.env'), '-f', (Join-Path $root 'compose/compose.yaml'), '-f', (Join-Path $root 'compose/compose.dev.yaml'))
$applicationSql = Get-Content -Raw (Join-Path $root 'postgres/migrations/001-enable-application-extensions.sql')
$maintenanceSql = Get-Content -Raw (Join-Path $root 'postgres/migrations/002-enable-maintenance-extension.sql')
$applicationSql | & docker compose @compose exec -T postgres-app sh -c 'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
if ($LASTEXITCODE -ne 0) { throw 'Application extension migration failed.' }
$maintenanceSql | & docker compose @compose exec -T postgres-app sh -c 'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres'
if ($LASTEXITCODE -ne 0) { throw 'Maintenance extension migration failed.' }
Write-Host 'Extensions enabled. Review versioned schema changes before upgrading extensions.'
