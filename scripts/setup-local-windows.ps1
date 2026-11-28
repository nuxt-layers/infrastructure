#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$id = '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}'
function Test-Boundary {
    $profiles = @(Get-NetFirewallProfile -PolicyStore ActiveStore)
    if ($profiles.Count -ne 3 -or @($profiles | Where-Object { "$($_.Enabled)" -ne 'True' -or "$($_.DefaultInboundAction)" -ne 'Block' }).Count) {
        throw 'Windows firewall profiles must be enabled with default inbound Block.'
    }
    $mappings = @(Get-NetNatStaticMapping)
    if ($mappings.Count) { throw 'Static NAT mappings exist; review before proceeding.' }
    $proxy = @(netsh interface portproxy show all)
    if ($LASTEXITCODE -ne 0 -or ($proxy -match '^\s*\S+\s+\d+\s+\S+\s+\d+\s*$')) {
        throw 'Port proxy mappings exist or inspection failed.'
    }
    $config = Join-Path $env:USERPROFILE '.wslconfig'
    if (Test-Path $config) {
        $modes = @(Get-Content $config | Where-Object { $_ -match '^\s*networkingMode\s*=' })
        if ($modes.Count -gt 1 -or ($modes.Count -eq 1 -and $modes[0] -notmatch '^\s*networkingMode\s*=\s*nat\s*$')) {
            throw 'WSL must use NAT networking; review .wslconfig manually.'
        }
        if (Get-Content $config | Where-Object { $_ -match '^\s*firewall\s*=\s*false' }) {
            throw 'WSL firewall must not be disabled.'
        }
    }
}
Test-Boundary
if ($Apply -and $PSCmdlet.ShouldProcess('WSL VM creator (all distributions)', 'Apply persistent inbound-block firewall policy')) {
    Set-NetFirewallHyperVVMSetting -Name $id -Enabled True -DefaultInboundAction Block -DefaultOutboundAction Allow -LoopbackEnabled True -AllowHostPolicyMerge False
}
$s = Get-NetFirewallHyperVVMSetting -Name $id -PolicyStore ActiveStore
$s | Format-List
foreach ($pair in @{Enabled='True';DefaultInboundAction='Block';DefaultOutboundAction='Allow';LoopbackEnabled='True';AllowHostPolicyMerge='False'}.GetEnumerator()) {
    if ([string]$s.($pair.Key) -ne $pair.Value) { throw "Effective Hyper-V policy mismatch: $($pair.Key)" }
}
Write-Host 'PASS: Windows baseline settings. Router, effective explicit allow rules, runtime NAT and external probes remain independent gates.'
