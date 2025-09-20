#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Get recoveryservicesbackupitem

.DESCRIPTION
    Get recoveryservicesbackupitem operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    Name                                     ContainerType        ContainerUniqueName                      WorkloadType         ProtectionStatus
----                                     -------------        -------------------                      ------------         ----------------
VM;iaasvmcontainerv2;canprintequip_ou... AzureVM              iaasvmcontainerv2;canprintequip_outlo... AzureVM              Healthy
    General notes
$CustomerName = 'CanPrintEquip'
$VMName = 'Outlook1'
$ResourceGroupName = -join ("$CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join (" $VMName" , "ARSV1" )
$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Vaultname
}
$targetVault = Get-AzRecoveryServicesVault -ErrorAction Stop @getAzRecoveryServicesVaultSplat
$getAzRecoveryServicesBackupItemSplat = @{
    Container = $namedContainer
    WorkloadType = "AzureVM"
    VaultId = $targetVault.ID
}
$backupitem = Get-AzRecoveryServicesBackupItem -ErrorAction Stop @getAzRecoveryServicesBackupItemSplat
$backupitem

