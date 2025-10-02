#Requires -Version 7.4

<#
.SYNOPSIS
    Install SCCM Client

.DESCRIPTION
    Azure automation script that installs and configures SCCM client on target machines

.PARAMETER DomainFullName
    The full domain name for the environment

.PARAMETER CMUser
    The Configuration Manager user account

.PARAMETER ClientName
    Comma-separated list of client machine names to install SCCM client on

.PARAMETER DPMPName
    The Distribution Point/Management Point server name

.PARAMETER Role
    The role/site code for the CM installation

.PARAMETER ProvisionToolPath
    The path to the provisioning tools

.EXAMPLE
    .\Installclient.ps1 -DomainFullName "contoso.com" -CMUser "domain\admin" -ClientName "client1,client2" -DPMPName "dp01" -Role "P01" -ProvisionToolPath "C:\Tools"
    Installs SCCM client on specified machines

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
    [string]$CMUser,

    [Parameter(Mandatory = $true)]
    [string]$ClientName,

    [Parameter(Mandatory = $true)]
    [string]$DPMPName,

    [Parameter(Mandatory = $true)]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [string]$ProvisionToolPath
)

$ErrorActionPreference = 'Stop'

$logpath = "$ProvisionToolPath\InstallClientLog.txt"
$ConfigurationFile = Join-Path -Path $ProvisionToolPath -ChildPath "$Role.json"

# Load and update configuration
$Configuration = Get-Content -Path $ConfigurationFile | ConvertFrom-Json
$Configuration.InstallClient.Status = 'Running'
$Configuration.InstallClient.StartTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Start running install client script." | Out-File -Append $logpath

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

$DPMPMachineName = "$DPMPName.$DomainFullName"
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

# Verify management point
Get-CMManagementPoint -SiteSystemServerName $DPMPMachineName

"[$(Get-Date -format "HH:mm:ss")] Setting system discovery..." | Out-File -Append $logpath
$DomainName = $DomainFullName.split('.')[0]
$lastdomainname = $DomainFullName.Split('.')[-1]

while (((Get-CMDiscoveryMethod | Where-Object {$_.ItemName -eq "SMS_AD_SYSTEM_DISCOVERY_AGENT|SMS Site Server"}).Props | Where-Object {$_.PropertyName -eq "Settings"}).value1.ToLower() -ne "active") {
    Start-Sleep -Seconds 20
    Set-CMDiscoveryMethod -ActiveDirectorySystemDiscovery -SiteCode $SiteCode -Enabled $true -AddActiveDirectoryContainer "LDAP://DC=$DomainName,DC=$lastdomainname" -Recursive
}

"[$(Get-Date -format "HH:mm:ss")] Invoke system discovery..." | Out-File -Append $logpath
Invoke-CMSystemDiscovery

"[$(Get-Date -format "HH:mm:ss")] Create boundary group." | Out-File -Append $logpath
New-CMBoundaryGroup -Name $SiteCode -DefaultSiteCode $SiteCode -AddSiteSystemServerName $DPMPMachineName

$ClientNameList = $ClientName.split(',')

foreach ($client in $ClientNameList) {
    $ClientIP = (Test-Connection $client -Count 1 | Select-Object @{Name="Computername"; Expression={$_.Address}}, Ipv4Address).IpV4Address.IPAddressToString
    "[$(Get-Date -format "HH:mm:ss")] $client IP is $ClientIP." | Out-File -Append $logpath

    $boundaryrange = "$ClientIP-$ClientIP"
    "[$(Get-Date -format "HH:mm:ss")] Create boundary..." | Out-File -Append $logpath
    New-CMBoundary -Type IPRange -Name $client -Value $boundaryrange

    "[$(Get-Date -format "HH:mm:ss")] Add $client IP to Boundary Group..." | Out-File -Append $logpath
    Add-CMBoundaryToGroup -BoundaryName $client -BoundaryGroupName $SiteCode
}

$machinelist = (Get-CMDevice -CollectionName "All Systems").Name

foreach ($client in $ClientNameList) {
    while ($machinelist -notcontains $client) {
        Invoke-CMDeviceCollectionUpdate -Name "All Systems"
        "[$(Get-Date -format "HH:mm:ss")] Waiting for $client to appear in all systems collection." | Out-File -Append $logpath
        Start-Sleep -Seconds 20
        $machinelist = (Get-CMDevice -CollectionName "All Systems").Name
    }

    "[$(Get-Date -format "HH:mm:ss")] $client push Client..." | Out-File -Append $logpath
    Install-CMClient -DeviceName $client -SiteCode $SiteCode -AlwaysInstallClient $true
    "[$(Get-Date -format "HH:mm:ss")] $client push Client Done." | Out-File -Append $logpath
}

$Configuration.InstallClient.Status = 'Completed'
$Configuration.InstallClient.EndTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force