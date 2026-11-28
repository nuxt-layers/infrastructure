[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SeaweedImage,
    [Parameter(Mandatory)][string]$MailpitImage
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
foreach ($image in @($SeaweedImage,$MailpitImage)) {
    if ($image -notmatch '^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$') { throw 'Use reviewed digest-qualified images.' }
}
foreach ($name in @('SEAWEFS_IMAGE','MAILPIT_IMAGE','SUPPORT_FIXTURE_DIR','COMPOSE_FILE','COMPOSE_PROFILES')) {
    if (Test-Path "Env:$name") { throw "Unset $name before acceptance." }
}
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$project = 'nl-support-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$folder = Join-Path ([IO.Path]::GetTempPath()) $project
New-Item -ItemType Directory -Path $folder | Out-Null
$envFile = Join-Path $folder 'fixture.env'
$access = [guid]::NewGuid().ToString('N')
$secret = [guid]::NewGuid().ToString('N')
$tenantAccess = [guid]::NewGuid().ToString('N')
$tenantSecret = [guid]::NewGuid().ToString('N')
$compose = @('--project-name',$project,'--env-file',$envFile,'-f',(Join-Path $root 'compose/compose.supporting.yaml'))
try {
    @{identities=@(@{name='fixture';credentials=@(@{accessKey=$access;secretKey=$secret});actions=@('Admin','Read','Write','List','Tagging')},@{name='restricted';credentials=@(@{accessKey=$tenantAccess;secretKey=$tenantSecret});actions=@('Read:infra-fixture','Write:infra-fixture','List:infra-fixture')})} | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $folder 's3.json')
    @("SEAWEFS_IMAGE=$SeaweedImage","MAILPIT_IMAGE=$MailpitImage","SUPPORT_FIXTURE_DIR=$($folder.Replace('\','/'))") | Set-Content -Encoding utf8 $envFile
    & docker compose @compose up -d
    if ($LASTEXITCODE -ne 0) { throw 'Supporting fixture startup failed.' }
    function Get-Endpoint([string]$service,[int]$port) {
        for ($attempt = 0; $attempt -lt 15; $attempt++) {
            $endpoint = (& docker compose @compose port $service $port | Out-String).Trim()
            if ($LASTEXITCODE -eq 0 -and $endpoint -match '^127\.0\.0\.1:\d+$') { return $endpoint }
            if ($endpoint -and $endpoint -notmatch '^127\.0\.0\.1:\d+$') { throw "Unsafe published endpoint for ${service}:${port}: $endpoint" }
            Start-Sleep -Seconds 1
        }
        & docker compose @compose ps | Out-Host
        throw "No loopback port published for ${service}:${port}."
    }
    $s3 = Get-Endpoint seaweedfs 8333
    $mail = Get-Endpoint mailpit 8025
    $smtp = Get-Endpoint mailpit 1025
    & node (Join-Path $root 'tests/supporting/acceptance.mjs') $s3 $mail $smtp $access $secret $tenantAccess $tenantSecret
    if ($LASTEXITCODE -ne 0) { throw 'Supporting acceptance failed.' }
    & docker compose @compose restart seaweedfs
    if ($LASTEXITCODE -ne 0) { throw 'SeaweedFS restart failed.' }
    $s3 = Get-Endpoint seaweedfs 8333
    & node (Join-Path $root 'tests/supporting/acceptance.mjs') $s3 $mail $smtp $access $secret $tenantAccess $tenantSecret --after-restart
    if ($LASTEXITCODE -ne 0) { throw 'Supporting restart acceptance failed.' }
} catch {
    if (Test-Path $envFile) {
        & docker compose @compose ps | Out-Host
        & docker compose @compose logs --no-color --tail 80 2>&1 | ForEach-Object {
            ([string]$_).Replace($access,'[redacted]').Replace($secret,'[redacted]').Replace($tenantAccess,'[redacted]').Replace($tenantSecret,'[redacted]')
        } | Out-Host
    }
    throw
} finally {
    if (Test-Path $envFile) {
        & docker compose @compose down --volumes --remove-orphans
        if ($LASTEXITCODE -ne 0) { Write-Warning "Cleanup failed for $project" }
    }
    Remove-Item -LiteralPath $folder -Recurse -Force
}
