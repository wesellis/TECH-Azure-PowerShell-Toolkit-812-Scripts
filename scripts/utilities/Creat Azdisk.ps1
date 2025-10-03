#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Create Azure disk

.DESCRIPTION
    Create Azure disk operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Location = 'Canada Central',

    [Parameter(Mandatory = $true)]
    [string]$ImageName = 'FGC_Kroll_Image',

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName = 'FGC_Kroll_Image_RG',

    [Parameter(Mandatory = $true)]
    [string]$DiskName = 'FGC_Kroll_Image_Disk',

    [Parameter(Mandatory = $true)]
    [long]$UploadSizeInBytes,

    [Parameter()]
    [string]$SkuName = 'Premium_LRS',

    [Parameter()]
    [string]$OsType = 'Windows',

    [Parameter()]
    [string]$HyperVGeneration = 'V2'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$newAzDiskConfigSplat = @{
    SkuName = $SkuName
    OsType = $OsType
    UploadSizeInBytes = $UploadSizeInBytes
    Location = $Location
    CreateOption = 'Upload'
    HyperVGeneration = $HyperVGeneration
}

$diskconfig = New-AzDiskConfig -ErrorAction Stop @newAzDiskConfigSplat
$disk = New-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName -Disk $diskconfig -ErrorAction Stop
$disk