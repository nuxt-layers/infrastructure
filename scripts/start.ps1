[CmdletBinding()]
param([switch]$Temporal)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) {
    throw 'Missing .env. Copy .env.example to .env and review the development credentials.'
}
$compose = @('--env-file', (Join-Path $root '.env'), '-f', (Join-Path $root 'compose/compose.yaml'), '-f', (Join-Path $root 'compose/compose.dev.yaml'))
if ($Temporal) { $compose += @('--profile', 'temporal') }
& docker compose @compose up -d --wait
if ($LASTEXITCODE -ne 0) { throw "Docker Compose failed with code $LASTEXITCODE" }
