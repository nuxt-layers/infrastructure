[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) { throw 'Missing local .env file.' }
$compose = @('--env-file', (Join-Path $root '.env'), '-f', (Join-Path $root 'compose/compose.yaml'), '-f', (Join-Path $root 'compose/compose.dev.yaml'), '--profile', 'temporal')
function Assert-DockerExit {
    if ($LASTEXITCODE -ne 0) { throw "Command failed (exit $LASTEXITCODE)." }
}
& docker compose @compose up -d --wait
Assert-DockerExit
# A separate PostgreSQL container must be v18. Read-only SQL version probe.
$version = & docker compose @compose exec -T postgres-temporal sh -c 'psql -X -A -t -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c "SHOW server_version_num"'
Assert-DockerExit
if (-not (($version | Out-String).Trim() -match '^18\d{4}$')) {
    throw "Temporal PostgreSQL is not version 18: $version"
}
# The first start may initialise the Temporal schema, so wait for the frontend.
$ready = $false
for ($attempt = 0; $attempt -lt 60; $attempt++) {
    & docker compose @compose exec -T temporal sh -c 'tctl --address temporal:7233 namespace describe default' *> $null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $ready) { throw 'Temporal default namespace did not become ready.' }
$workflowId = 'infra-acceptance-' + [guid]::NewGuid().ToString('N')
$harness = Join-Path $root 'tests/temporal'
Push-Location $harness
try {
    & corepack pnpm install --frozen-lockfile
    Assert-DockerExit
    & corepack pnpm exec tsx src/acceptance.ts execute $workflowId
    Assert-DockerExit
} finally { Pop-Location }
& docker compose @compose restart temporal
Assert-DockerExit
# Restart does not recreate the persistence database or discard volumes.
$ok = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    Start-Sleep -Seconds 2
    & docker compose @compose exec -T temporal sh -c 'tctl --address temporal:7233 namespace describe default' *> $null
    if ($LASTEXITCODE -eq 0) { $ok = $true; break }
}
if (-not $ok) { throw 'Temporal frontend did not become ready after restart.' }
Push-Location $harness
try {
    & corepack pnpm exec tsx src/acceptance.ts verify $workflowId
    Assert-DockerExit
} finally { Pop-Location }
Write-Host 'PASS: Temporal PostgreSQL 18 local workflow and persistence acceptance.'
