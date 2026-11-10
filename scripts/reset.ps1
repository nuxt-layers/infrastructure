[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not (Test-Path (Join-Path $root '.env'))) { throw 'Missing .env.' }
if ($PSCmdlet.ShouldProcess('ALL local Nuxt Layers infrastructure PostgreSQL volumes', 'Permanently destroy database data')) {
    & docker compose --env-file (Join-Path $root '.env') -f (Join-Path $root 'compose/compose.yaml') -f (Join-Path $root 'compose/compose.dev.yaml') --profile temporal down --volumes --remove-orphans
    if ($LASTEXITCODE -ne 0) { throw "Docker Compose failed with code $LASTEXITCODE" }
    Write-Host 'Local infrastructure containers and volumes removed.'
}
