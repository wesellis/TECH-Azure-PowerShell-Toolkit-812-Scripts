<#
.SYNOPSIS
    Prepvhdfile

.DESCRIPTION
    Prepvhdfile operation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
[OutputType([bool])]
 {
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param([Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Path)
    if (!(Test-Path $Path)) {
        Write-Warning "Required path not found: $Path"
        return $false
    }
    return $true
}
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
Convert-VHD -Path filepathtoyourDynamicVHDorVHDX.VHDX file  -DestinationPath destinationfileofnewVHD.VHD -VHDType Fixed
Get-VHD -Path 'PathtoYourFixedSized.VHD' | Select-Object *
Resize-VHD -Path 'PathtoYourFixedSized.VHD' -SizeBytes '274877906944' #for a 256 GiB Disk
Get-VHD -Path 'PathtoYourFixedSized.VHD' | Select-Object *
$VHDfile = 'E:\FGC_Kroll_Lab_P2V_Clone_VHD_to_Azure\FGC-CR08NW2.VHD';
$vhdSizeBytes = (Get-Item -ErrorAction Stop $VHDfile).length
Resize-VHD -Path 'D:\FGC_Kroll_Lab_P2V_Clone_VHD_to_Azure\FGC-CR08NW2_fixed.VHD' -SizeBytes '274877906944'
Get-VHD -Path 'D:\FGC_Kroll_Lab_P2V_Clone_VHD_to_Azure\FGC-CR08NW2_fixed.VHD' | Select-Object *
$Script:SYS_ENV_SYSDIRECTORY = $null
$Script:SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory
Write-Host "Starting Sysprep with OOBE"
& $SYS_ENV_SYSDIRECTORY\sysprep\sysprep.exe /generalize /reboot /oobe
Get-AppxPackage -AllUsers *HP* | Remove-AppxPackage -AllUsers #the AllUsers parameter is important to show the app in all users
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

