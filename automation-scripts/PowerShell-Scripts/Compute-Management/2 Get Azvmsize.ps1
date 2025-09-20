#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Get available VM sizes

.DESCRIPTION
    List available VM sizes in a location
    Author: Wes Ellis (wes@wesellis.com)
.PARAMETER Location
    Azure location to query
.EXAMPLE
    Get-AzVmSize -Location 'CanadaCentral'
#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$Location
)

$ErrorActionPreference = "Stop"

# Get and display available VM sizes
Get-AzVmSize -Location $Location | Format-Table -AutoSize

