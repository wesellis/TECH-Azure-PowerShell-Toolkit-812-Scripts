<#
.SYNOPSIS
    Start Azvm

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

<#
.SYNOPSIS
    We Enhanced Start Azvm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Start-AzVM -ResourceGroupName "CCI_PS_AUTOMATION_RG" -Name " PSAutomation1"



$WEErrorActionPreference = " Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

Start-AzVM -ResourceGroupName " CCI_PS_AUTOMATION_RG" -Name " PSAutomation1" ; 
$pip = Get-AzPublicIpAddress -ResourceGroupName " CCI_PS_AUTOMATION_RG" -Name " PSAutomation1-ip"
Write-Output $pip.IpAddress
mstsc.exe





















# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================