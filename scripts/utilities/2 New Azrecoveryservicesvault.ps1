#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    New Azrecoveryservicesvault

.DESCRIPTION
    New Azrecoveryservicesvault operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Note: Vault name cannot contain underscore _ or other special characters
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerName = 'CanPrintEquip',

    [Parameter(Mandatory = $true)]
    [string]$VMName = 'Outlook1',

    [Parameter(Mandatory = $true)]
    [string]$LocationName = 'CanadaCentral',

    [Parameter()]
    [hashtable]$Tags
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$ResourceGroupName = -join ("$CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join ("$VMName" , "ARSV1" )

$newAzRecoveryServicesVaultSplat = @{
    Name = $Vaultname
    ResourceGroupName = $ResourceGroupName
    Location = $LocationName
}

if ($Tags) {
    $newAzRecoveryServicesVaultSplat['Tag'] = $Tags
}

New-AzRecoveryServicesVault -ErrorAction Stop @newAzRecoveryServicesVaultSplat