<#
.SYNOPSIS
    We Enhanced 2 Prepvhdfile

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

function WE-Test-RequiredPath {
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPath)
    if (!(Test-Path $WEPath)) {
        Write-Warning "Required path not found: $WEPath"
        return $false
    }
    return $true
}


	









$WEErrorActionPreference = " Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

Convert-VHD -Path filepathtoyourDynamicVHDorVHDX.VHDX file  -DestinationPath destinationfileofnewVHD.VHD -VHDType Fixed


Get-VHD -Path 'PathtoYourFixedSized.VHD' | Select-Object *          


Resize-VHD -Path 'PathtoYourFixedSized.VHD' -SizeBytes '274877906944' #for a 256 GiB Disk


Get-VHD -Path 'PathtoYourFixedSized.VHD' | Select-Object * 



$WEVHDfile = 'E:\FGC_Kroll_Lab_P2V_Clone_VHD_to_Azure\FGC-CR08NW2.VHD'; 
$vhdSizeBytes = (Get-Item $WEVHDfile).length



	



Resize-VHD -Path 'D:\FGC_Kroll_Lab_P2V_Clone_VHD_to_Azure\FGC-CR08NW2_fixed.VHD' -SizeBytes '274877906944'


Get-VHD -Path 'D:\FGC_Kroll_Lab_P2V_Clone_VHD_to_Azure\FGC-CR08NW2_fixed.VHD' | Select-Object * 



$WEScript:SYS_ENV_SYSDIRECTORY = $null
$WEScript:SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory


write-host " Starting Sysprep with OOBE"
& $WESYS_ENV_SYSDIRECTORY\sysprep\sysprep.exe /generalize /reboot /oobe




Get-AppxPackage -AllUsers *HP* | Remove-AppxPackage -AllUsers #the AllUsers parameter is important to show the app in all users







# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
