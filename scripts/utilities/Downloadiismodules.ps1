#Requires -Version 7.4

<#
.SYNOPSIS
    Downloads and installs IIS modules and management tools

.DESCRIPTION
    This script downloads and installs various IIS modules, management tools, and extensions
    commonly needed for web server configurations. It can install modules from multiple sources
    including Windows Features, Web Platform Installer, and direct downloads.

.PARAMETER ModuleList
    Array of IIS modules to install. If not specified, installs a default set of common modules.

.PARAMETER IncludeManagementTools
    Switch to include IIS management tools and console

.PARAMETER IncludeDevelopmentFeatures
    Switch to include development-related IIS features like ASP.NET

.PARAMETER InstallWebPlatformInstaller
    Switch to install Web Platform Installer for additional modules

.PARAMETER LogPath
    Path for installation logs. Defaults to C:\temp\IISInstall.log

.EXAMPLE
    .\Downloadiismodules.ps1 -IncludeManagementTools -IncludeDevelopmentFeatures

.EXAMPLE
    .\Downloadiismodules.ps1 -ModuleList @("IIS-HttpRedirect", "IIS-HttpLogging", "IIS-RequestFiltering") -LogPath "C:\logs\iis.log"

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires administrative privileges
    Compatible with Windows Server 2016 and later
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$ModuleList = @(),

    [Parameter()]
    [switch]$IncludeManagementTools,

    [Parameter()]
    [switch]$IncludeDevelopmentFeatures,

    [Parameter()]
    [switch]$InstallWebPlatformInstaller,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = "C:\temp\IISInstall.log"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Level = 'Information'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Ensure log directory exists
    $logDir = Split-Path -Path $LogPath -Parent
    if (!(Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Write to log file
    $logMessage | Out-File -FilePath $LogPath -Append

    # Write to console
    switch ($Level) {
        'Information' { Write-Host $logMessage -ForegroundColor Green }
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message }
    }
}

function Install-WindowsFeatures {
    param(
        [Parameter(Mandatory)]
        [string[]]$Features
    )

    Write-Log "Installing Windows Features: $($Features -join ', ')"

    foreach ($feature in $Features) {
        try {
            $result = Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart
            if ($result.RestartNeeded) {
                Write-Log "Feature '$feature' installed successfully (restart required)" -Level Warning
            }
            else {
                Write-Log "Feature '$feature' installed successfully"
            }
        }
        catch {
            Write-Log "Failed to install feature '$feature': $($_.Exception.Message)" -Level Error
        }
    }
}

function Install-WebPlatformInstaller {
    Write-Log "Downloading and installing Web Platform Installer"

    $webPiUrl = "https://download.microsoft.com/download/C/F/F/CFF3A0B8-99D4-41A2-AE1A-496C08BEB904/WebPlatformInstaller_amd64_en-US.msi"
    $webPiPath = "$env:TEMP\WebPlatformInstaller.msi"

    try {
        Invoke-WebRequest -Uri $webPiUrl -OutFile $webPiPath -UseBasicParsing
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$webPiPath`" /quiet" -Wait
        Write-Log "Web Platform Installer installed successfully"

        # Clean up
        Remove-Item -Path $webPiPath -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Log "Failed to install Web Platform Installer: $($_.Exception.Message)" -Level Error
    }
}

try {
    Write-Log "Starting IIS modules installation process"

    # Default module list if none specified
    if ($ModuleList.Count -eq 0) {
        $ModuleList = @(
            "IIS-WebServerRole",
            "IIS-WebServer",
            "IIS-CommonHttpFeatures",
            "IIS-DefaultDocument",
            "IIS-DirectoryBrowsing",
            "IIS-StaticContent",
            "IIS-HttpErrors",
            "IIS-HttpRedirect",
            "IIS-ApplicationDevelopment",
            "IIS-RequestFiltering",
            "IIS-Security",
            "IIS-Performance",
            "IIS-HttpCompressionStatic",
            "IIS-HttpLogging",
            "IIS-LoggingLibraries",
            "IIS-RequestMonitor",
            "IIS-HttpTracing",
            "IIS-BasicAuthentication",
            "IIS-WindowsAuthentication"
        )
        Write-Log "Using default module list with $($ModuleList.Count) modules"
    }

    # Add management tools if requested
    if ($IncludeManagementTools) {
        Write-Log "Including IIS management tools"
        $ModuleList += @(
            "IIS-WebServerManagementTools",
            "IIS-ManagementConsole",
            "IIS-ManagementService",
            "IIS-ManagementScriptingTools"
        )
    }

    # Add development features if requested
    if ($IncludeDevelopmentFeatures) {
        Write-Log "Including development features"
        $ModuleList += @(
            "IIS-NetFxExtensibility45",
            "IIS-ISAPIExtensions",
            "IIS-ISAPIFilter",
            "IIS-ASPNET45",
            "IIS-ApplicationInit"
        )
    }

    # Remove duplicates
    $ModuleList = $ModuleList | Sort-Object | Get-Unique

    Write-Log "Total modules to install: $($ModuleList.Count)"

    # Install Windows Features
    Install-WindowsFeatures -Features $ModuleList

    # Install Web Platform Installer if requested
    if ($InstallWebPlatformInstaller) {
        Install-WebPlatformInstaller
    }

    # Check installation status
    Write-Log "Verifying installed features..."
    $installedFeatures = @()
    $failedFeatures = @()

    foreach ($feature in $ModuleList) {
        try {
            $featureState = Get-WindowsOptionalFeature -Online -FeatureName $feature
            if ($featureState.State -eq "Enabled") {
                $installedFeatures += $feature
            }
            else {
                $failedFeatures += $feature
            }
        }
        catch {
            $failedFeatures += $feature
        }
    }

    Write-Log "Installation Summary:"
    Write-Log "Successfully installed: $($installedFeatures.Count) features"
    Write-Log "Failed installations: $($failedFeatures.Count) features"

    if ($failedFeatures.Count -gt 0) {
        Write-Log "Failed features: $($failedFeatures -join ', ')" -Level Warning
    }

    # Check if restart is needed
    $restartNeeded = $false
    try {
        $restartNeeded = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) -ne $null
    }
    catch {
        # Registry key may not exist
    }

    if ($restartNeeded) {
        Write-Log "A system restart is required to complete the installation" -Level Warning
        Write-Log "Please restart the system when convenient"
    }
    else {
        Write-Log "No restart required for installed features"
    }

    Write-Log "IIS modules installation completed successfully"

    # Return summary
    return @{
        TotalRequested = $ModuleList.Count
        Installed = $installedFeatures.Count
        Failed = $failedFeatures.Count
        FailedFeatures = $failedFeatures
        RestartRequired = $restartNeeded
    }
}
catch {
    $errorMessage = "IIS modules installation failed: $($_.Exception.Message)"
    Write-Log $errorMessage -Level Error
    throw
}
finally {
    Write-Log "Installation log saved to: $LogPath"
}