#Requires -Version 7.4

<#
.SYNOPSIS
    Install and update SCCM (System Center Configuration Manager)

.DESCRIPTION
    Azure automation script that installs SCCM and applies available updates

.PARAMETER DomainFullName
    The full domain name for the environment

.PARAMETER CM
    The Configuration Manager installation file name

.PARAMETER CMUser
    The user to be granted CM administrative privileges

.PARAMETER Role
    The role/site code for the CM installation

.PARAMETER ProvisionToolPath
    The path to the provisioning tools

.EXAMPLE
    .\Installandupdatesccm.ps1 -DomainFullName "contoso.com" -CM "ConfigMgr.exe" -CMUser "domain\admin" -Role "P01" -ProvisionToolPath "C:\Tools"
    Installs and updates SCCM with the specified parameters

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrator privileges, SQL Server, and appropriate permissions
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
    [string]$ProvisionToolPath
)

$ErrorActionPreference = 'Stop'

$SMSInstallDir = "${env:ProgramFiles}\Microsoft Configuration Manager"
$logpath = "$ProvisionToolPath\InstallSCCMlog.txt"
$ConfigurationFile = Join-Path -Path $ProvisionToolPath -ChildPath "$Role.json"

# Load and update configuration
$Configuration = Get-Content -Path $ConfigurationFile | ConvertFrom-Json
$Configuration.InstallSCCM.Status = 'Running'
$Configuration.InstallSCCM.StartTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

$cmpath = "c:\$CM.exe"
$cmsourceextractpath = "c:\$CM"

if (!(Test-Path $cmpath)) {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Copying SCCM installation source..." | Out-File -Append $logpath
    $cmurl = "https://go.microsoft.com/fwlink/?linkid=2093192"
    Invoke-WebRequest -Uri $cmurl -OutFile $cmpath

    if (!(Test-Path $cmsourceextractpath)) {
        New-Item -ItemType Directory -Path $cmsourceextractpath
        Start-Process -WorkingDirectory ($cmsourceextractpath) -Filepath ($cmpath) -ArgumentList ('/s') -Wait
    }
}

$cmsourcepath = (Get-ChildItem -Path $cmsourceextractpath | Where-Object {$_.Name.ToLower().Contains("cd.")}).FullName
$CMINIPath = "$cmsourceextractpath\Standalone.ini"

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Check ini file." | Out-File -Append $logpath

$cmini = @'
[Identification]
Action=InstallPrimarySite

[Options]
ProductID=EVAL
SiteCode=%Role%
SiteName=%Role%
SMSInstallDir=%InstallDir%
SDKServer=%MachineFQDN%
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICertificate=0
PrerequisiteComp=0
PrerequisitePath=%cmsourcepath%\REdist
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
CloudConnector=1
CloudConnectorServer=%MachineFQDN%
UseProxy=0
ProxyName=
ProxyPort=

[SystemCenterOptions]
SysCenterId=

[HierarchyExpansionOption]
'@

