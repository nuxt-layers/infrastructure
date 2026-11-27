[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
# Dedicated ephemeral project, no host port override and no existing data volumes.
$project = 'nl-pg2-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$envFile = Join-Path ([System.IO.Path]::GetTempPath()) "$project.env"
$secret = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.yaml'))
try {
    # Shell environment takes precedence over Compose env files. Refuse overrides.
    foreach ($name in @('APP_POSTGRES_USER','APP_POSTGRES_PASSWORD','APP_POSTGRES_DB','COMPOSE_PROFILES','COMPOSE_FILE')) {
        if (Test-Path "Env:$name") { throw "Unset $name before running isolated acceptance." }
    }
    @("APP_POSTGRES_USER=fixture_admin","APP_POSTGRES_PASSWORD=$secret","APP_POSTGRES_DB=fixture_db","TEMPORAL_POSTGRES_USER=unused","TEMPORAL_POSTGRES_PASSWORD=$secret","TEMPORAL_DEV_VERSION=1.27.2","TEMPORAL_UI_VERSION=2.37.2") | Set-Content -Encoding utf8 $envFile
    & docker compose @compose up -d --build --wait postgres-app
    if ($LASTEXITCODE -ne 0) { throw 'Isolated PostgreSQL startup failed.' }
    foreach ($file in @('10-role-isolation.sql','11-outbox.sql')) {
        Get-Content -Raw (Join-Path $root "tests/postgres/$file") | & docker compose @compose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db
        if ($LASTEXITCODE -ne 0) { throw "Phase 2 fixture failed: $file" }
    }
    function Invoke-Fixture {
        param([string]$File)
        Get-Content -Raw (Join-Path $root "tests/postgres/$File") | & docker compose @compose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db
        if ($LASTEXITCODE -ne 0) { throw "Fixture failed: $File" }
    }
    function Invoke-Admin {
        param([string]$Sql)
        $Sql | & docker compose @compose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db
        if ($LASTEXITCODE -ne 0) { throw 'Admin fixture failed.' }
    }
    Get-Content -Raw (Join-Path $root 'postgres/provision/owner.sql') | & docker compose @compose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db -v owner_schema=infra_login -v migration_role=nl_accept_migration -v runtime_role=nl_accept_runtime -v diagnostic_role=nl_accept_diagnostic
    if ($LASTEXITCODE -ne 0) { throw 'Owner provisioning failed.' }
    $migrationSecret = [guid]::NewGuid().ToString('N')
    $runtimeSecret = [guid]::NewGuid().ToString('N')
    $diagnosticSecret = [guid]::NewGuid().ToString('N')
    Get-Content -Raw (Join-Path $root 'tests/postgres/15-login-setup.sql') | & docker compose @compose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db -v "migration_secret=$migrationSecret" -v "runtime_secret=$runtimeSecret" -v "diagnostic_secret=$diagnosticSecret"
    if ($LASTEXITCODE -ne 0) { throw 'Login setup failed.' }
    foreach ($login in @(@{Role='nl_accept_migration';Secret=$migrationSecret;File='16-login-migration.sql'},@{Role='nl_accept_runtime';Secret=$runtimeSecret;File='17-login-runtime.sql'},@{Role='nl_accept_diagnostic';Secret=$diagnosticSecret;File='18-login-diagnostic.sql'})) {
        Get-Content -Raw (Join-Path $root "tests/postgres/$($login.File)") | & docker compose @compose exec -T -e "PGPASSWORD=$($login.Secret)" postgres-app psql -X -h 127.0.0.1 -v ON_ERROR_STOP=1 -U $login.Role -d fixture_db
        if ($LASTEXITCODE -ne 0) { throw "Real login fixture failed: $($login.Role)" }
    }
    foreach ($pair in @(@{Setup='19-scoped-search-setup.sql';Runtime='20-scoped-search-runtime.sql'},@{Setup='21-scoped-transport-setup.sql';Runtime='22-scoped-transport-runtime.sql'},@{Setup='23-scoped-graph-setup.sql';Runtime='24-scoped-graph-runtime.sql'})) {
        Invoke-Fixture $pair.Setup
        Get-Content -Raw (Join-Path $root "tests/postgres/$($pair.Runtime)") | & docker compose @compose exec -T -e "PGPASSWORD=$runtimeSecret" postgres-app psql -X -h 127.0.0.1 -v ON_ERROR_STOP=1 -U nl_accept_runtime -d fixture_db
        if ($LASTEXITCODE -ne 0) { throw "Scoped extension fixture failed: $($pair.Runtime)" }
    }
    # Separate psql processes: listener establishes LISTEN then signals readiness
    # using an advisory lock. Publisher waits for that lock, not an arbitrary sleep.
    $composeJson = ConvertTo-Json -InputObject $compose -Compress
    $listener = Start-Job -ArgumentList $composeJson -ScriptBlock {
        param($json)
        $argsForCompose = @(ConvertFrom-Json $json)
        @("LISTEN infra_phase2_wake;", "SELECT pg_advisory_lock(827361);", "SELECT pg_sleep(30);", "SELECT pg_advisory_unlock(827361);") | & docker compose @argsForCompose exec -T postgres-app psql -X -v ON_ERROR_STOP=1 -U fixture_admin -d fixture_db
        if ($LASTEXITCODE -ne 0) { throw 'Listener failed.' }
    }
    try {
        $ready = $false
        for ($i=0; $i -lt 40; $i++) {
            $probe = & docker compose @compose exec -T postgres-app psql -X -At -U fixture_admin -d fixture_db -c "SELECT EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND objid=827361 AND granted)"
            if ($LASTEXITCODE -ne 0) { throw 'Listener probe failed.' }
            if (($probe | Out-String).Trim() -eq 't') { $ready=$true; break }
            Start-Sleep -Milliseconds 100
        }
        if (-not $ready) { throw 'Listener did not establish readiness.' }
        Invoke-Admin "NOTIFY infra_phase2_wake, 'fixture-event';"
        $received = Receive-Job $listener -Wait -ErrorAction Stop | Out-String
        if ($listener.State -ne 'Completed' -or $received -notmatch 'fixture-event') { throw 'Cross-session notification missing.' }
    } finally {
        Remove-Job $listener -Force
    }
    # Role connection quota is an infrastructure pressure fixture, not a client pool test.
    Invoke-Admin 'ALTER ROLE nl_accept_runtime CONNECTION LIMIT 1;'
    $holder = Start-Job -ArgumentList $composeJson,$runtimeSecret -ScriptBlock {
        param($json,$password)
        $argsForCompose = @(ConvertFrom-Json $json)
        @('SELECT pg_advisory_lock(827362);','SELECT pg_sleep(30);') | & docker compose @argsForCompose exec -T -e "PGPASSWORD=$password" postgres-app psql -X -h 127.0.0.1 -v ON_ERROR_STOP=1 -U nl_accept_runtime -d fixture_db
        if ($LASTEXITCODE -ne 0) { throw 'Connection holder failed.' }
    }
    try {
        $ready = $false
        for ($i=0; $i -lt 40; $i++) {
            $probe = & docker compose @compose exec -T postgres-app psql -X -At -U fixture_admin -d fixture_db -c "SELECT EXISTS(SELECT 1 FROM pg_locks WHERE locktype='advisory' AND objid=827362 AND granted)"
            if ($LASTEXITCODE -ne 0) { throw 'Connection holder probe failed.' }
            if (($probe | Out-String).Trim() -eq 't') { $ready=$true; break }
            Start-Sleep -Milliseconds 100
        }
        if (-not $ready) { throw 'Connection holder not ready.' }
        $rejected = & docker compose @compose exec -T -e "PGPASSWORD=$runtimeSecret" -e LC_ALL=C postgres-app psql -X -h 127.0.0.1 -U nl_accept_runtime -d fixture_db -c 'SELECT 1' 2>&1
        if ($LASTEXITCODE -eq 0 -or ($rejected | Out-String) -notmatch 'too many connections for role') { throw 'Expected role connection limit rejection.' }
        Receive-Job $holder -Wait -ErrorAction Stop | Out-Null
        if ($holder.State -ne 'Completed') { throw 'Connection holder failed.' }
        & docker compose @compose exec -T -e "PGPASSWORD=$runtimeSecret" postgres-app psql -X -h 127.0.0.1 -v ON_ERROR_STOP=1 -U nl_accept_runtime -d fixture_db -c 'SELECT 1'
        if ($LASTEXITCODE -ne 0) { throw 'Connection recovery failed.' }
    } finally {
        Remove-Job $holder -Force
        Invoke-Admin 'ALTER ROLE nl_accept_runtime CONNECTION LIMIT -1;'
    }
    Invoke-Fixture '12-committed-outbox.sql'
    Invoke-Fixture '13-crash-setup.sql'
    $containerId = & docker compose @compose ps -q postgres-app
    if ($LASTEXITCODE -ne 0 -or -not $containerId) { throw 'Cannot identify crash fixture container.' }
    $actualProject = & docker inspect --format '{{index .Config.Labels "com.docker.compose.project"}}' $containerId
    if ($LASTEXITCODE -ne 0 -or $actualProject -ne $project -or $project -notmatch '^nl-pg2-[0-9a-f]{12}$') { throw 'Refusing crash outside isolated fixture.' }
    # SIGKILL only the uniquely named ephemeral project, never shared volumes.
    & docker compose @compose kill -s SIGKILL postgres-app
    if ($LASTEXITCODE -ne 0) { throw 'Crash injection failed.' }
    & docker compose @compose up -d --wait postgres-app
    if ($LASTEXITCODE -ne 0) { throw 'Crash recovery startup failed.' }
    Invoke-Fixture '14-crash-verify.sql'
    Write-Host 'PASS: isolated Phase 2 authored SQL, login, notify and crash fixtures (not full Phase 2 acceptance).'
} finally {
    & docker compose @compose down --volumes --remove-orphans
    if ($LASTEXITCODE -ne 0) { Write-Warning "Cleanup failed for isolated project $project; inspect before removing." }
    Remove-Item $envFile -Force -ErrorAction SilentlyContinue
}
