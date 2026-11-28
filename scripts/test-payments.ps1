[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
& node (Join-Path $PSScriptRoot '../tests/payments/acceptance.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Offline payment acceptance failed.' }
