<#
.SYNOPSIS
    6 Create Azimage

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 6 Create Azimage

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$vmName = " FGC-CR08NW2-MIG"
$rgName = " FGC_AVD_RG1"
$location = " canadacentral"
$imageName = " FGC-CR08NW2-AVD-Nerdio-image-v1"



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

$imageConfig = Set-AzImageOsDisk @setAzImageOsDiskSplat

; 
$newAzImageSplat = @{
    ImageName = $imageName
    ResourceGroupName = $rgName
    Image = $imageConfig
}
; 
$image = New-AzImage @newAzImageSplat


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================