[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$')][string]$TraefikImage,
    [Parameter(Mandatory)][string]$CertificateFolder
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
foreach ($name in @('TRAEFIK_FIXTURE_IMAGE','PROXY_FIXTURE_DIR','COMPOSE_FILE','COMPOSE_PROFILES')) {
    if (Test-Path "Env:$name") { throw "Unset $name before acceptance." }
}
$project = 'nl-proxy-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$root = Join-Path ([IO.Path]::GetTempPath()) $project
$envFile = Join-Path $root 'fixture.env'
$dynamic = Join-Path $root 'dynamic'
$certs = Join-Path $root 'certificates'
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $PSScriptRoot '../compose/compose.proxy-acceptance.yaml'))
function Invoke-Compose {
    & docker compose @compose @args
    if ($LASTEXITCODE -ne 0) { throw 'Proxy fixture command failed.' }
}
function Write-Routes([bool]$IncludeA, [switch]$Live) {
    $routers = @{}
    $services = @{}
    $certificates = @()
    foreach ($site in @('site-a','site-b')) {
        $fqdn = "$site.fixture.test"
        $certificates += @{certFile="/certificates/$fqdn.crt";keyFile="/certificates/$fqdn.key"}
        if ($site -eq 'site-a' -and -not $IncludeA) { continue }
        $routers[$site] = @{rule=('Host(`'+$fqdn+'`)');entryPoints=@('websecure');service=$site;tls=@{}}
        $services[$site] = @{loadBalancer=@{servers=@(@{url="http://$site"+':80'})}}
    }
    $config = @{http=@{routers=$routers;services=$services};tls=@{certificates=$certificates;options=@{default=@{sniStrict=$true;minVersion='VersionTLS12'}}}}
    $temp = Join-Path $dynamic 'routes.tmp'
    $json = $config | ConvertTo-Json -Depth 15 -Compress
    if ($Live) {
        # Publish within Linux tmpfs so the file watcher receives native rename events.
        $json | & docker compose @compose exec -T proxy sh -ec 'cat > /dynamic/routes.tmp; mv /dynamic/routes.tmp /dynamic/routes.yaml'
        if ($LASTEXITCODE -ne 0) { throw 'Live route publication failed.' }
    } else {
        $json | Set-Content -Encoding utf8 $temp
        Move-Item -LiteralPath $temp -Destination (Join-Path $dynamic 'routes.yaml') -Force
    }
}
try {
    New-Item -ItemType Directory -Path $dynamic,$certs | Out-Null
    foreach ($site in @('site-a','site-b')) {
        foreach ($extension in @('crt','key')) {
            Copy-Item -LiteralPath (Join-Path $CertificateFolder "$site.fixture.test.$extension") -Destination $certs
        }
        $conf = 'server { listen 80; location / { default_type text/plain; return 200 "SITE|$http_x_forwarded_host|$http_x_forwarded_proto|$http_x_forwarded_for"; } }'
        $conf.Replace('SITE',$site) | Set-Content -Encoding utf8 (Join-Path $root "$site.conf")
    }
    @("TRAEFIK_FIXTURE_IMAGE=$TraefikImage","PROXY_FIXTURE_DIR=$($root.Replace('\','/'))") | Set-Content -Encoding utf8 $envFile
    Write-Routes $true
    Invoke-Compose up -d
    $endpoint = (Invoke-Compose port proxy 8443 | Out-String).Trim()
    if ($endpoint -notmatch '^127\.0\.0\.1:\d+$') { throw 'Proxy must be loopback only.' }
    foreach ($phase in @('apply','withdraw','reapply')) {
        if ($phase -eq 'withdraw') { Write-Routes $false -Live }
        if ($phase -eq 'reapply') { Write-Routes $true -Live }
        & node (Join-Path $PSScriptRoot '../tests/site-hosting/proxy-acceptance.mjs') $endpoint $CertificateFolder $phase
        if ($LASTEXITCODE -ne 0) { throw "Proxy acceptance failed: $phase" }
    }
} catch {
    if (Test-Path $envFile) { & docker compose @compose logs --no-color --tail 50 | Out-Host }
    throw
} finally {
    if (Test-Path $envFile) {
        & docker compose @compose down --volumes --remove-orphans
        if ($LASTEXITCODE -ne 0) { Write-Warning "Cleanup failed for $project" }
    }
    if (Test-Path $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
