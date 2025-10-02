#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Invoke Azure Resource Group creation

.DESCRIPTION
    Creates a new Azure Resource Group with specified configuration

.PARAMETER ResourceGroupName
    Name of the resource group

.PARAMETER LocationName
    Azure location name

.PARAMETER Tags
    Hash table of tags to apply

.EXAMPLE
    Invoke-AzResourceGroup -ResourceGroupName "MyRG" -LocationName "East US" -Tags @{Environment="Dev"}

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$LocationName,

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{}
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Invoke-AzResourceGroup {
    $NewAzResourceGroupSplat = @{
        Name     = $ResourceGroupName
        Location = $LocationName
        Tag      = $Tags
    }
    $RG = New-AzResourceGroup -ErrorAction Stop @NewAzResourceGroupSplat
    return $RG
}

# Execute the function
Invoke-AzResourceGroup
