#Requires -Version 7.4

<#
.SYNOPSIS
    Install Azure DevOps Build Agent

.DESCRIPTION
    Downloads and installs Azure DevOps (VSTS) build agents on Windows.
    Configures multiple agents, installs required PowerShell modules, and sets up the environment.

.PARAMETER VSTSAccount
    Azure DevOps organization name

.PARAMETER PersonalAccessToken
    Personal Access Token for authentication with Azure DevOps

.PARAMETER AgentName
    Base name for the build agents (will be suffixed with numbers)

.PARAMETER PoolName
    Agent pool name in Azure DevOps

.PARAMETER AgentCount
    Number of build agents to install and configure

.PARAMETER AdminUser
    Administrative user account for running the agents

.PARAMETER Modules
    Array of PowerShell modules to install with Name and Version properties

.PARAMETER Prerelease
    Install prerelease version of the build agent

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions, internet connectivity, and valid Azure DevOps credentials
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VSTSAccount,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PersonalAccessToken,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AgentName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PoolName,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 10)]
    [int]$AgentCount,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUser,

    [Parameter(Mandatory = $true)]
    [array]$Modules,

    [bool]$Prerelease = $false
)

$ErrorActionPreference = 'Stop'

try {
    Write-Verbose "Starting Azure DevOps Agent installation" -Verbose

    $currentLocation = Split-Path -Parent $MyInvocation.MyCommand.Definition
    Write-Verbose "Current folder: $currentLocation" -Verbose

    # Create temporary folder for agent download
    $agentTempFolderName = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Force -Path $agentTempFolderName | Out-Null
    Write-Verbose "Temporary Agent download folder: $agentTempFolderName" -Verbose

    $serverUrl = "https://dev.azure.com/$VSTSAccount"
    Write-Verbose "Server URL: $serverUrl" -Verbose

    # Download agent with retry logic
    $retryCount = 3
    $retries = 1
    $agentZipPath = "$agentTempFolderName\agent.zip"

    Write-Verbose "Downloading Agent install files" -Verbose
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    do {
        try {
            Write-Verbose "Trying to get download URL for latest Azure DevOps agent release... (Attempt $retries)"
            $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases"
            $latestRelease = $latestRelease |
                Where-Object { $_.prerelease -eq $Prerelease -and $_.assets -ne $null } |
                Sort-Object created_at -Descending |
                Select-Object -First 1

            if (-not $latestRelease) {
                throw "No suitable release found"
            }

            $windowsAsset = $latestRelease.assets | Where-Object { $_.name -like "*win-x64*" }
            if (-not $windowsAsset) {
                throw "Windows x64 asset not found in release"
            }

            $downloadUrl = $windowsAsset.browser_download_url
            Write-Verbose "Downloading from: $downloadUrl"

            Invoke-WebRequest -Uri $downloadUrl -OutFile $agentZipPath
            Write-Verbose "Downloaded agent successfully on attempt $retries" -Verbose
            break
        }
        catch {
            $exceptionText = ($_ | Out-String).Trim()
            Write-Warning "Exception occurred downloading agent: $exceptionText in try number $retries"
            $retries++
            if ($retries -le $retryCount) {
                Start-Sleep -Seconds 30
            }
        }
    }
    while ($retries -le $retryCount)

    if ($retries -gt $retryCount) {
        throw "Failed to download agent after $retryCount attempts"
    }

    # Install and configure agents
    for ($i = 0; $i -lt $AgentCount; $i++) {
        $agent = "$AgentName-$i"
        $agentInstallationPath = Join-Path "C:\" $agent

        Write-Verbose "Installing agent: $agent at $agentInstallationPath" -Verbose

        # Create agent directory
        New-Item -ItemType Directory -Force -Path $agentInstallationPath | Out-Null

        # Extract agent files
        Write-Verbose "Extracting the zip file for the agent" -Verbose
        Expand-Archive -Path $agentZipPath -DestinationPath $agentInstallationPath -Force

        # Unblock files
        Write-Verbose "Unblocking files" -Verbose
        Get-ChildItem -Recurse -Path $agentInstallationPath | Unblock-File

        # Configure agent
        $agentConfigPath = Join-Path $agentInstallationPath 'config.cmd'
        Write-Verbose "Agent Location = $agentConfigPath" -Verbose

        if (-not (Test-Path $agentConfigPath)) {
            throw "Agent configuration script not found: $agentConfigPath"
        }

        Write-Verbose "Configuring agent '$agent'" -Verbose

        Push-Location -Path $agentInstallationPath
        try {
            $configArgs = @(
                '--unattended',
                '--url', $serverUrl,
                '--auth', 'PAT',
                '--token', $PersonalAccessToken,
                '--pool', $PoolName,
                '--agent', $agent,
                '--runasservice'
            )

            & .\config.cmd @configArgs
            Write-Verbose "Agent configuration exit code: $LASTEXITCODE" -Verbose

            if ($LASTEXITCODE -ne 0) {
                throw "Agent configuration failed with exit code: $LASTEXITCODE"
            }
        }
        finally {
            Pop-Location
        }
    }

    # Configure PowerShell module path
    Write-Verbose "Configuring PowerShell module path" -Verbose
    $currentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
    $modulePath = "C:\Modules"

    if ($currentValue -notlike "*$modulePath*") {
        [Environment]::SetEnvironmentVariable("PSModulePath", "$currentValue;$modulePath", "Machine")
        $newValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
        Write-Verbose "New PSModulePath: $newValue" -Verbose
    }

    # Create modules directory
    if (-not (Test-Path -Path $modulePath)) {
        New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
        Write-Verbose "Created modules directory: $modulePath" -Verbose
    }

    # Configure PowerShell repository
    Write-Verbose "Configuring PowerShell repository and package providers" -Verbose
    Install-PackageProvider -Name NuGet -Force -Scope AllUsers
    Import-PackageProvider -Name NuGet -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

    # Install custom modules
    Write-Verbose "Installing custom PowerShell modules" -Verbose
    foreach ($module in $Modules) {
        try {
            Write-Verbose "Installing module: $($module.Name) version $($module.Version)" -Verbose
            if ($module.Version) {
                Find-Module -Name $module.Name -RequiredVersion $module.Version -Repository PSGallery |
                    Save-Module -Path $modulePath -Force
            }
            else {
                Find-Module -Name $module.Name -Repository PSGallery |
                    Save-Module -Path $modulePath -Force
            }
        }
        catch {
            Write-Warning "Failed to install module $($module.Name): $($_.Exception.Message)"
        }
    }

    # Update default modules
    Write-Verbose "Updating default PowerShell modules" -Verbose
    $defaultModules = @("PowerShellGet", "PackageManagement", "Pester")

    foreach ($module in $defaultModules) {
        try {
            Write-Verbose "Updating module: $module" -Verbose
            if (Get-Module -Name $module -ErrorAction SilentlyContinue) {
                Remove-Module -Name $module -Force
            }
            Find-Module -Name $module -Repository PSGallery |
                Install-Module -Force -Confirm:$false -SkipPublisherCheck -AllowClobber
        }
        catch {
            Write-Warning "Failed to update module $module: $($_.Exception.Message)"
        }
    }

    # Clean up legacy Azure PowerShell if requested (commented out for safety)
    <#
    Write-Verbose "Checking for legacy Azure PowerShell installation" -Verbose
    $programName = "Microsoft Azure PowerShell"
    $app = Get-CimInstance -Class Win32_Product -Filter "Name Like '$($programName)%'" -ErrorAction SilentlyContinue

    if ($app) {
        Write-Warning "Legacy Azure PowerShell found. Consider manual removal if needed."
        # Uncomment the next line only if you want to automatically remove legacy Azure PowerShell
        # $app.Uninstall()
    }
    #>

    # Clean up temporary files
    if (Test-Path $agentTempFolderName) {
        Remove-Item -Path $agentTempFolderName -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Verbose "Azure DevOps Agent installation completed successfully" -Verbose
    Write-Output "Successfully installed $AgentCount Azure DevOps build agents"
}
catch {
    $errorMsg = "Azure DevOps Agent installation failed: $($_.Exception.Message)"
    Write-Error $errorMsg
    throw
}