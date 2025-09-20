#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Update Azvm(Systemassignedidentity)

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $vm -IdentityType SystemAssigned\n

