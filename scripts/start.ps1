[CmdletBinding()]
param([switch]$Temporal)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) {
    throw 'Missing .env. Copy .env.example to .env and review the development credentials.'
}
if ($Temporal) {
    # Refuse to attach an old PG16 cluster to the new PostgreSQL 18 service.
    # This probe mounts the volume read-only; no data is modified or deleted.
    $volumeName = 'nuxt-layers-infrastructure_temporal_pgdata'
    & docker volume inspect $volumeName *> $null
    if ($LASTEXITCODE -eq 0) {
        & docker run --rm --volume "${volumeName}:/volume:ro" --entrypoint sh postgres:18 -c 'if [ -f /volume/PG_VERSION ]; then echo "Existing pre-PG18 Temporal data directory detected; perform an explicit major upgrade or restore."; exit 42; fi; if [ -e /volume/18/docker/PG_VERSION ] && [ "$(cat /volume/18/docker/PG_VERSION)" != 18 ]; then exit 43; fi'
        if ($LASTEXITCODE -ne 0) {
            throw 'Temporal data volume is incompatible with PostgreSQL 18 or could not be verified. Existing data was not changed.'
        }
    }
}
$compose = @('--env-file', (Join-Path $root '.env'), '-f', (Join-Path $root 'compose/compose.yaml'), '-f', (Join-Path $root 'compose/compose.dev.yaml'))
if ($Temporal) { $compose += @('--profile', 'temporal') }
& docker compose @compose up -d --wait
if ($LASTEXITCODE -ne 0) { throw "Docker Compose failed with code $LASTEXITCODE" }
