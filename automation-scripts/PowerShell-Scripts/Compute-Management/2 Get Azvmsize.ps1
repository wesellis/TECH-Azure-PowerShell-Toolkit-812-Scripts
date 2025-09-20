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
param(
    [Parameter(Mandatory)]
    [string]$Location
)

$ErrorActionPreference = "Stop"

# Get and display available VM sizes
Get-AzVmSize -Location $Location | Format-Table -AutoSize

