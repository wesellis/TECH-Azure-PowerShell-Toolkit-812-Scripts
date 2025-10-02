#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Get recoveryservicesbackupjobdetails

.DESCRIPTION
    Get recoveryservicesbackupjobdetails operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerName,

    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter()]
    [string]$JobId,

    [Parameter()]
    [int]$DaysBack = 30,

    [Parameter()]
    [ValidateSet('InProgress', 'Completed', 'Failed', 'CompletedWithWarnings', 'Cancelled')]
    [string]$Status = 'Completed'
)

$ErrorActionPreference = 'Stop'

$ResourceGroupName = -join ("$CustomerName" , "_$VMName" , "_RG" )
$Vaultname = -join ("$VMName" , "ARSV1" )

$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Vaultname
}
$targetVault = Get-AzRecoveryServicesVault @getAzRecoveryServicesVaultSplat

$getAzRecoveryServicesBackupJobSplat = @{
    VaultId = $targetVault.ID
    Status = $Status
    From = (Get-Date).AddDays(-$DaysBack).ToUniversalTime()
}
$jobs = Get-AzRecoveryServicesBackupJob -ErrorAction Stop @getAzRecoveryServicesBackupJobSplat

if ($JobId) {
    $restorejob = $jobs | Where-Object {$_.JobId -eq $JobId}
} else {
    $restorejob = $jobs | Select-Object -First 1
}

if ($null -eq $restorejob) {
    Write-Error "No jobs found matching the criteria"
    return
}

$getAzRecoveryServicesBackupJobDetailsSplat = @{
    Job = $restorejob
    VaultId = $targetVault.ID
}
$details = Get-AzRecoveryServicesBackupJobDetail -ErrorAction Stop @getAzRecoveryServicesBackupJobDetailsSplat
$details | Format-List