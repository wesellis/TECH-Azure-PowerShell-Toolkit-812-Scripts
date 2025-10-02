#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Get VM extensions

.DESCRIPTION
    List available VM extensions for a location
    Author: Wes Ellis (wes@wesellis.com)
.PARAMETER Location
    Azure location
.EXAMPLE
    Get-AzVmImagePublisher -Location "CanadaCentral" | Get-AzVMExtensionImageType | Get-AzVMExtensionImage
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$Location = "CanadaCentral"
)

$ErrorActionPreference = "Stop"

Get-AzVmImagePublisher -Location $Location |
    Get-AzVMExtensionImageType |
    Get-AzVMExtensionImage |
    Select-Object PublisherName, Type, Version


