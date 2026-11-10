[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) { throw 'Missing .env.' }
& docker compose --env-file (Join-Path $root '.env') -f (Join-Path $root 'compose/compose.yaml') -f (Join-Path $root 'compose/compose.dev.yaml') --profile temporal down
if ($LASTEXITCODE -ne 0) { throw "Docker Compose failed with code $LASTEXITCODE" }
Write-Host 'Containers stopped. Persistent volumes retained.'
