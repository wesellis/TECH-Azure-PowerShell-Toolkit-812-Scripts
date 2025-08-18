<#
.SYNOPSIS
    We Enhanced Update Azvm(Systemassignedidentity)

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

$WEVMName = "TrueSky1"
Update-AzVM -ResourceGroupName $WEResourceGroupName -VM $vm -IdentityType SystemAssigned


$WEErrorActionPreference = " Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$WEVMName = " TrueSky1"
$WEResourceGroupName = " CCI_TrueSky1_RG"; 
$vm = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVMName
Update-AzVM -ResourceGroupName $WEResourceGroupName -VM $vm -IdentityType SystemAssigned


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================