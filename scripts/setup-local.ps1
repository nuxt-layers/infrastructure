#Requires -RunAsAdministrator
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'setup-local-windows.ps1')
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Windows preflight failed.' }
Write-Host 'PASS: Windows provisioning preflight.'
Write-Host 'BLOCKED: Debian activation requires router verification and controlled offline first boot; no WSL command executed.'
