<#
.SYNOPSIS
    16 Get Azrecoveryservicesbackuprecoverypoint

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
    We Enhanced 16 Get Azrecoveryservicesbackuprecoverypoint

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
.NOTES
    General notes

    RecoveryPointId    RecoveryPointType  RecoveryPointTime      ContainerName                        ContainerType  
---------------    -----------------  -----------------      -------------                        -------------
630969556710589... CrashConsistent    2020-12-12 11:18:41 PM iaasvmcontainerv2;canprintequip_o... AzureVM


$startDate = (Get-Date).AddDays(-7)
$endDate = Get-Date; 
$getAzRecoveryServicesBackupRecoveryPointSplat = @{
    Item = $backupitem
    StartDate = $startdate.ToUniversalTime()
    EndDate = $enddate.ToUniversalTime()
    VaultId = $targetVault.ID
}
; 
$rp = Get-AzRecoveryServicesBackupRecoveryPoint @getAzRecoveryServicesBackupRecoveryPointSplat

$rp

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================