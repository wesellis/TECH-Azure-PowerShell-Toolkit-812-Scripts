#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
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

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerName = 'CanPrintEquip',

    [Parameter(Mandatory = $true)]
    [string]$VMName = 'Outlook1'
)

$ErrorActionPreference = 'Stop'

$ResourceGroupName = -join ("$CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join ("$VMName" , "ARSV1" )
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