#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Start Azvm

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Start-AzVM -ResourceGroupName "CCI_PS_AUTOMATION_RG" -Name "PSAutomation1"
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
Start-AzVM -ResourceGroupName "CCI_PS_AUTOMATION_RG" -Name "PSAutomation1" ;
$pip = Get-AzPublicIpAddress -ResourceGroupName "CCI_PS_AUTOMATION_RG" -Name "PSAutomation1-ip"
Write-Output $pip.IpAddress
mstsc.exe\n

