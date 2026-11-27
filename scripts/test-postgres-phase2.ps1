[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
# Dedicated ephemeral project, no host port override and no existing data volumes.
$project = 'nl-pg2-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$envFile = Join-Path ([System.IO.Path]::GetTempPath()) "$project.env"
$secret = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.yaml'))
try {
    @("APP_POSTGRES_USER=fixture_admin","APP_POSTGRES_PASSWORD=$secret","APP_POSTGRES_DB=fixture_db","TEMPORAL_POSTGRES_USER=unused","TEMPORAL_POSTGRES_PASSWORD=$secret","TEMPORAL_DEV_VERSION=1.27.2","TEMPORAL_UI_VERSION=2.37.2") | Set-Content -Encoding utf8 $envFile
    & docker compose @compose up -d --build --wait postgres-app
    if ($LASTEXITCODE -ne 0) { throw 'Isolated PostgreSQL startup failed.' }
    foreach ($file in @('10-role-isolation.sql','11-outbox.sql')) {
        Get-Content -Raw (Join-Path $root "tests/postgres/$file") | & docker compose @compose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db
        if ($LASTEXITCODE -ne 0) { throw "Phase 2 fixture failed: $file" }
    }
    Write-Host 'PASS: isolated Phase 2 SQL fixtures (not full Phase 2 acceptance).'
} finally {
    & docker compose @compose down --volumes --remove-orphans
    if ($LASTEXITCODE -ne 0) { Write-Warning "Cleanup failed for isolated project $project; inspect before removing." }
    Remove-Item $envFile -Force -ErrorAction SilentlyContinue
}
