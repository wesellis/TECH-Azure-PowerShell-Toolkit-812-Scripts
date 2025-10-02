#Requires -Version 7.4

<#
.SYNOPSIS
    Configure WinGet for PowerShell 7

.DESCRIPTION
    Azure automation script to ensure that WinGet is installed and ready to use for the current user with PowerShell 7

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Verbose "[$Timestamp] [$Level] $Message"
}

function Install-WinGetModule {
    Write-Log "Checking for Microsoft.WinGet.Client module..."

    try {
        $module = Get-InstalledModule -Name Microsoft.WinGet.Client -ErrorAction SilentlyContinue
        if ($module) {
            Write-Log "Microsoft.WinGet.Client module version $($module.Version) is already installed"
            return $true
        }
    }
    catch {
        Write-Log "Microsoft.WinGet.Client module not found, installing..." "WARN"
    }

    try {
        Write-Log "Installing Microsoft.WinGet.Client module..."
        Install-Module -Name Microsoft.WinGet.Client -Scope AllUsers -Force -AllowClobber
        Write-Log "Microsoft.WinGet.Client module installed successfully"
        return $true
    }
    catch {
        Write-Error "Failed to install Microsoft.WinGet.Client module: $($_.Exception.Message)"
        return $false
    }
}

function Repair-WinGetPackageManager {
    param(
        [switch]$Latest,
        [switch]$Force
    )

    Write-Log "Repairing WinGet Package Manager..."

    try {
        # Import the module
        Import-Module Microsoft.WinGet.Client -Force

        # Check if Repair-WinGetPackageManager cmdlet exists
        if (Get-Command Repair-WinGetPackageManager -ErrorAction SilentlyContinue) {
            $params = @{}
            if ($Latest) { $params['Latest'] = $true }
            if ($Force) { $params['Force'] = $true }

            Write-Log "Running Repair-WinGetPackageManager..."
            Repair-WinGetPackageManager @params

            Write-Log "WinGet Package Manager repair completed"
        }
        else {
            Write-Log "Repair-WinGetPackageManager cmdlet not available, using alternative method..." "WARN"

            # Alternative repair method
            Write-Log "Resetting WinGet sources..."
            winget source reset --force

            Write-Log "Updating WinGet sources..."
            winget source update
        }

        return $true
    }
    catch {
        Write-Error "Failed to repair WinGet Package Manager: $($_.Exception.Message)"
        return $false
    }
}

function Test-WinGetInstallation {
    Write-Log "Testing WinGet installation..."

    try {
        $wingetVersion = winget --version
        Write-Log "WinGet version: $wingetVersion"

        # Test WinGet functionality
        $sources = winget source list
        if ($sources) {
            Write-Log "WinGet sources are accessible"
            return $true
        }
    }
    catch {
        Write-Log "WinGet test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }

    return $false
}

$IsFailed = $false

try {
    Write-Log "=== Ensure WinGet is ready for the current user"

    # Install WinGet module if needed
    if (-not (Install-WinGetModule)) {
        $IsFailed = $true
    }

    # Repair WinGet Package Manager
    if (-not $IsFailed) {
        if (-not (Repair-WinGetPackageManager -Latest -Force)) {
            $IsFailed = $true
        }
    }

    # Test WinGet installation
    if (-not $IsFailed) {
        if (-not (Test-WinGetInstallation)) {
            $IsFailed = $true
        }
    }
}
catch {
    Write-Log "!!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" "ERROR"
    $IsFailed = $true
}

if ($IsFailed) {
    Write-Log "=== Attempting to repair WinGet Client module" "WARN"

    try {
        # Show current module info
        Get-InstalledModule -ErrorAction Stop Microsoft.WinGet.Client | Format-List

        # Uninstall and reinstall the module
        Write-Log "Uninstalling Microsoft.WinGet.Client module..."
        Uninstall-Module Microsoft.WinGet.Client -AllowPrerelease -AllVersions -Force -ErrorAction Continue

        Write-Log "Reinstalling Microsoft.WinGet.Client module..."
        Install-Module Microsoft.WinGet.Client -Scope AllUsers -Force -ErrorAction Continue

        # Try repair again
        Repair-WinGetPackageManager -Latest -Force

        # Final test
        if (Test-WinGetInstallation) {
            Write-Log "WinGet repair successful"
            $IsFailed = $false
        }
    }
    catch {
        Write-Error "Failed to repair WinGet: $($_.Exception.Message)"
        throw
    }
}

if (-not $IsFailed) {
    Write-Log "WinGet configuration for PowerShell 7 completed successfully"
}
else {
    throw "WinGet configuration failed. Please check the logs for details."
}