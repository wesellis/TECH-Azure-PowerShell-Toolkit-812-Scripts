#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    14 Get Azrecoveryservicesbackupitem

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 14 Get Azrecoveryservicesbackupitem

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)

    Name                                     ContainerType        ContainerUniqueName                      WorkloadType         ProtectionStatus    
----                                     -------------        -------------------                      ------------         ----------------    
VM;iaasvmcontainerv2;canprintequip_ou... AzureVM              iaasvmcontainerv2;canprintequip_outlo... AzureVM              Healthy
 
.NOTES
    General notes



$WECustomerName = 'CanPrintEquip'
$WEVMName = 'Outlook1'
$WEResourceGroupName = -join ("$WECustomerName" , " _Outlook" , " _RG" )

$WEVaultname = -join (" $WEVMName" , " ARSV1" )

$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Name = $WEVaultname
}

$targetVault = Get-AzRecoveryServicesVault -ErrorAction Stop @getAzRecoveryServicesVaultSplat
; 
$getAzRecoveryServicesBackupItemSplat = @{
    Container = $namedContainer
    WorkloadType = " AzureVM"
    VaultId = $targetVault.ID
}
; 
$backupitem = Get-AzRecoveryServicesBackupItem -ErrorAction Stop @getAzRecoveryServicesBackupItemSplat
$backupitem

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
