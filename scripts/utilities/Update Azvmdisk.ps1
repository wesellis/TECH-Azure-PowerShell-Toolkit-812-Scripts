#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Update Azvmdisk

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$diskupdateconfig = New-AzDiskUpdateConfig -DiskSizeGB 10 -SkuName Premium_LRS -OsType Windows -CreateOption Empty -EncryptionSettingsEnabled $true;
$disk | Update-AzDisk
$ErrorActionPreference = "Stop";
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$diskupdateconfig = New-AzDiskUpdateConfig -DiskSizeGB 10 -SkuName Premium_LRS -OsType Windows -CreateOption Empty -EncryptionSettingsEnabled $true;
Update-AzDisk -ResourceGroupName 'ResourceGroup01' -DiskName 'Disk01' -DiskUpdate $diskupdateconfig;
$diskupdateconfig = New-AzDiskUpdateConfig -SkuName Premium_LRS
Update-AzDisk -ResourceGroupName 'ResourceGroup01' -DiskName 'Disk01' -DiskUpdate $diskupdateconfig;
$setAzVMOSDiskSplat = @{
    VM           = $VirtualMachine
    Name         = $OSDiskName
    # VhdUri = $OSDiskUri
    # SourceImageUri = $SourceImageUri
    Caching      = $OSDiskCaching
    CreateOption = $OSCreateOption
    # Windows = $true
    DiskSizeInGB = '256'
}
$VirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat
$diskName = $OSDiskName
$rgName = $ResourceGroupName
$storageType = 'Standard_LRS'
$disk = Get-AzDisk -DiskName $diskName -ResourceGroupName $rgName
$disk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($storageType)
$disk | Update-AzDisk
$diskName = $OSDiskName
$rgName = $ResourceGroupName;
$storageType = 'Standard_LRS';
$disk = Get-AzDisk -DiskName $diskName -ResourceGroupName $rgName
$disk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($storageType)
$disk | Update-AzDisk


