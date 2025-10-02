#Requires -Version 7.4

<#
.SYNOPSIS
    Install PowerShell for SCCM Hierarchy

.DESCRIPTION
    Installs and configures System Center Configuration Manager (SCCM) Primary Site as part of a hierarchy.
    Waits for Central Administration Site (CAS) to complete installation before proceeding.

.PARAMETER DomainFullName
    Fully qualified domain name

.PARAMETER CM
    Configuration Manager site code

.PARAMETER CMUser
    Configuration Manager service account user

.PARAMETER Role
    Site role identifier

.PARAMETER ProvisionToolPath
    Path to provisioning tools and configuration files

.PARAMETER CSName
    Central Administration Site server name

.PARAMETER CSRole
    Central Administration Site role

.PARAMETER LogFolder
    Logging folder name

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions, SQL Server, and SCCM installation media
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainFullName,

    [Parameter(Mandatory = $true)]
    [string]$CM,

    [Parameter(Mandatory = $true)]
    [string]$CMUser,

    [Parameter(Mandatory = $true)]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [string]$ProvisionToolPath,

    [Parameter(Mandatory = $true)]
    [string]$CSName,

    [Parameter(Mandatory = $true)]
    [string]$CSRole,

    [Parameter(Mandatory = $true)]
    [string]$LogFolder
)

$ErrorActionPreference = 'Stop'

# Configuration
$SMSInstallDir = "${env:ProgramFiles}\Microsoft Configuration Manager"
$logPath = "$ProvisionToolPath\InstallSCCMlog.txt"
$ConfigurationFile = Join-Path -Path $ProvisionToolPath -ChildPath "$Role.json"

# Load and update configuration
$Configuration = Get-Content -Path $ConfigurationFile | ConvertFrom-Json
$Configuration.WaitingForCASFinsihedInstall.Status = 'Running'
$Configuration.WaitingForCASFinsihedInstall.StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

# Wait for CAS configuration file
$_Role = $CSRole
$_FilePath = "\\$CSName\$LogFolder"
$CSConfigurationFile = Join-Path -Path $_FilePath -ChildPath "$_Role.json"

while (!(Test-Path $CSConfigurationFile)) {
    "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Wait for configuration file exist on $CSName, will try 60 seconds later..." | Out-File -Append $logPath
    Start-Sleep -Seconds 60
    $CSConfigurationFile = Join-Path -Path $_FilePath -ChildPath "$_Role.json"
}

# Wait for CAS upgrade to complete
$CSConfiguration = Get-Content -Path $CSConfigurationFile -ErrorAction Ignore | ConvertFrom-Json
while ($CSConfiguration.UpgradeSCCM.Status -ne "Completed") {
    "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Wait for step : [UpgradeSCCM] finished running on $CSName, will try 60 seconds later..." | Out-File -Append $logPath
    Start-Sleep -Seconds 60
    $CSConfiguration = Get-Content -Path $CSConfigurationFile | ConvertFrom-Json
}

# Update configuration status
$Configuration.WaitingForCASFinsihedInstall.Status = 'Completed'
$Configuration.WaitingForCASFinsihedInstall.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

# Prepare installation paths
$cmsourcepath = "\\$CSName\SMS_$CSRole\cd.latest"
$CMINIPath = "C:\HierarchyPS.ini"

"[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Check ini file." | Out-File -Append $logPath

# Create SCCM installation configuration file
$cmini = @"
[Identification]
Action=InstallPrimarySite
CDLatest=1

[Options]
ProductID=EVAL
SiteCode=%Role%
SiteName=%Role%
SMSInstallDir=%InstallDir%
SDKServer=%MachineFQDN%
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICertificate=0
PrerequisiteComp=1
PrerequisitePath=%REdistPath%
MobileDeviceLanguage=0
AdminConsole=1
JoinCEIP=0

