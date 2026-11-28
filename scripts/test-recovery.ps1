[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[0-9][0-9a-zA-Z.+:~-]*$')][string]$PgBackRestVersion)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
foreach ($name in @('PGBACKREST_VERSION','RECOVERY_DB_SECRET','RECOVERY_REPO_SECRET','COMPOSE_FILE','COMPOSE_PROFILES')) {
    if (Test-Path "Env:$name") { throw "Unset $name before acceptance." }
}
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = 'nl-recovery-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$envFile = Join-Path ([IO.Path]::GetTempPath()) "$project.env"
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.recovery.yaml'))
function Invoke-Compose {
    & docker compose @compose @args
    if ($LASTEXITCODE -ne 0) { throw 'Recovery fixture command failed.' }
}
function Invoke-Sql([string]$Service,[string]$Sql) {
    Invoke-Compose exec -T -u postgres $Service psql -X -At -v ON_ERROR_STOP=1 -d postgres -c $Sql
}
try {
    @("PGBACKREST_VERSION=$PgBackRestVersion","RECOVERY_DB_SECRET=$([guid]::NewGuid().ToString('N'))","RECOVERY_REPO_SECRET=$([guid]::NewGuid().ToString('N'))$([guid]::NewGuid().ToString('N'))") | Set-Content -Encoding utf8 $envFile
    Invoke-Compose build database
    Invoke-Compose run --rm --no-deps prepare
    Invoke-Compose up -d --wait database
    Invoke-Sql database "CREATE TABLE recovery_probe(id integer PRIMARY KEY); INSERT INTO recovery_probe VALUES (1);"
    Invoke-Compose exec -T -u postgres database pgbackrest --stanza=fixture check
    Invoke-Compose exec -T -u postgres database pgbackrest --stanza=fixture --type=full backup
    Invoke-Sql database "INSERT INTO recovery_probe VALUES (2);"
    Invoke-Sql database "SELECT pg_create_restore_point('fixture_target');"
    Invoke-Sql database "DELETE FROM recovery_probe;"
    Invoke-Sql database "SELECT pg_switch_wal();"
    Invoke-Compose exec -T -u postgres database pgbackrest --stanza=fixture check
    $timer = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Compose stop database
    Invoke-Compose run --rm --no-deps restore --stanza=fixture --type=name --target=fixture_target --target-action=promote restore
    Invoke-Compose up -d --wait recovered
    $result = ''
    for ($i=0;$i -lt 30;$i++) {
        $result = (Invoke-Sql recovered "SELECT CASE WHEN pg_is_in_recovery() THEN 'recovering' ELSE (SELECT string_agg(id::text,',' ORDER BY id) FROM recovery_probe) END;" | Out-String).Trim()
        if ($result -eq '1,2') { break }
        Start-Sleep -Seconds 2
    }
    if ($result -ne '1,2') { throw 'Point-in-time restore did not reproduce the expected rows.' }
    $timer.Stop()
    Write-Host "Observed database recovery seconds: $($timer.Elapsed.TotalSeconds)"
    Write-Host 'PASS: encrypted pgBackRest full backup and WAL point-in-time restoration into independent volume.'
} finally {
    if (Test-Path $envFile) {
        & docker compose @compose --profile tools down --volumes --remove-orphans
        if ($LASTEXITCODE -ne 0) { Write-Warning "Cleanup failed for $project" }
        Remove-Item -LiteralPath $envFile -Force
    }
}
