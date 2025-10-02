#Requires -Version 7.4

<#
.SYNOPSIS
    Install Octopus Deploy Server

.DESCRIPTION
    Downloads, installs, and configures Octopus Deploy server with database and licensing.
    Creates firewall rules and sets up administrative user.

.PARAMETER SqlDbConnectionString
    Base64 encoded SQL Server connection string for Octopus Deploy database

.PARAMETER LicenseFullName
    Base64 encoded full name for license registration

.PARAMETER LicenseOrganisationName
    Base64 encoded organization name for license registration

.PARAMETER LicenseEmailAddress
    Base64 encoded email address for license registration

.PARAMETER OctopusAdminUsername
    Base64 encoded username for Octopus Deploy administrator

.PARAMETER OctopusAdminPassword
    Base64 encoded password for Octopus Deploy administrator

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions, SQL Server, and internet connectivity
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SqlDbConnectionString,

    [Parameter(Mandatory = $true)]
    [string]$LicenseFullName,

    [Parameter(Mandatory = $true)]
    [string]$LicenseOrganisationName,

    [Parameter(Mandatory = $true)]
    [string]$LicenseEmailAddress,

    [Parameter(Mandatory = $true)]
    [string]$OctopusAdminUsername,

    [Parameter(Mandatory = $true)]
    [string]$OctopusAdminPassword
)

$ErrorActionPreference = 'Stop'

# Configuration
$config = @{}
$OctopusDeployVersion = "Octopus.3.0.12.2366-x64"
$MsiFileName = "Octopus.3.0.12.2366-x64.msi"
$DownloadBaseUrl = "https://download.octopusdeploy.com/octopus/"
$DownloadUrl = $DownloadBaseUrl + $MsiFileName
$InstallBasePath = "D:\Install\"
$MsiPath = $InstallBasePath + $MsiFileName
$MsiLogPath = $InstallBasePath + $MsiFileName + '.log'
$InstallerLogPath = $InstallBasePath + 'Install-OctopusDeploy.ps1.log'
$OctopusLicenseUrl = "https://octopusdeploy.com/api/licenses/trial"
$OFS = "`r`n"

function Write-Log {
    param([string]$message)

    $timestamp = ([System.DateTime]::UTCNow).ToString("yyyy'-'MM'-'dd'T'HH':'mm':'ss")
    Write-Output "[$timestamp] $message"
}

function Write-CommandOutput {
    param([string]$output)

    if ($output -eq "") { return }
    Write-Output ""
    $output.Trim().Split("`n") | ForEach-Object { Write-Output "`t| $($_.Trim())" }
    Write-Output ""
}

function Get-Config {
    Write-Log "======================================"
    Write-Log "Get Config"
    Write-Log ""
    Write-Log "Parsing script parameters ..."

    $config.Add("sqlDbConnectionString", [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($SqlDbConnectionString)))
    $config.Add("licenseFullName", [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($LicenseFullName)))
    $config.Add("licenseOrganisationName", [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($LicenseOrganisationName)))
    $config.Add("licenseEmailAddress", [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($LicenseEmailAddress)))
    $config.Add("octopusAdminUsername", [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($OctopusAdminUsername)))
    $config.Add("octopusAdminPassword", [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($OctopusAdminPassword)))

    Write-Log "done."
    Write-Log ""
}

function Create-InstallLocation {
    Write-Log "======================================"
    Write-Log "Create Install Location"
    Write-Log ""

    if (!(Test-Path $InstallBasePath)) {
        Write-Log "Creating installation folder at '$InstallBasePath' ..."
        New-Item -ItemType Directory -Path $InstallBasePath | Out-Null
        Write-Log "done."
    }
    else {
        Write-Log "Installation folder at '$InstallBasePath' already exists."
    }
    Write-Log ""
}

function Install-OctopusDeploy {
    Write-Log "======================================"
    Write-Log "Install Octopus Deploy"
    Write-Log ""

    Write-Log "Downloading Octopus Deploy installer '$DownloadUrl' to '$MsiPath' ..."
    (New-Object Net.WebClient).DownloadFile($DownloadUrl, $MsiPath)
    Write-Log "done."

    Write-Log "Installing via '$MsiPath' ..."
    $exe = 'msiexec.exe'
    $args = @('/qn', '/i', $MsiPath, '/l*v', $MsiLogPath)
    $output = & $exe $args
    Write-CommandOutput $output
    Write-Log "done."
    Write-Log ""
}

