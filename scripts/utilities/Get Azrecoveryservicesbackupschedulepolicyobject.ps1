#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Get Azure Recovery Services backup schedule policy object

.DESCRIPTION
    Get Azure Recovery Services backup schedule policy object operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('AzureVM', 'WindowsServer', 'AzureFiles', 'MSSQL')]
    [string]$WorkloadType = 'AzureVM'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$getAzRecoveryServicesBackupSchedulePolicyObjectSplat = @{
    WorkloadType = $WorkloadType
}

Get-AzRecoveryServicesBackupSchedulePolicyObject @getAzRecoveryServicesBackupSchedulePolicyObjectSplat -ErrorAction Stop