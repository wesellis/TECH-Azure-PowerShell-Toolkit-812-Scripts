#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Module Az.Resources
<#`n.SYNOPSIS
    Get Azure Recovery Services backup container

.DESCRIPTION
    Retrieve backup container information from Azure Recovery Services vault
.EXAMPLE
    PS C:\> .\"13 Get Azrecoveryservicesbackupcontainer.ps1"
    Gets backup container details for the configured VM
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    LastModified: 2025-09-19
    Requires appropriate permissions and modules
#>
$CustomerName = 'CanPrintEquip'
$VMName = 'Outlook1'
$ResourceGroupName = -join ("$CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join (" $VMName" , "ARSV1" )
$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Vaultname
}
$targetVault = Get-AzRecoveryServicesVault @getAzRecoveryServicesVaultSplat
$getAzRecoveryServicesBackupContainerSplat = @{
    ContainerType = "AzureVM"
    Status = "Registered"
    FriendlyName = $VMName
    VaultId = $targetVault.ID
}
$namedContainer = Get-AzRecoveryServicesBackupContainer @getAzRecoveryServicesBackupContainerSplat
$namedContainer

