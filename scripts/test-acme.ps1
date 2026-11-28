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
    Write-Host 'PASS: initial ACME issuance and trusted HTTPS for both sites.'
    # Traefik writes ACME state asynchronously; wait for both certificate entries
    # without exposing account keys or certificate private keys in console output.
    $persisted = $false
    for ($i=0; $i -lt 30; $i++) {
        $state = & docker compose @compose exec -T proxy sh -ec 'test -s /state/acme.json && cat /state/acme.json' 2>$null
        if ($LASTEXITCODE -eq 0) {
            try {
                $saved = ($state | Out-String | ConvertFrom-Json).local.Certificates
                $domains = @($saved | ForEach-Object { $_.domain.main })
                if ($domains -contains 'site-a.fixture.test' -and $domains -contains 'site-b.fixture.test') { $persisted = $true; break }
            } catch { }
        }
        Start-Sleep -Seconds 1
    }
    Remove-Variable state,saved -ErrorAction SilentlyContinue
    if (-not $persisted) { throw 'ACME state did not persist both issued certificates before restart.' }
    # Recreate instead of restarting, ensuring the named volume is the durable source.
    Dc up -d --no-deps --force-recreate proxy
    # Docker can assign a new ephemeral host port on restart/recreation.
    $endpoint = (Dc port proxy 8443 | Out-String).Trim()
    if ($endpoint -notmatch '^127\.0\.0\.1:\d+$') { throw 'Recreated proxy must publish a loopback endpoint.' }
    Write-Host "Recreated proxy endpoint: $endpoint"
    & node (Join-Path $PSScriptRoot '../tests/site-hosting/acme-acceptance.mjs') $endpoint $rootCa @serials
    if ($LASTEXITCODE -ne 0) { throw 'ACME certificate persistence failed.' }
    Write-Host 'PASS: local ACME HTTP-01 issuance, trusted multi-site TLS, unknown SNI denial and persisted certificates across restart.'
} catch {
    if (Test-Path $envFile) { & docker compose @compose logs --tail 100 proxy pebble }
    throw
} finally {
    if (Test-Path $envFile) { & docker compose @compose down --volumes --remove-orphans; if ($LASTEXITCODE -ne 0) { throw 'ACME fixture cleanup failed.' } }
    if (Test-Path $folder) { Remove-Item -LiteralPath $folder -Recurse -Force }
}
