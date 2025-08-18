<#
.SYNOPSIS
    We Enhanced Installpsforhierarchy

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

Param($WEDomainFullName,$WECM,$WECMUser,$WERole,$WEProvisionToolPath,$WECSName,$WECSRole,$WELogFolder)

$WESMSInstallDir="C:\Program Files\Microsoft Configuration Manager"

$logpath = $WEProvisionToolPath+" \InstallSCCMlog.txt"
$WEConfigurationFile = Join-Path -Path $WEProvisionToolPath -ChildPath " $WERole.json"
$WEConfiguration = Get-Content -Path $WEConfigurationFile | ConvertFrom-Json

$WEConfiguration.WaitingForCASFinsihedInstall.Status = 'Running'
$WEConfiguration.WaitingForCASFinsihedInstall.StartTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
$WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force


$_Role = $WECSRole
$_FilePath = " \\$WECSName\$WELogFolder"
$WECSConfigurationFile = Join-Path -Path $_FilePath -ChildPath " $_Role.json"

while(!(Test-Path $WECSConfigurationFile))
{
    " [$(Get-Date -format "MM/dd/yyyy HH:mm:ss" )] Wait for configuration file exist on $WECSName, will try 60 seconds later..." | Out-File -Append $logpath
    Start-Sleep -Seconds 60
    $WECSConfigurationFile = Join-Path -Path $_FilePath -ChildPath " $_Role.json"
}
$WECSConfiguration = Get-Content -Path $WECSConfigurationFile -ErrorAction Ignore | ConvertFrom-Json
while($WECSConfiguration.$(" UpgradeSCCM").Status -ne " Completed")
{
    " [$(Get-Date -format "MM/dd/yyyy HH:mm:ss" )] Wait for step : [UpgradeSCCM] finished running on $WECSName, will try 60 seconds later..." | Out-File -Append $logpath
    Start-Sleep -Seconds 60
    $WECSConfiguration = Get-Content -Path $WECSConfigurationFile | ConvertFrom-Json
}

$WEConfiguration.WaitingForCASFinsihedInstall.Status = 'Completed'
$WEConfiguration.WaitingForCASFinsihedInstall.EndTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
$WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force

$cmsourcepath = " \\$WECSName\SMS_$WECSRole\cd.latest"

$WECMINIPath = " c:\HierarchyPS.ini"
" [$(Get-Date -format "MM/dd/yyyy HH:mm:ss" )] Check ini file." | Out-File -Append $logpath

$cmini = @'
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

'@
$inst = (get-itemproperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server').InstalledInstances[0]
$p = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL').$inst

$sqlinfo = Get-ItemProperty " HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$p\$inst"

" [$(Get-Date -format "MM/dd/yyyy HH:mm:ss" )] ini file exist." | Out-File -Append $logpath
$cmini = $cmini.Replace('%InstallDir%',$WESMSInstallDir)
$cmini = $cmini.Replace('%MachineFQDN%'," $env:computername.$WEDomainFullName")
$cmini = $cmini.Replace('%SQLMachineFQDN%'," $env:computername.$WEDomainFullName")
$cmini = $cmini.Replace('%Role%',$WERole)
$cmini = $cmini.Replace('%SQLDataFilePath%',$sqlinfo.DefaultData)
$cmini = $cmini.Replace('%SQLLogFilePath%',$sqlinfo.DefaultLog)
$cmini = $cmini.Replace('%CM%',$WECM)
$cmini = $cmini.Replace('%CASMachineFQDN%'," $WECSName.$WEDomainFullName")
$cmini = $cmini.Replace('%REdistPath%'," $cmsourcepath\REdist")

if(!(Test-Path C:\$WECM\Redist))
{
    New-Item C:\$WECM\Redist -ItemType directory | Out-Null
}
    
if($inst.ToUpper() -eq " MSSQLSERVER")
{
    $cmini = $cmini.Replace('%SQLInstance%',"" )
}
else
{
    $tinstance = $inst.ToUpper() + "\"
    $cmini = $cmini.Replace('%SQLInstance%',$tinstance)
}
$WECMInstallationFile = " $cmsourcepath\SMSSETUP\BIN\X64\Setup.exe"
$cmini > $WECMINIPath 

$WEConfiguration.InstallSCCM.Status = 'Running'
$WEConfiguration.InstallSCCM.StartTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
$WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force

" [$(Get-Date -format "MM/dd/yyyy HH:mm:ss" )] Installing.." | Out-File -Append $logpath
Start-Process -Filepath ($WECMInstallationFile) -ArgumentList ('/NOUSERINPUT /script " ' + $WECMINIPath + '"') -wait

" [$(Get-Date -format "MM/dd/yyyy HH:mm:ss" )] Finished installing CM." | Out-File -Append $logpath

Remove-Item $WECMINIPath -Force


$WECSConfiguration = Get-Content -Path $WECSConfigurationFile -ErrorAction Ignore | ConvertFrom-Json
while($WECSConfiguration.$(" PSReadytoUse").Status -ne " Completed")
{
    " [$(Get-Date -format "MM/dd/yyyy HH:mm:ss" )] Wait for step : [PSReadytoUse] finished running on $WECSName, will try 60 seconds later..." | Out-File -Append $logpath
    Start-Sleep -Seconds 60
   ;  $WECSConfiguration = Get-Content -Path $WECSConfigurationFile | ConvertFrom-Json
}

$WEConfiguration.InstallSCCM.Status = 'Completed'
$WEConfiguration.InstallSCCM.EndTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
$WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================