# Get SQL Server information
$inst = (Get-ItemProperty -ErrorAction Stop 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances[0]
$p = (Get-ItemProperty -ErrorAction Stop 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$inst
$sqlinfo = Get-ItemProperty -ErrorAction Stop "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\$inst"

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] ini file exist." | Out-File -Append $logpath

# Replace placeholders in configuration
$cmini = $cmini.Replace('%InstallDir%', $SMSInstallDir)
$cmini = $cmini.Replace('%MachineFQDN%', "$env:computername.$DomainFullName")
$cmini = $cmini.Replace('%SQLMachineFQDN%', "$env:computername.$DomainFullName")
$cmini = $cmini.Replace('%Role%', $Role)
$cmini = $cmini.Replace('%SQLDataFilePath%', $sqlinfo.DefaultData)
$cmini = $cmini.Replace('%SQLLogFilePath%', $sqlinfo.DefaultLog)
$cmini = $cmini.Replace('%CM%', $CM)
$cmini = $cmini.Replace('%cmsourcepath%', $cmsourcepath)

if (!(Test-Path $cmsourcepath\Redist)) {
    New-Item -ErrorAction Stop $cmsourcepath\Redist -ItemType directory | Out-Null
}

if ($inst.ToUpper() -eq "MSSQLSERVER") {
    $cmini = $cmini.Replace('%SQLInstance%', "")
}
else {
    $tinstance = $inst.ToUpper() + "\"
    $cmini = $cmini.Replace('%SQLInstance%', $tinstance)
}

$CMInstallationFile = "$cmsourcepath\SMSSETUP\BIN\X64\Setup.exe"
$cmini | Out-File $CMINIPath

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Installing.." | Out-File -Append $logpath
Start-Process -Filepath ($CMInstallationFile) -ArgumentList ('/NOUSERINPUT /script "' + $CMINIPath + '"') -Wait

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Finished installing CM." | Out-File -Append $logpath
Remove-Item -ErrorAction Stop $CMINIPath -Force

$Configuration.InstallSCCM.Status = 'Completed'
$Configuration.InstallSCCM.EndTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

# Begin upgrade process
$Configuration.UpgradeSCCM.Status = 'Running'
$Configuration.UpgradeSCCM.StartTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

Start-Sleep -Seconds 120
$logpath = "$ProvisionToolPath\UpgradeCMlog.txt"

$SiteCode = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Identification' -Name 'Site Code'
$ProviderMachineName = $env:COMPUTERNAME + "." + $DomainFullName

$initParams = @{}
if ($ENV:SMS_ADMIN_UI_PATH -eq $null) {
    $ENV:SMS_ADMIN_UI_PATH = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\i386"
}

if ((Get-Module -ErrorAction Stop ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
}

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Setting PS Drive..." | Out-File -Append $logpath
New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams

while ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Retry in 10s to set PS Drive. Please wait." | Out-File -Append $logpath
    Start-Sleep -Seconds 10
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

Set-Location -ErrorAction Stop "$($SiteCode):\" @initParams

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Setting $CMUser as CM administrative user." | Out-File -Append $logpath
New-CMAdministrativeUser -Name $CMUser -RoleName "Full Administrator" -SecurityScopeName "All", "All Systems", "All Users and User Groups"

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Done" | Out-File -Append $logpath

# Wait for DMP downloader to be ready
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
$subKey = $key.OpenSubKey("SOFTWARE\Microsoft\SMS\Components\SMS_Executive\Threads\SMS_DMP_DOWNLOADER")
$DMPState = $subKey.GetValue("Current State")

while ($DMPState -ne "Running") {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Current SMS_DMP_DOWNLOADER state is: $DMPState, will try again 30 seconds later..." | Out-File -Append $logpath
    Start-Sleep -Seconds 30
    $DMPState = $subKey.GetValue("Current State")
}

"[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Current SMS_DMP_DOWNLOADER state is: $DMPState" | Out-File -Append $logpath

function Get-Update {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Get CM update..." | Out-File -Append $logpath
    $CMPSSuppressFastNotUsedCheck = $true
    $updatepacklist = Get-CMSiteUpdate -Fast | Where-Object {$_.State -ne 196612}
    $getupdateretrycount = 0

    while ($updatepacklist.Count -eq 0) {
        if ($getupdateretrycount -eq 3) {
            break
        }
        "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Not found any updates, retry to invoke update check." | Out-File -Append $logpath
        $getupdateretrycount++
        "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Invoke CM Site update check..." | Out-File -Append $logpath
        Invoke-CMSiteUpdateCheck -ErrorAction Ignore
        Start-Sleep 120
        $updatepacklist = Get-CMSiteUpdate -ErrorAction Stop | Where-Object {$_.State -ne 196612}
    }

    if ($updatepacklist.Count -eq 0) {
        return ""
    }
    elseif ($updatepacklist.Count -eq 1) {
        return $updatepacklist
    }
    else {
        return ($updatepacklist | Sort-Object -Property fullversion)[-1]
    }
}

# State mappings for CM updates
$state = @{
    0 = 'UNKNOWN'; 2 = 'ENABLED'; 262145 = 'DOWNLOAD_IN_PROGRESS'; 262146 = 'DOWNLOAD_SUCCESS'
    327679 = 'DOWNLOAD_FAILED'; 327681 = 'APPLICABILITY_CHECKING'; 327682 = 'APPLICABILITY_SUCCESS'
    393213 = 'APPLICABILITY_HIDE'; 393214 = 'APPLICABILITY_NA'; 393215 = 'APPLICABILITY_FAILED'
    65537 = 'CONTENT_REPLICATING'; 65538 = 'CONTENT_REPLICATION_SUCCESS'; 131071 = 'CONTENT_REPLICATION_FAILED'
    131073 = 'PREREQ_IN_PROGRESS'; 131074 = 'PREREQ_SUCCESS'; 131075 = 'PREREQ_WARNING'
    196607 = 'PREREQ_ERROR'; 196609 = 'INSTALL_IN_PROGRESS'; 196610 = 'INSTALL_WAITING_SERVICE_WINDOW'
    196611 = 'INSTALL_WAITING_PARENT'; 196612 = 'INSTALL_SUCCESS'; 196613 = 'INSTALL_PENDING_REBOOT'
    262143 = 'INSTALL_FAILED'; 196614 = 'INSTALL_CMU_VALIDATING'; 196615 = 'INSTALL_CMU_STOPPED'
    196616 = 'INSTALL_CMU_INSTALLFILES'; 196617 = 'INSTALL_CMU_STARTED'; 196618 = 'INSTALL_CMU_SUCCESS'
    196619 = 'INSTALL_WAITING_CMU'; 262142 = 'INSTALL_CMU_FAILED'; 196620 = 'INSTALL_INSTALLFILES'
    196621 = 'INSTALL_UPGRADESITECTRLIMAGE'; 196622 = 'INSTALL_CONFIGURESERVICEBROKER'
    196623 = 'INSTALL_INSTALLSYSTEM'; 196624 = 'INSTALL_CONSOLE'; 196625 = 'INSTALL_INSTALLBASESERVICES'
    196626 = 'INSTALL_UPDATE_SITES'; 196627 = 'INSTALL_SSB_ACTIVATION_ON'; 196628 = 'INSTALL_UPGRADEDATABASE'
    196629 = 'INSTALL_UPDATEADMINCONSOLE'
}

$sites = Get-CMSite -ErrorAction Stop
$originalbuildnumber = if ($sites.count -eq 1) { $sites.BuildNumber } else { $sites[0].BuildNumber }

$upgradingfailed = $false
$retrytimes = 0
$downloadretrycount = 0
$updatepack = Get-Update

if ($updatepack -ne "") {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Update package is $($updatepack.Name)" | Out-File -Append $logpath
}
else {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] No update package be found." | Out-File -Append $logpath
}

# Process updates
while ($updatepack -ne "") {
    if ($retrytimes -eq 3) {
        $upgradingfailed = $true
        break
    }

    $updatepack = Get-CMSiteUpdate -Fast -Name $updatepack.Name

    # Handle download states
    while ($updatepack.State -eq 327682 -or $updatepack.State -eq 262145 -or $updatepack.State -eq 327679) {
        if ($updatepack.State -eq 327682) {
            Invoke-CMSiteUpdateDownload -Name $updatepack.Name -Force -WarningAction SilentlyContinue
            Start-Sleep 120
            $updatepack = Get-CMSiteUpdate -Name $updatepack.Name -Fast
            $downloadstarttime = Get-Date -ErrorAction Stop

            while ($updatepack.State -eq 327682) {
                "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Waiting SCCM Upgrade package start to download, sleep 2 min..." | Out-File -Append $logpath
                Start-Sleep 120
                $updatepack = Get-CMSiteUpdate -Name $updatepack.Name -Fast
                $downloadspan = New-TimeSpan -Start $downloadstarttime -End (Get-Date)

                if ($downloadspan.Hours -ge 1) {
                    Restart-Service -DisplayName "SMS_Executive"
                    $downloadretrycount++
                    Start-Sleep 120
                    $downloadstarttime = Get-Date -ErrorAction Stop
                }

                if ($downloadretrycount -ge 2) {
                    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Update package $($updatepack.Name) failed to start downloading in 2 hours." | Out-File -Append $logpath
                    break
                }
            }
        }

        if ($downloadretrycount -ge 2) { break }

        $downloadstarttime = Get-Date -ErrorAction Stop
        while ($updatepack.State -eq 262145) {
            "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Waiting SCCM Upgrade package download, sleep 2 min..." | Out-File -Append $logpath
            Start-Sleep 120
            $updatepack = Get-CMSiteUpdate -Name $updatepack.Name -Fast
            $downloadspan = New-TimeSpan -Start $downloadstarttime -End (Get-Date)

            if ($downloadspan.Hours -ge 1) {
                Restart-Service -DisplayName "SMS_Executive"
                Start-Sleep 120
                $downloadstarttime = Get-Date -ErrorAction Stop
            }
        }

        if ($updatepack.State -eq 327679) {
            $retrytimes++
            Start-Sleep 300
            continue
        }
    }

    if ($downloadretrycount -ge 2) { break }

    # Check prerequisites
    Invoke-CMSiteUpdatePrerequisiteCheck -Name $updatepack.Name
    while ($updatepack.State -ne 196607 -and $updatepack.State -ne 131074 -and $updatepack.State -ne 131075) {
        "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Waiting checking prerequisites complete, current pack $($updatepack.Name) state is $($state.($updatepack.State)), sleep 2 min..." | Out-File -Append $logpath
        Start-Sleep 120
        $updatepack = Get-CMSiteUpdate -Fast -Name $updatepack.Name
    }

    if ($updatepack.State -eq 196607) {
        $retrytimes++
        Start-Sleep 300
        continue
    }

    # Install update
    Install-CMSiteUpdate -Name $updatepack.Name -SkipPrerequisiteCheck -Force
    while ($updatepack.State -ne 196607 -and $updatepack.State -ne 262143 -and $updatepack.State -ne 196612) {
        "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Waiting SCCM Upgrade Complete, current pack $($updatepack.Name) state is $($state.($updatepack.State)), sleep 2 min..." | Out-File -Append $logpath
        Start-Sleep 120
        $updatepack = Get-CMSiteUpdate -Fast -Name $updatepack.Name
    }

    if ($updatepack.State -eq 196612) {
        "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] SCCM Upgrade Complete, current pack $($updatepack.Name) state is $($state.($updatepack.State))" | Out-File -Append $logpath
        $toplevelsite = Get-CMSite -ErrorAction Stop | Where-Object {$_.ReportingSiteCode -eq ""}

        if ((Get-CMSite).count -eq 1) {
            $path = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Setup' -Name 'Installation Directory'
            $fileversion = (Get-Item -ErrorAction Stop ($path + '\cd.latest\SMSSETUP\BIN\X64\setup.exe')).VersionInfo.FileVersion.split('.')[2]

            while ($fileversion -ne $toplevelsite.BuildNumber) {
                Start-Sleep 120
                $fileversion = (Get-Item -ErrorAction Stop ($path + '\cd.latest\SMSSETUP\BIN\X64\setup.exe')).VersionInfo.FileVersion.split('.')[2]
            }
            Start-Sleep 600
        }

        $updatepack = Get-Update
        if ($updatepack -ne "") {
            "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Found another update package: $($updatepack.Name)" | Out-File -Append $logpath
        }
    }

    if ($updatepack.State -eq 196607 -or $updatepack.State -eq 262143) {
        if ($retrytimes -le 3) {
            $retrytimes++
            Start-Sleep 300
            continue
        }
    }
}

# Handle completion status
if ($upgradingfailed -eq $true) {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Upgrade $($updatepack.Name) failed" | Out-File -Append $logpath

    if ($($updatepack.Name).ToLower().Contains("hotfix")) {
        "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] This is a hotfix, skip it and continue..." | Out-File -Append $logpath
        $Configuration.UpgradeSCCM.Status = 'CompletedWithHotfixInstallFailed'
    }
    else {
        $Configuration.UpgradeSCCM.Status = 'Error'
        $Configuration.UpgradeSCCM.EndTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
        $Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force
        throw
    }
}
else {
    $Configuration.UpgradeSCCM.Status = 'Completed'
}

if ($downloadretrycount -ge 2) {
    "[$(Get-Date -format "MM/dd/yyyy HH:mm:ss")] Upgrade $($updatepack.Name) failed to start downloading" | Out-File -Append $logpath
    $Configuration.UpgradeSCCM.Status = 'CompletedWithDownloadFailed'
    $Configuration.UpgradeSCCM.EndTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
    $Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force
    throw
}

$Configuration.UpgradeSCCM.EndTime = Get-Date -format "yyyy-MM-dd HH:mm:ss"
$Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force