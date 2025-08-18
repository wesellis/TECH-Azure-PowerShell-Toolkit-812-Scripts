<#
.SYNOPSIS
    Update Azvmdisk

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
    We Enhanced Update Azvmdisk

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$diskupdateconfig = New-AzDiskUpdateConfig -DiskSizeGB 10 -SkuName Premium_LRS -OsType Windows -CreateOption Empty -EncryptionSettingsEnabled $true;
$disk | Update-AzDisk


$WEErrorActionPreference = "Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }
; 
$diskupdateconfig = New-AzDiskUpdateConfig -DiskSizeGB 10 -SkuName Premium_LRS -OsType Windows -CreateOption Empty -EncryptionSettingsEnabled $true;

Update-AzDisk -ResourceGroupName 'ResourceGroup01' -DiskName 'Disk01' -DiskUpdate $diskupdateconfig;




$diskupdateconfig = New-AzDiskUpdateConfig -SkuName Premium_LRS
Update-AzDisk -ResourceGroupName 'ResourceGroup01' -DiskName 'Disk01' -DiskUpdate $diskupdateconfig;













$setAzVMOSDiskSplat = @{
    VM           = $WEVirtualMachine
    Name         = $WEOSDiskName
    # VhdUri = $WEOSDiskUri
    # SourceImageUri = $WESourceImageUri
    Caching      = $WEOSDiskCaching
    CreateOption = $WEOSCreateOption
    # Windows = $true
    DiskSizeInGB = '256'
}
$WEVirtualMachine = Set-AzVMOSDisk @setAzVMOSDiskSplat











$diskName = $WEOSDiskName

$rgName = $WEResourceGroupName

$storageType = 'Standard_LRS'


$disk = Get-AzDisk -DiskName $diskName -ResourceGroupName $rgName










$disk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($storageType)
$disk | Update-AzDisk



$diskName = $WEOSDiskName
$rgName = $WEResourceGroupName; 
$storageType = 'Standard_LRS'; 
$disk = Get-AzDisk -DiskName $diskName -ResourceGroupName $rgName
$disk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($storageType)
$disk | Update-AzDisk


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================