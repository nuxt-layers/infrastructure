[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$checker=Join-Path $PSScriptRoot '../hosting/check-production-config.mjs'
function Test-Policy([hashtable]$Config,[bool]$Expected,[string]$Label) {
    $json=$Config | ConvertTo-Json -Depth 20 -Compress
    $result=$json | & node $checker 2>&1
    $ok=$LASTEXITCODE -eq 0
    if ($ok -ne $Expected) { throw "Unexpected policy outcome: $Label" }
    Write-Host "PASS: $Label"
}
function New-Config {
    return @{services=@{db=@{image=('fixture@sha256:' + ('a'*64));mem_limit=1073741824;cpus=1;pids_limit=256;networks=@{private=@{}};logging=@{driver='json-file';options=@{'max-size'='10m';'max-file'='3'}};environment=@{POSTGRES_PASSWORD_FILE='/run/secrets/db'};volumes=@(@{type='volume';source='data';target='/data'})}};networks=@{private=@{internal=$true}}}
}
$c=New-Config; Test-Policy $c $true 'private digest-qualified bounded manifest'
$c=New-Config; $c.services.db.image='fixture:latest'; Test-Policy $c $false 'mutable image denied'
$c=New-Config; $c.services.db.ports=@(@{published=5432;target=5432}); Test-Policy $c $false 'published database port denied'
$c=New-Config; $c.networks.private.internal=$false; Test-Policy $c $false 'public network denied'
$c=New-Config; $c.services.db.environment.POSTGRES_PASSWORD='synthetic'; Test-Policy $c $false 'inline credential denied'
$c=New-Config; $c.services.db.privileged=$true; Test-Policy $c $false 'privileged container denied'
$c=New-Config; $c.services.db.volumes=@(@{type='bind';source='/var/run/docker.sock';target='/var/run/docker.sock'}); Test-Policy $c $false 'host socket mount denied'
$c=New-Config; $c.services.db.Remove('mem_limit'); Test-Policy $c $false 'missing memory budget denied'
$c=New-Config; $c.services.db.Remove('logging'); Test-Policy $c $false 'unbounded logging denied'
