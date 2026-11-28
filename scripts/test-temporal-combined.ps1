[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
foreach ($script in @('test-temporal-h1.ps1','test-temporal-h2.ps1','test-temporal-phase3.ps1')) {
    $path = Join-Path $PSScriptRoot $script
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing acceptance script: $script" }
    Write-Host "Running $script"
    if ($script -eq 'test-temporal-phase3.ps1') { & $path -Stage All } else { & $path }
}
Write-Host 'PASS: combined local H1, H2 and Phase 3 functional/recovery/worker-crash fixtures; integration and upgrade gates remain separate.'
