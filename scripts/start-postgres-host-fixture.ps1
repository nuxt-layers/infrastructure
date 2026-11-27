[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = 'nl-pghost-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$folder = Join-Path ([System.IO.Path]::GetTempPath()) $project
$admin = [guid]::NewGuid().ToString('N')
$password = [guid]::NewGuid().ToString('N')
foreach ($name in @('APP_POSTGRES_USER','APP_POSTGRES_PASSWORD','APP_POSTGRES_DB','COMPOSE_PROFILES','COMPOSE_FILE')) {
    if (Test-Path "Env:$name") { throw "Unset $name before running isolated host fixture." }
}
New-Item -ItemType Directory -Path $folder | Out-Null
$envFile = Join-Path $folder 'fixture.env'
$override = Join-Path $folder 'fixture.yaml'
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.yaml'),'-f',$override)
try {
    @("APP_POSTGRES_USER=fixture_admin","APP_POSTGRES_PASSWORD=$admin","APP_POSTGRES_DB=fixture_db","TEMPORAL_POSTGRES_USER=unused","TEMPORAL_POSTGRES_PASSWORD=$admin","TEMPORAL_DEV_VERSION=1.27.2","TEMPORAL_UI_VERSION=2.37.2") | Set-Content -Encoding utf8 $envFile
    @'
services:
  postgres-app:
    ports:
      - "127.0.0.1::5432"
'@ | Set-Content -Encoding utf8 $override
    & docker compose @compose up -d --build --wait postgres-app
    if ($LASTEXITCODE -ne 0) { throw 'Fixture startup failed.' }
    Get-Content -Raw (Join-Path $root 'postgres/provision/owner.sql') | & docker compose @compose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db -v owner_schema=infra_host_fixture -v migration_role=nl_host_migration -v runtime_role=nl_host_runtime -v diagnostic_role=nl_host_diagnostic
    if ($LASTEXITCODE -ne 0) { throw 'Fixture role provisioning failed.' }
    @'
ALTER ROLE nl_host_diagnostic LOGIN PASSWORD :'diagnostic_secret';
REVOKE CONNECT,TEMP ON DATABASE fixture_db FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA pgmq,ag_catalog FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA pgmq,ag_catalog FROM PUBLIC;
SET ROLE nl_host_migration;
CREATE TABLE infra_host_fixture.private_record(id integer);
INSERT INTO infra_host_fixture.private_record VALUES (1);
RESET ROLE;
'@ | & docker compose @compose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db -v "diagnostic_secret=$password"
    if ($LASTEXITCODE -ne 0) { throw 'Fixture grant setup failed.' }
    $address = (& docker compose @compose port postgres-app 5432 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $address -notmatch '^127\.0\.0\.1:(\d+)$') { throw 'Fixture port is not loopback.' }
    $port = $Matches[1]
    Write-Host 'Copy these synthetic session-only assignments to the test application terminal. Do not commit or paste them into chat.'
    Write-Host ('$env:NUXT_INFRA_TEST_ENABLED = "true"')
    Write-Host ('$env:NUXT_INFRA_TEST_DATABASE_URL = "postgresql://nl_host_diagnostic:' + $password + '@127.0.0.1:' + $port + '/fixture_db"')
    Write-Host ('$env:NUXT_INFRA_TEST_TEMPORAL_ADDRESS = ""')
    Read-Host 'Press Enter after host acceptance to destroy disposable fixture' | Out-Null
} finally {
    if ((Test-Path $envFile) -and (Test-Path $override)) {
        & docker compose @compose down --volumes --remove-orphans
        if ($LASTEXITCODE -ne 0) { Write-Warning "Cleanup failed for $project; inspect before removing." }
    }
    Remove-Item $folder -Recurse -Force -ErrorAction SilentlyContinue
}
