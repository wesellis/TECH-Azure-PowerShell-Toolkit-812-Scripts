#Requires -Version 7.4
#Requires -Modules Az.RecoveryServices

<#
.SYNOPSIS
    Gets Azure Recovery Services vaults

.DESCRIPTION
    This script retrieves information about Azure Recovery Services vaults in the current
    subscription or a specific resource group.

.PARAMETER ResourceGroupName
    Optional. The name of the resource group to filter vaults

.PARAMETER VaultName
    Optional. The name of a specific vault to retrieve

.EXAMPLE
    PS C:\> Get-AzRecoveryServicesVault
    Gets all Recovery Services vaults in the current subscription

.EXAMPLE
    PS C:\> Get-AzRecoveryServicesVault -ResourceGroupName "CanPrintEquip_Outlook_RG"
    Gets all Recovery Services vaults in the specified resource group

.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>

param(
    [Parameter(Mandatory = $false)]
    $ResourceGroupName,

    [Parameter(Mandatory = $false)]
    $VaultName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Get Recovery Services vaults based on parameters
if ($VaultName -and $ResourceGroupName) {
    Write-Host "Getting Recovery Services vault '$VaultName' in resource group '$ResourceGroupName'..." -ForegroundColor Green
    Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
} elseif ($ResourceGroupName) {
    Write-Host "Getting Recovery Services vaults in resource group '$ResourceGroupName'..." -ForegroundColor Green
    Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -ErrorAction Stop
} else {
    Write-Host "Getting all Recovery Services vaults in subscription..." -ForegroundColor Green
    Get-AzRecoveryServicesVault -ErrorAction Stop
}