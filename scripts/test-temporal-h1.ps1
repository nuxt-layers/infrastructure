[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = 'nl-th1-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$envFile = Join-Path ([IO.Path]::GetTempPath()) "$project.env"
$names = @('H1_BOOTSTRAP','H1_MIGRATION','H1_EXECUTION','H1_VISIBILITY')
foreach ($name in ($names + @('COMPOSE_FILE','COMPOSE_PROFILES'))) {
    if (Test-Path "Env:$name") { throw "Unset $name before isolated acceptance." }
}
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.temporal-hardened.yaml'))
$oldAddress = [Environment]::GetEnvironmentVariable('TEMPORAL_ADDRESS','Process')
$secrets = @{}
foreach ($name in $names) { $secrets[$name] = [guid]::NewGuid().ToString('N') }
function Invoke-Compose {
    & docker compose @compose @args
    if ($LASTEXITCODE -ne 0) { throw "Compose command failed: $($args[0])" }
}
function Invoke-Sql {
    param([string]$Role,[string]$Database,[string]$Sql,[string]$SecretName,[switch]$Deny)
    # The shell in the PostgreSQL container reads the fixture secret from its own environment.
    # Never put the password in command-line arguments.
    $output = $Sql | & docker compose @compose exec -T postgres-temporal sh -ec 'export PGPASSWORD="$(printenv "$1")"; exec psql -X -h 127.0.0.1 -U "$2" -d "$3" -At -v ON_ERROR_STOP=1 -v VERBOSITY=verbose' sh $SecretName $Role $Database 2>&1
    $code = $LASTEXITCODE
    $message = ($output | Out-String).Trim()
    if ($Deny) {
        if ($code -eq 0 -or $message -notmatch '42501') { throw "Expected SQLSTATE 42501 for $Role / $Database; got: $message" }
        Write-Host "PASS: denied $Role / $Database : $Sql"
        return
    }
    if ($code -ne 0) { throw "SQL failed for $Role / $Database : $message" }
    return $message
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
    Invoke-Compose up -d --wait postgres-temporal
    Invoke-Compose run --rm --no-deps migrate
    Get-Content -Raw (Join-Path $root 'temporal/hardened/finalise.sql') | & docker compose @compose exec -T postgres-temporal psql -X -U temporal_bootstrap -d postgres -v ON_ERROR_STOP=1
    if ($LASTEXITCODE -ne 0) { throw 'Privilege finalisation failed.' }
    $pairs = @(
        @{ Role='temporal_execution'; Database='temporal'; Secret='H1_EXECUTION'; Version='1.16' },
        @{ Role='temporal_visibility_runtime'; Database='temporal_visibility'; Secret='H1_VISIBILITY'; Version='1.9' }
    )
    foreach ($pair in $pairs) {
        $role = $pair.Role; $database = $pair.Database; $secret = $pair.Secret
        $version = Invoke-Sql $role $database 'SELECT curr_version FROM schema_version' $secret
        if ($version -ne $pair.Version) { throw "Unexpected schema version: $database / $version" }
        Write-Host "PASS: $database schema $version, actual TCP runtime login"
        $flags = Invoke-Sql $role $database "SELECT (NOT rolsuper AND NOT rolcreatedb AND NOT rolcreaterole AND NOT rolreplication AND NOT rolbypassrls)::text FROM pg_roles WHERE rolname=current_user" $secret
        if ($flags -ne 'true') { throw "Elevated runtime role: $role" }
        Invoke-Sql $role $database 'CREATE TABLE public.forbidden_probe(id int)' $secret -Deny
        Invoke-Sql $role $database 'UPDATE schema_version SET curr_version=curr_version' $secret -Deny
        Invoke-Sql $role $database 'SET ROLE temporal_migration' $secret -Deny
        $other = if ($database -eq 'temporal') { 'temporal_visibility' } else { 'temporal' }
        # Connection failures have SQLSTATE in verbose psql output on supported clients;
        # use a catalogue check plus an actual TCP rejection with its explicit error text.
        $canConnect = Invoke-Sql $role $database "SELECT has_database_privilege(current_user,'$other','CONNECT')::text" $secret
        if ($canConnect -ne 'false') { throw "Cross-database CONNECT granted: $role" }
        $denial = & docker compose @compose exec -T postgres-temporal sh -ec 'export PGPASSWORD="$(printenv "$1")"; exec psql -X -h 127.0.0.1 -U "$2" -d "$3" -c "SELECT 1"' sh $secret $role $other 2>&1
        if ($LASTEXITCODE -eq 0 -or ($denial | Out-String) -notmatch 'permission denied for database') { throw "Expected cross-database connection denial: $role" }
        Write-Host "PASS: cross-database login denied for $role"
    }
    $disabled = & docker compose @compose exec -T postgres-temporal psql -X -U temporal_bootstrap -d postgres -At -c "SELECT NOT rolcanlogin FROM pg_roles WHERE rolname='temporal_migration'"
    if ($LASTEXITCODE -ne 0 -or ($disabled | Out-String).Trim() -ne 't') { throw 'Migration login not disabled.' }
    Write-Host 'PASS: migration login disabled'
    Invoke-Compose up -d temporal
    Push-Location (Join-Path $root 'tests/temporal')
    try {
        & pnpm install --frozen-lockfile
        if ($LASTEXITCODE -ne 0) { throw 'Frozen SDK install failed.' }
    } finally { Pop-Location }
    $ready = $false
    for ($i=0; $i -lt 30; $i++) {
        $address = (& docker compose @compose port temporal 7233 | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $address -match '^127\.0\.0\.1:\d+$') {
            $env:TEMPORAL_ADDRESS = $address
            try {
                Invoke-Sdk 'src/hardened-bootstrap.ts' @()
                $ready = $true
                break
            } catch { Write-Host "Bootstrap readiness attempt $($i+1): $($_.Exception.Message)" }
        }
        Start-Sleep -Seconds 2
    }
    if (-not $ready) { throw 'Explicit frontend bootstrap failed.' }
    $ready = $false
    for ($i=0; $i -lt 20; $i++) {
        try { Invoke-Sdk 'src/phase3-acceptance.ts' @('probe','readiness'); $ready = $true; break }
        catch { Start-Sleep -Seconds 2 }
    }
    if (-not $ready) { throw 'Namespace readiness failed.' }
    $id = 'infra-phase3-' + [guid]::NewGuid().ToString('N')
    Invoke-Sdk 'src/functional-acceptance.ts' @('visibility',$id)
    Write-Host 'PASS: H1 explicit migrations, restricted database runtime and real workflow visibility.'
} catch {
    if (Test-Path -LiteralPath $envFile) {
        & docker compose @compose ps -a
        $logs = & docker compose @compose logs --no-color --tail 80 postgres-temporal temporal 2>&1
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
        if ($cleanup -ne 0) { throw "H1 cleanup failed for $project" }
    }
}
