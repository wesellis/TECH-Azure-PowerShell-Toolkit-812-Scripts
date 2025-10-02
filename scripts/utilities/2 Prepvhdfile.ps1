#Requires -Version 7.4
#Requires -Modules Hyper-V

<#
.SYNOPSIS
    Prepvhdfile

.DESCRIPTION
    Prepare VHD file for Azure upload by converting to fixed size and running sysprep

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Note: This script requires Hyper-V PowerShell module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceVHDPath,

    [Parameter(Mandatory = $true)]
    [string]$DestinationVHDPath,

    [Parameter(Mandatory = $true)]
    [long]$SizeBytes = 274877906944,  # 256 GiB

    [Parameter()]
    [switch]$RunSysprep
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Test-VHDPath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )
    if (!(Test-Path $Path)) {
        Write-Warning "Required path not found: $Path"
        return $false
    }
    return $true
}

try {
    if (!(Test-VHDPath -Path $SourceVHDPath)) {
        throw "Source VHD file not found: $SourceVHDPath"
    }

    Write-Output "Converting VHD to fixed size..."
    Convert-VHD -Path $SourceVHDPath -DestinationPath $DestinationVHDPath -VHDType Fixed

    Write-Output "Getting VHD information..."
    Get-VHD -Path $DestinationVHDPath | Select-Object *

    Write-Output "Resizing VHD to specified size..."
    Resize-VHD -Path $DestinationVHDPath -SizeBytes $SizeBytes

    Write-Output "Getting updated VHD information..."
    Get-VHD -Path $DestinationVHDPath | Select-Object *

    if ($RunSysprep) {
        Write-Output "Removing HP AppX packages..."
        Get-AppxPackage -AllUsers *HP* | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

        $SYS_ENV_SYSDIRECTORY = [System.Environment]::SystemDirectory
        Write-Output "Starting Sysprep with OOBE..."
        & "$SYS_ENV_SYSDIRECTORY\sysprep\sysprep.exe" /generalize /reboot /oobe
    }

    Write-Output "VHD preparation completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}