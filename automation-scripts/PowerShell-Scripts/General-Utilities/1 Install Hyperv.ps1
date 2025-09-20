<#
.SYNOPSIS
    Install Hyperv

.DESCRIPTION
    Install Hyperv operation
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V
Get-WindowsOptionalFeature -Online -FeatureName *hyper-v* | Select-Object DisplayName, FeatureName
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

