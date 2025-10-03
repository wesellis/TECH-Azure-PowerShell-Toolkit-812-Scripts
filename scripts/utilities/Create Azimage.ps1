#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Create Azure image

.DESCRIPTION
    Create Azure image operation from a virtual machine

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$ImageName,

    [Parameter()]
    [ValidateSet('Generalized', 'Specialized')]
    [string]$OsState = 'Generalized',

    [Parameter()]
    [ValidateSet('Windows', 'Linux')]
    [string]$OsType = 'Windows'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

$vm = Get-AzVm -Name $VMName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
$diskID = $vm.StorageProfile.OsDisk.ManagedDisk.Id
$imageConfig = New-AzImageConfig -Location $Location

$setAzImageOsDiskSplat = @{
    Image = $imageConfig
    OsState = $OsState
    OsType = $OsType
    ManagedDiskId = $diskID
}

$imageConfig = Set-AzImageOsDisk @setAzImageOsDiskSplat -ErrorAction Stop

$newAzImageSplat = @{
    ImageName = $ImageName
    ResourceGroupName = $ResourceGroupName
    Image = $imageConfig
}

$image = New-AzImage @newAzImageSplat -ErrorAction Stop
$image


