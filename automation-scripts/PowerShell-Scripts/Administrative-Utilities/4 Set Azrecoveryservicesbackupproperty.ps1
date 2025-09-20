#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Set Azrecoveryservicesbackupproperty

.DESCRIPTION
    Set Azrecoveryservicesbackupproperty operation
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
    General notes
Storage Redundancy can be modified only if there are no backup items protected to the vault.
Default value when you create a new RSV
Recovery Services Vault --> Properties --> Storage Replication Type = Geo-Redundant
$VMName = 'Outlook1'
$Vaultname = -join ("$VMName" , "ARSV1" )
$setAzRecoveryServicesBackupPropertySplat = @{
    Vault = $Vaultname
    BackupStorageRedundancy = 'GeoRedundant/LocallyRedundant'
}
Set-AzRecoveryServicesBackupProperty -ErrorAction Stop @setAzRecoveryServicesBackupPropertySplat