[SQLConfigOptions]
SQLServerName=%SQLMachineFQDN%
DatabaseName=%SQLInstance%CM_%Role%
SQLSSBPort=4022
SQLDataFilePath=%SQLDataFilePath%
SQLLogFilePath=%SQLLogFilePath%

[CloudConnectorOptions]
CloudConnector=0
CloudConnectorServer=
UseProxy=0
ProxyName=
ProxyPort=

[SystemCenterOptions]
SysCenterId=

[HierarchyExpansionOption]
CCARSiteServer=%CASMachineFQDN%
"@

# Get SQL Server information
try {
    $inst = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances[0]
    $p = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$inst
    $sqlinfo = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\$inst"
}
catch {
    throw "Failed to retrieve SQL Server information: $($_.Exception.Message)"
}

"[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] ini file exist." | Out-File -Append $logPath

# Replace placeholders in configuration
$cmini = $cmini.Replace('%InstallDir%', $SMSInstallDir)
$cmini = $cmini.Replace('%MachineFQDN%', "$env:computername.$DomainFullName")
$cmini = $cmini.Replace('%SQLMachineFQDN%', "$env:computername.$DomainFullName")
$cmini = $cmini.Replace('%Role%', $Role)
$cmini = $cmini.Replace('%SQLDataFilePath%', $sqlinfo.DefaultData)
$cmini = $cmini.Replace('%SQLLogFilePath%', $sqlinfo.DefaultLog)
$cmini = $cmini.Replace('%CM%', $CM)
$cmini = $cmini.Replace('%CASMachineFQDN%', "$CSName.$DomainFullName")
$cmini = $cmini.Replace('%REdistPath%', "$cmsourcepath\REdist")

# Create redistribution directory
if (!(Test-Path "C:\$CM\Redist")) {
    New-Item -Path "C:\$CM\Redist" -ItemType Directory | Out-Null
}

# Handle SQL instance name
if ($inst.ToUpper() -eq "MSSQLSERVER") {
    $cmini = $cmini.Replace('%SQLInstance%', "")
}
else {
    $tinstance = $inst.ToUpper() + "\"
    $cmini = $cmini.Replace('%SQLInstance%', $tinstance)
}

# Prepare installation
$CMInstallationFile = "$cmsourcepath\SMSSETUP\BIN\X64\Setup.exe"
$cmini | Out-File -FilePath $CMINIPath -Encoding UTF8

# Update configuration for installation
$Configuration.InstallSCCM.Status = 'Running'
$Configuration.InstallSCCM.StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

# Install SCCM
"[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Installing.." | Out-File -Append $logPath

if ($PSCmdlet.ShouldProcess("SCCM Primary Site", "Install")) {
    try {
        Start-Process -FilePath $CMInstallationFile -ArgumentList "/NOUSERINPUT /script `"$CMINIPath`"" -Wait -NoNewWindow
        "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Finished installing CM." | Out-File -Append $logPath
    }
    catch {
        "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Error installing CM: $($_.Exception.Message)" | Out-File -Append $logPath
        throw
    }
    finally {
        # Clean up configuration file
        if (Test-Path $CMINIPath) {
            Remove-Item -Path $CMINIPath -Force -ErrorAction SilentlyContinue
        }
    }
}

# Wait for Primary Site to be ready
$CSConfiguration = Get-Content -Path $CSConfigurationFile -ErrorAction Ignore | ConvertFrom-Json
while ($CSConfiguration.PSReadytoUse.Status -ne "Completed") {
    "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Wait for step : [PSReadytoUse] finished running on $CSName, will try 60 seconds later..." | Out-File -Append $logPath
    Start-Sleep -Seconds 60
    $CSConfiguration = Get-Content -Path $CSConfigurationFile | ConvertFrom-Json
}

# Final configuration update
$Configuration.InstallSCCM.Status = 'Completed'
$Configuration.InstallSCCM.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

Write-Output "SCCM Primary Site installation completed successfully"