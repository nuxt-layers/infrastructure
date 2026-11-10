[CmdletBinding()]
param([switch]$SkipRestart)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) {
    throw 'Missing .env. Copy .env.example and configure local development credentials.'
}
$compose = @('--env-file', (Join-Path $root '.env'), '-f', (Join-Path $root 'compose/compose.yaml'), '-f', (Join-Path $root 'compose/compose.dev.yaml'))
function Invoke-DatabaseSql {
    param([string]$File, [string]$Database = 'app')
    $source = Join-Path $root "tests/postgres/$File"
    $sql = Get-Content -Raw $source
    if ($Database -eq 'maintenance') {
        $destination = 'postgres'
    } else {
        $destination = '$POSTGRES_DB'
    }
    $command = 'psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d ' + $destination
    $sql | & docker compose @compose exec -T postgres-app sh -c $command
    if ($LASTEXITCODE -ne 0) { throw "SQL acceptance failed: $File" }
}
function Invoke-Compose {
    param([string[]]$Arguments)
    & docker compose @compose @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Docker Compose failed: $($Arguments -join ' ')" }
}
$cronConfigured = $false
try {
    Invoke-Compose -Arguments @('exec', '-T', 'postgres-app', 'pg_isready')
    Invoke-DatabaseSql '01-graph.sql'
    Invoke-DatabaseSql '02-search.sql'
    Invoke-DatabaseSql '03-queue-start.sql'
    Start-Sleep -Seconds 3
    Invoke-DatabaseSql '04-queue-retry.sql'
    Invoke-DatabaseSql '05-persistence-setup.sql'
    Invoke-DatabaseSql '07-cron-setup.sql' 'maintenance'
    $cronConfigured = $true
    $cronCompleted = $false
    for ($attempt=0; $attempt -lt 15; $attempt++) {
        Start-Sleep -Seconds 2
        $check = 'SELECT count(*) FROM public.infra_acceptance_cron_events;'
        $count = $check | & docker compose @compose exec -T postgres-app sh -c 'psql -X -A -t -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres'
        if ($LASTEXITCODE -ne 0) { throw 'Unable to poll pg_cron acceptance fixture.' }
        if ([int](($count | Out-String).Trim()) -gt 0) { $cronCompleted = $true; break }
    }
    if (-not $cronCompleted) { throw 'pg_cron did not execute within 30 seconds.' }
    Invoke-DatabaseSql '08-cron-verify.sql' 'maintenance'
    if ($SkipRestart) {
        Write-Host 'SKIPPED: persistence restart (SkipRestart supplied); fixture retained.'
    } else {
        # A clean Docker restart does NOT test UNLOGGED crash truncation.
        Invoke-Compose -Arguments @('restart', 'postgres-app')
        Invoke-DatabaseSql '06-persistence-verify.sql'
    }
    Write-Host 'PASS: PostgreSQL extension functional acceptance.'
} finally {
    if ($cronConfigured) {
        try { Invoke-DatabaseSql '09-cron-cleanup.sql' 'maintenance' }
        catch { Write-Warning "Cron fixture cleanup failed: $_" }
    }
}
