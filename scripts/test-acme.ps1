[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$')][string]$PebbleImage,
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$')][string]$TraefikImage
)
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
foreach ($name in @('PEBBLE_IMAGE','TRAEFIK_IMAGE','ACME_FIXTURE_DIR','COMPOSE_FILE','COMPOSE_PROFILES')) {
    if (Test-Path "Env:$name") { throw "Unset $name before acceptance." }
}
$project='nl-acme-'+[guid]::NewGuid().ToString('N').Substring(0,12)
$folder=Join-Path ([IO.Path]::GetTempPath()) $project
$envFile=Join-Path $folder 'fixture.env'
$compose=@('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $PSScriptRoot '../compose/compose.acme.yaml'))
function Dc {
    & docker compose @compose @args
    if ($LASTEXITCODE -ne 0) { throw "ACME compose command failed: $($args[0])" }
}
try {
    New-Item -ItemType Directory $folder | Out-Null
    Copy-Item (Join-Path $PSScriptRoot '../tests/site-hosting/acme-routes.yaml') (Join-Path $folder 'routes.yaml')
    @("PEBBLE_IMAGE=$PebbleImage","TRAEFIK_IMAGE=$TraefikImage","ACME_FIXTURE_DIR=$($folder.Replace('\','/'))") | Set-Content -Encoding utf8 $envFile
    Dc up -d pebble
    $id=(Dc ps -q pebble | Out-String).Trim()
    & docker cp "${id}:/test/certs/pebble.minica.pem" (Join-Path $folder 'pebble.minica.pem')
    if ($LASTEXITCODE -ne 0) { throw 'Unable to extract fixture CA from reviewed Pebble image.' }
    $management=(Dc port pebble 15000 | Out-String).Trim()
    if ($management -notmatch '^127\.0\.0\.1:\d+$') { throw 'Management endpoint must be loopback.' }
    $rootCa=Join-Path $folder 'issued-root.pem'
    for($i=0;$i -lt 30;$i++){
        try { Invoke-WebRequest "https://$management/roots/0" -SkipCertificateCheck -TimeoutSec 3 -OutFile $rootCa; break } catch { Start-Sleep -Seconds 1 }
    }
    if (!(Test-Path $rootCa)) { throw 'Local Pebble management root unavailable.' }
    # The management bootstrap uses an isolated loopback fixture only; ACME client and issued TLS are verified.
    Dc up -d proxy site
    $endpoint=(Dc port proxy 8443 | Out-String).Trim()
    $serials=@(& node (Join-Path $PSScriptRoot '../tests/site-hosting/acme-acceptance.mjs') $endpoint $rootCa)
    if ($LASTEXITCODE -ne 0 -or $serials.Count -ne 2) { throw 'ACME issuance failed.' }
    Dc restart proxy
    & node (Join-Path $PSScriptRoot '../tests/site-hosting/acme-acceptance.mjs') $endpoint $rootCa @serials
    if ($LASTEXITCODE -ne 0) { throw 'ACME certificate persistence failed.' }
    Write-Host 'PASS: local ACME HTTP-01 issuance, trusted multi-site TLS, unknown SNI denial and persisted certificates across restart.'
} catch {
    if (Test-Path $envFile) { & docker compose @compose logs --tail 40 }
    throw
} finally {
    if (Test-Path $envFile) { & docker compose @compose down --volumes --remove-orphans }
    if (Test-Path $folder) { Remove-Item -LiteralPath $folder -Recurse -Force }
}
