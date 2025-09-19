#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    4 Creat Azdisk

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 4 Creat Azdisk

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$location = 'Canada Central'
$imageName = 'FGC_Kroll_Image'
$rgName = 'FGC_Kroll_Image_RG'
$WEDiskname = 'FGC_Kroll_Image_Disk'

; 
$newAzDiskConfigSplat = @{
    # SkuName = 'Standard_LRS'
    SkuName = 'Premium_LRS'
    OsType = 'Windows'
    UploadSizeInBytes = $vhdSizeBytes
    Location = $location
    CreateOption = 'Upload'
    HyperVGeneration = 'V2'
}
; 
$diskconfig = New-AzDiskConfig -ErrorAction Stop @newAzDiskConfigSplat

New-AzDisk -ResourceGroupName $rgName -DiskName $WEDiskname -Disk $diskconfig


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
