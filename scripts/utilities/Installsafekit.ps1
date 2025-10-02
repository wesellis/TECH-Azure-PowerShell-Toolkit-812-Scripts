#Requires -Version 7.4

<#
.SYNOPSIS
    Install SafeKit

.DESCRIPTION
    Downloads and installs SafeKit high availability and load balancing software.
    Configures firewall rules and starts the CA helper service.

.PARAMETER SkFile
    Path to the SafeKit MSI installation file

.PARAMETER Passwd
    Password for the CA helper service

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions and SafeKit installation media
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SkFile,

    [Parameter(Mandatory = $true)]
    [string]$Passwd
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    $logEntry = "$timestamp [InstallSafeKit.ps1] $Message"
    Add-Content -Path ".\installsk.log" -Value $logEntry
    Write-Verbose $logEntry
}

try {
    Write-Log "Starting SafeKit installation process"

    # Check if SafeKit is already installed
    if (Test-Path -Path "C:\safekit") {
        Write-Log "SafeKit already installed"
        Write-Output "SafeKit is already installed on this system"
        return
    }

    # Verify installation file exists
    if (-not (Test-Path -Path $SkFile)) {
        $errorMsg = "Download $SkFile failed. Check calling template fileUris property."
        Write-Log $errorMsg
        throw $errorMsg
    }

    Write-Log "Installing SafeKit from: $SkFile"

    # Install SafeKit using MSI
    $argList = @(
        "/i",
        "`"$SkFile`"",
        "/qn",
        "/l*vx",
        "loginst.txt",
        "DODESKTOP='0'"
    )

    Write-Log "Running MSI installation with arguments: $($argList -join ' ')"
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $argList -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "MSI installation failed with exit code: $($process.ExitCode)"
    }

    Write-Log "SafeKit installation completed successfully"

    # Install Azure RM if script exists
    $azureRmScript = ".\installAzureRm.ps1"
    if (Test-Path -Path $azureRmScript) {
        Write-Log "Installing Azure RM"
        try {
            & $azureRmScript
            Write-Log "Azure RM installation completed"
        }
        catch {
            Write-Log "Azure RM installation failed: $($_.Exception.Message)"
            Write-Warning "Azure RM installation failed, but continuing with SafeKit setup"
        }
    }
    else {
        Write-Log "Azure RM installation script not found, skipping"
    }

    # Apply firewall rules
    Write-Log "Applying firewall rules"
    $firewallScript = "C:\safekit\private\bin\firewallcfg.cmd"
    if (Test-Path $firewallScript) {
        & $firewallScript add
        Write-Log "Firewall rules applied successfully"
    }
    else {
        Write-Warning "Firewall configuration script not found at: $firewallScript"
    }

    # Start CA helper service
    Write-Log "Starting CA helper service"
    $currentLocation = Get-Location

    try {
        $caServPath = "C:\safekit\web\bin"
        if (Test-Path $caServPath) {
            Set-Location $caServPath
            $startCaScript = ".\startcaserv.cmd"
            if (Test-Path $startCaScript) {
                & $startCaScript $Passwd
                Write-Log "CA helper service started successfully"
            }
            else {
                Write-Warning "CA service start script not found: $startCaScript"
            }
        }
        else {
            Write-Warning "CA service directory not found: $caServPath"
        }
    }
    finally {
        Set-Location $currentLocation
    }

    Write-Log "SafeKit installation and configuration completed successfully"
    Write-Output "SafeKit has been installed and configured successfully"
}
catch {
    $errorMsg = "SafeKit installation failed: $($_.Exception.Message)"
    Write-Log $errorMsg
    Write-Error $errorMsg
    throw
}
finally {
    Write-Log "End of SafeKit installation script"
}