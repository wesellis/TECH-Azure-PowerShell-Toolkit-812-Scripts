#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Update Azvm(Systemassignedidentity)

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$VMName = "TrueSky1"
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -IdentityType SystemAssigned
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$VMName = "TrueSky1";
$ResourceGroupName = "CCI_TrueSky1_RG" ;
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -IdentityType SystemAssigned


