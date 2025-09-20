#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Creat Azdisk

.DESCRIPTION
    Creat Azdisk operation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$location = 'Canada Central'
$imageName = 'FGC_Kroll_Image'
$rgName = 'FGC_Kroll_Image_RG'
$Diskname = 'FGC_Kroll_Image_Disk'
$newAzDiskConfigSplat = @{
    # SkuName = 'Standard_LRS'
    SkuName = 'Premium_LRS'
    OsType = 'Windows'
    UploadSizeInBytes = $vhdSizeBytes
    Location = $location
    CreateOption = 'Upload'
    HyperVGeneration = 'V2'
}
$diskconfig = New-AzDiskConfig -ErrorAction Stop @newAzDiskConfigSplat
New-AzDisk -ResourceGroupName $rgName -DiskName $Diskname -Disk $diskconfig\n

