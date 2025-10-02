#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create resource group

.DESCRIPTION
    Create Azure resource group

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name = 'FGC_Prod_Bastion_RG',

    [Parameter(Mandatory = $true)]
    [string]$Location = 'CanadaCentral'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

New-AzResourceGroup -Name $Name -Location $Location