function Configure-OctopusDeploy {
    Write-Log "======================================"
    Write-Log "Configure Octopus Deploy"
    Write-Log ""

    $exe = "${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe"
    $count = 0

    while (!(Test-Path $exe) -and $count -lt 5) {
        Write-Log "$exe - not available yet ... waiting 10s ..."
        Start-Sleep -Seconds 10
        $count = $count + 1
    }

    Write-Log "Creating Octopus Deploy instance ..."
    $args = @('create-instance', '--console', '--instance', 'OctopusServer', '--config', 'C:\Octopus\OctopusServer.config')
    $output = & $exe $args
    Write-CommandOutput $output
    Write-Log "done."

    Write-Log "Configuring Octopus Deploy instance ..."
    $args = @(
        'configure', '--console', '--instance', 'OctopusServer', '--home', 'C:\Octopus',
        '--storageConnectionString', $($config.sqlDbConnectionString),
        '--upgradeCheck', 'True', '--upgradeCheckWithStatistics', 'True',
        '--webAuthenticationMode', 'UsernamePassword', '--webForceSSL', 'False',
        '--webListenPrefixes', 'http://localhost:80/', '--commsListenPort', '10943'
    )
    $output = & $exe $args
    Write-CommandOutput $output
    Write-Log "done."

    Write-Log "Creating Octopus Deploy database ..."
    $args = @('database', '--console', '--instance', 'OctopusServer', '--create')
    $output = & $exe $args
    Write-CommandOutput $output
    Write-Log "done."

    Write-Log "Stopping Octopus Deploy instance ..."
    $args = @('service', '--console', '--instance', 'OctopusServer', '--stop')
    $output = & $exe $args
    Write-CommandOutput $output
    Write-Log "done."

    Write-Log "Creating Admin User for Octopus Deploy instance ..."
    $args = @('admin', '--console', '--instance', 'OctopusServer', '--username', $($config.octopusAdminUsername), '--password', $($config.octopusAdminPassword))
    $output = & $exe $args
    Write-CommandOutput $output
    Write-Log "done."

    Write-Log "Obtaining a trial license for Full Name: $($config.licenseFullName), Organisation Name: $($config.licenseOrganisationName), Email Address: $($config.licenseEmailAddress) ..."
    $PostParams = @{
        FullName = $($config.licenseFullName)
        Organization = $($config.licenseOrganisationName)
        EmailAddress = $($config.licenseEmailAddress)
    }
    $response = Invoke-WebRequest -UseBasicParsing -Uri $OctopusLicenseUrl -Method POST -Body $PostParams
    $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
    $bytes = $utf8NoBOM.GetBytes($response.Content)
    $LicenseBase64 = [System.Convert]::ToBase64String($bytes)
    Write-Log "done."

    Write-Log "Installing license for Octopus Deploy instance ..."
    $args = @('license', '--console', '--instance', 'OctopusServer', '--licenseBase64', $LicenseBase64)
    $output = & $exe $args
    Write-CommandOutput $output
    Write-Log "done."

    Write-Log "Reconfigure and start Octopus Deploy instance ..."
    $args = @('service', '--console', '--instance', 'OctopusServer', '--install', '--reconfigure', '--start')
    $output = & $exe $args
    Write-CommandOutput $output
    Write-Log "done."
    Write-Log ""
}

function Configure-Firewall {
    Write-Log "======================================"
    Write-Log "Configure Firewall"
    Write-Log ""

    $FirewallRuleName = "Allow_Port80_HTTP"
    if ((Get-NetFirewallRule -Name $FirewallRuleName -ErrorAction Ignore) -eq $null) {
        Write-Log "Creating firewall rule to allow port 80 HTTP traffic ..."
        $FirewallRule = @{
            Name = $FirewallRuleName
            DisplayName = "Allow Port 80 (HTTP)"
            Description = "Port 80 for HTTP traffic"
            Direction = 'Inbound'
            Protocol = 'TCP'
            LocalPort = 80
            Enabled = 'True'
            Profile = 'Any'
            Action = 'Allow'
        }
        $output = (New-NetFirewallRule @FirewallRule | Out-String)
        Write-CommandOutput $output
        Write-Log "done."
    }
    else {
        Write-Log "Firewall rule to allow port 80 HTTP traffic already exists."
    }
    Write-Log ""
}

try {
    Write-Log "======================================"
    Write-Log "Installing '$OctopusDeployVersion'"
    Write-Log "======================================"
    Write-Log ""

    Get-Config
    Create-InstallLocation
    Install-OctopusDeploy
    Configure-OctopusDeploy
    Configure-Firewall

    Write-Log "Installation successful."
    Write-Log ""
}
catch {
    Write-Log "Error: $($_.Exception.Message)"
    Write-Error $_.Exception.Message
    throw
}