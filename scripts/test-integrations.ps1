$ErrorActionPreference = 'Stop'
& node (Join-Path $PSScriptRoot '../tests/integrations/acceptance.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Integration fixture failed.' }
