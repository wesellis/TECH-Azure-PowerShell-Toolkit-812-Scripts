#Requires -Version 7.4

<#
.SYNOPSIS
    Install SCCM Distribution Point

.DESCRIPTION
    Azure automation script that installs and configures SCCM Distribution Point on a specified server

.PARAMETER DomainFullName
    The full domain name for the environment

.PARAMETER DPMPName
    The Distribution Point/Management Point server name

.PARAMETER Role
    The role/site code for the CM installation

.PARAMETER ProvisionToolPath
    The path to the provisioning tools

.EXAMPLE
    .\Installdp.ps1 -DomainFullName "contoso.com" -DPMPName "dp01" -Role "P01" -ProvisionToolPath "C:\Tools"
    Installs SCCM Distribution Point on the specified server

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrator privileges and SCCM infrastructure
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainFullName,

    [Parameter(Mandatory = $true)]
    [string]$DPMPName,

    [Parameter(Mandatory = $true)]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [string]$ProvisionToolPath
)

$ErrorActionPreference = 'Stop'

$logpath = "$ProvisionToolPath\InstallDPlog.txt"
$ConfigurationFile = Join-Path -Path $ProvisionToolPath -ChildPath "$Role.json"

# Load and update configuration
$Configuration = Get-Content -Path $ConfigurationFile | ConvertFrom-Json
$Configuration.InstallDP.Status = 'Running'
$Configuration.InstallDP.StartTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Start running add distribution point script." | Out-File -Append $logpath

# Get SCCM installation paths
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)
$SubKey = $key.OpenSubKey("SOFTWARE\Microsoft\ConfigMgr10\Setup")
$UiInstallPath = $SubKey.GetValue("UI Installation Directory")
$ModulePath = "$UiInstallPath\bin\ConfigurationManager.psd1"

if ((Get-Module ConfigurationManager -ErrorAction SilentlyContinue) -eq $null) {
    Import-Module $ModulePath
}

# Get site code
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
$SubKey = $key.OpenSubKey("SOFTWARE\Microsoft\SMS\Identification")
$SiteCode = $SubKey.GetValue("Site Code")

$MachineName = "$DPMPName.$DomainFullName"
$InitParams = @{}
$ProviderMachineName = "$env:COMPUTERNAME.$DomainFullName"

"[$(Get-Date -format "HH:mm:ss")] Setting PS Drive..." | Out-File -Append $logpath
New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams

while ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    "[$(Get-Date -format "HH:mm:ss")] Retry in 10s to set PS Drive. Please wait." | Out-File -Append $logpath
    Start-Sleep -Seconds 10
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

Set-Location "$($SiteCode):\" @initParams

# Check if site system server exists
$SystemServer = Get-CMSiteSystemServer -SiteSystemServerName $MachineName

if (!$SystemServer) {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Creating CM site system server..." | Out-File -Append $logpath
    New-CMSiteSystemServer -SiteSystemServerName $MachineName | Out-File -Append $logpath
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Finished creating CM site system server." | Out-File -Append $logpath

    $SystemServer = Get-CMSiteSystemServer -SiteSystemServerName $MachineName
}

# Set certificate expiration date (30 years from now)
$Date = [DateTime]::Now.AddYears(30)

# Check if distribution point already exists
$DistributionPoint = Get-CMDistributionPoint -SiteSystemServerName $MachineName

if ($DistributionPoint.Count -ne 1) {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Adding distribution point on $MachineName..." | Out-File -Append $logpath
    Add-CMDistributionPoint -InputObject $SystemServer -CertificateExpirationTimeUtc $Date | Out-File -Append $logpath
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Finished adding distribution point on $MachineName..." | Out-File -Append $logpath

    # Verify distribution point was created successfully
    $DistributionPoint = Get-CMDistributionPoint -SiteSystemServerName $MachineName

    if ($DistributionPoint.Count -eq 1) {
        "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Finished running the script successfully." | Out-File -Append $logpath
        $Configuration.InstallDP.Status = 'Completed'
        $Configuration.InstallDP.EndTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
        $Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force
    }
    else {
        "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Failed to create distribution point." | Out-File -Append $logpath
        $Configuration.InstallDP.Status = 'Failed'
        $Configuration.InstallDP.EndTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
        $Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force
        throw "Failed to create distribution point on $MachineName"
    }
}
else {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] $MachineName is already a distribution point, skipping installation." | Out-File -Append $logpath
    $Configuration.InstallDP.Status = 'Completed'
    $Configuration.InstallDP.EndTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
    $Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force
}