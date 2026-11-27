[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$compose = @('--env-file',(Join-Path $root '.env'),'-f',(Join-Path $root 'compose/compose.yaml'),'-f',(Join-Path $root 'compose/compose.dev.yaml'))
function Invoke-DockerText {
    param([string[]]$Arguments)
    $result = & docker @Arguments
    if ($LASTEXITCODE -ne 0) { throw 'Docker evidence command failed.' }
    return ($result | Out-String).Trim()
}
$container = Invoke-DockerText -Arguments (@('compose') + $compose + @('ps','-q','postgres-app'))
if (-not $container) { throw 'Start PostgreSQL before collecting evidence.' }
$image = Invoke-DockerText -Arguments @('inspect','--format','{{.Image}}',$container)
$base = Invoke-DockerText -Arguments @('image','inspect','--format','{{json .RepoDigests}}','postgres:18-bookworm')
$packages = Invoke-DockerText -Arguments (@('compose') + $compose + @('exec','-T','postgres-app','dpkg-query','-W','postgresql-18','postgresql-18-cron'))
$extensions = Invoke-DockerText -Arguments (@('compose') + $compose + @('exec','-T','postgres-app','sh','-c','psql -X -At -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT extname,extversion FROM pg_extension ORDER BY extname"'))
[pscustomobject]@{
    collectedAt = [DateTimeOffset]::UtcNow.ToString('o')
    runningImageId = $image
    localBaseTagDigests = $base | ConvertFrom-Json
    runtimePackages = $packages
    applicationExtensions = $extensions
    qualification = 'Observed runtime and current local tag; not proof of builder provenance or immutable rebuild.'
} | ConvertTo-Json -Depth 4
