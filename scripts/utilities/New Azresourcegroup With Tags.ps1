#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    New Azresourcegroup

.DESCRIPTION
    New Azresourcegroup operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name = 'FGCHealth_Prod-PAS1_RG',

    [Parameter(Mandatory = $true)]
    [string]$Location = "CanadaCentral",

    [Parameter()]
    [hashtable]$Tags
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$params = @{
    Name = $Name
    Location = $Location
}

if ($Tags) {
    $params['Tag'] = $Tags
}

New-AzResourceGroup @params