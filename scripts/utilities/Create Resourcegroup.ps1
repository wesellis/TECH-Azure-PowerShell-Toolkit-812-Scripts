#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create Resourcegroup

.DESCRIPTION
    Create Resourcegroup operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter()]
    [hashtable]$Tags
)

$ErrorActionPreference = 'Stop'

$params = @{
    Name = $Name
    Location = $Location
}

if ($Tags) {
    $params['Tag'] = $Tags
}

New-AzResourceGroup @params