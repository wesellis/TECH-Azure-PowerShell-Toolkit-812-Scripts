#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Get VM extensions

.DESCRIPTION
    List available VM extensions for a location
    Author: Wes Ellis (wes@wesellis.com)
.PARAMETER Location
    Azure location
.EXAMPLE
    Get-AzVmImagePublisher -Location "CanadaCentral" | Get-AzVMExtensionImageType | Get-AzVMExtensionImage
#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$Location = "CanadaCentral"
)

$ErrorActionPreference = "Stop"

# Get all VM extensions for the location
Get-AzVmImagePublisher -Location $Location |
    Get-AzVMExtensionImageType |
    Get-AzVMExtensionImage |
    Select-Object PublisherName, Type, Version

