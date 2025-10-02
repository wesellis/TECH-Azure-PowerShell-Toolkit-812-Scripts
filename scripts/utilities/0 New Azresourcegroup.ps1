#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Creates a new Azure Resource Group

.DESCRIPTION
    This script creates a new Azure Resource Group in the specified location.
    Requires appropriate Azure permissions and the Az.Resources module.

.PARAMETER Name
    The name of the resource group to create

.PARAMETER Location
    The Azure region where the resource group will be created

.EXAMPLE
    PS C:\> New-AzResourceGroup -Name 'FGC_Prod_FileStorage_RG' -Location "CanadaCentral"
    Creates a new resource group named 'FGC_Prod_FileStorage_RG' in Canada Central

.AUTHOR
    Wes Ellis (wes@wesellis.com)
#>

param(
    [Parameter(Mandatory = $true)]
    $Name,

    [Parameter(Mandatory = $true)]
    $Location
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Create the Azure Resource Group
New-AzResourceGroup -Name $Name -Location $Location