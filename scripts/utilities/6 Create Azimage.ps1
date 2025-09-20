#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Create Azimage

.DESCRIPTION
    Create Azimage operation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$vmName = "FGC-CR08NW2-MIG"
$rgName = "FGC_AVD_RG1"
$location = " canadacentral"
$imageName = "FGC-CR08NW2-AVD-Nerdio-image-v1"
$vm = Get-AzVm -Name $vmName -ResourceGroupName $rgName
$diskID = $vm.StorageProfile.OsDisk.ManagedDisk.Id
$imageConfig = New-AzImageConfig -Location $location
$setAzImageOsDiskSplat = @{
    Image = $imageConfig
    OsState = 'Generalized'
    # OsState = 'Specialized'
    OsType = 'Windows'
    # ManagedDiskId = $disk.Id
    ManagedDiskId = $diskID
}
$imageConfig = Set-AzImageOsDisk -ErrorAction Stop @setAzImageOsDiskSplat
$newAzImageSplat = @{
    ImageName = $imageName
    ResourceGroupName = $rgName
    Image = $imageConfig
}
$image = New-AzImage -ErrorAction Stop @newAzImageSplat


