<#
.SYNOPSIS
    We Enhanced 4 Set Azrecoveryservicesbackupproperty

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
.NOTES
    General notes


    

Storage Redundancy can be modified only if there are no backup items protected to the vault.

Default value when you create a new RSV

Recovery Services Vault --> Properties --> Storage Replication Type = Geo-Redundant




$WEVMName = 'Outlook1'

$WEVaultname = -join ("$WEVMName" , "ARSV1" )


; 
$setAzRecoveryServicesBackupPropertySplat = @{
    Vault = $WEVaultname
    BackupStorageRedundancy = 'GeoRedundant/LocallyRedundant'
}

Set-AzRecoveryServicesBackupProperty @setAzRecoveryServicesBackupPropertySplat



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================