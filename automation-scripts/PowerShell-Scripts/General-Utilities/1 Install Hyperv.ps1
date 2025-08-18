<#
.SYNOPSIS
    We Enhanced 1 Install Hyperv

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V







Get-WindowsOptionalFeature -Online -FeatureName *hyper-v* | Select-Object DisplayName, FeatureName


Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Management-PowerShell


Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-Tools-All


Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================