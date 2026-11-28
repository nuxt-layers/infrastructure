[CmdletBinding()]
param([Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9./:_-]+@sha256:[a-f0-9]{64}$')][string]$ResticImage)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$project = 'nl-restic-' + [guid]::NewGuid().ToString('N').Substring(0,12)
$root = Join-Path ([IO.Path]::GetTempPath()) $project
$source = Join-Path $root 'source'
$repo = Join-Path $root 'repository'
$target = Join-Path $root 'restore'
$previous = [Environment]::GetEnvironmentVariable('RESTIC_PASSWORD','Process')
function Invoke-Restic {
    & docker run --rm --network none --memory 512m --cpus 1 --pids-limit 128 -e RESTIC_PASSWORD -v "${source}:/source:ro" -v "${repo}:/backup" -v "${target}:/restore" $ResticImage -r /backup @args
    if ($LASTEXITCODE -ne 0) { throw 'restic command failed.' }
}
try {
    New-Item -ItemType Directory -Path $source,$repo,$target | Out-Null
    $env:RESTIC_PASSWORD = [guid]::NewGuid().ToString('N')
    $file = Join-Path $source 'fixture.txt'
    'synthetic configuration fixture' | Set-Content -Encoding utf8 $file
    $expected = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
    Invoke-Restic init
    Invoke-Restic backup /source
    Invoke-Restic check --read-data
    Remove-Item -LiteralPath $file -Force
    $correctPassword = $env:RESTIC_PASSWORD
    try {
        $env:RESTIC_PASSWORD = [guid]::NewGuid().ToString('N')
        & docker run --rm --network none --memory 512m --cpus 1 --pids-limit 128 -e RESTIC_PASSWORD -v "${repo}:/backup:ro" $ResticImage -r /backup snapshots
        if ($LASTEXITCODE -eq 0) { throw 'Incorrect backup password was accepted.' }
    } finally { $env:RESTIC_PASSWORD = $correctPassword }
    $timer = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Restic restore latest --target /restore
    $timer.Stop()
    Write-Host "Observed file restore seconds: $($timer.Elapsed.TotalSeconds)"
    $actual = (Get-FileHash -LiteralPath (Join-Path $target 'source/fixture.txt') -Algorithm SHA256).Hash
    if ($actual -ne $expected) { throw 'Restored file hash mismatch.' }
    Write-Host 'PASS: encrypted restic backup, repository integrity, wrong-password denial and lost-file recovery.'
} finally {
    [Environment]::SetEnvironmentVariable('RESTIC_PASSWORD',$previous,'Process')
    if (Test-Path $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
