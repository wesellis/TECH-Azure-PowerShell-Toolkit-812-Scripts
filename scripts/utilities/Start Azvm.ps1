#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Start Azvm

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Start-AzVM -ResourceGroupName "CCI_PS_AUTOMATION_RG" -Name "PSAutomation1"
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
Start-AzVM -ResourceGroupName "CCI_PS_AUTOMATION_RG" -Name "PSAutomation1" ;
$pip = Get-AzPublicIpAddress -ResourceGroupName "CCI_PS_AUTOMATION_RG" -Name "PSAutomation1-ip"
Write-Output $pip.IpAddress
mstsc.exe



