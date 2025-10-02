#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Monitor Azure backup jobs

.DESCRIPTION
    Monitor backup job status for Azure Recovery Services vault
.EXAMPLE
    PS C:\> .\"12 Monitor Backupjob.ps1"
    Gets the status of backup jobs for the configured vault
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
$getAzRecoveryservicesBackupJobSplat = @{
    VaultId = $targetVault.ID
}
$joblist = Get-AzRecoveryservicesBackupJob @getAzRecoveryservicesBackupJobSplat
$joblist[0]