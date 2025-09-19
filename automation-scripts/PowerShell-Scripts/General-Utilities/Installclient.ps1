#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Installclient

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Installclient

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Param($WEDomainFullName,$WECMUser,$WEClientName,$WEDPMPName,$WERole,$WEProvisionToolPath)

$logpath = $WEProvisionToolPath+"\InstallClientLog.txt"
$WEConfigurationFile = Join-Path -Path $WEProvisionToolPath -ChildPath " $WERole.json"
$WEConfiguration = Get-Content -Path $WEConfigurationFile | ConvertFrom-Json


$WEConfiguration.InstallClient.Status = 'Running'
$WEConfiguration.InstallClient.StartTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
$WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force

" [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Start running install client script." | Out-File -Append $logpath
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)
$subKey =  $key.OpenSubKey(" SOFTWARE\Microsoft\ConfigMgr10\Setup" )
$uiInstallPath = $subKey.GetValue(" UI Installation Directory" )
$modulePath = $uiInstallPath+" bin\ConfigurationManager.psd1"

if((Get-Module -ErrorAction Stop ConfigurationManager) -eq $null) {
    Import-Module $modulePath
}
$key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
$subKey =  $key.OpenSubKey(" SOFTWARE\Microsoft\SMS\Identification" )
$WESiteCode =  $subKey.GetValue(" Site Code" )
$WEDPMPMachineName = $WEDPMPName +" ." + $WEDomainFullName
$initParams = @{}

$WEProviderMachineName = $env:COMPUTERNAME+" ." +$WEDomainFullName # SMS Provider machine name

" [$(Get-Date -format HH:mm:ss)] Setting PS Drive..." | Out-File -Append $logpath
New-PSDrive -Name $WESiteCode -PSProvider CMSite -Root $WEProviderMachineName @initParams

while((Get-PSDrive -Name $WESiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) 
{
    " [$(Get-Date -format HH:mm:ss)] Retry in 10s to set PS Drive. Please wait." | Out-File -Append $logpath
    Start-Sleep -Seconds 10
    New-PSDrive -Name $WESiteCode -PSProvider CMSite -Root $WEProviderMachineName @initParams
}

Set-Location -ErrorAction Stop " $($WESiteCode):\" @initParams

Get-CMManagementPoint -SiteSystemServerName $WEDPMPMachineName

" [$(Get-Date -format HH:mm:ss)] Setting system descovery..." | Out-File -Append $logpath
$WEDomainName = $WEDomainFullName.split('.')[0]
$lastdomainname = $WEDomainFullName.Split(" ." )[-1]
while(((Get-CMDiscoveryMethod -ErrorAction Stop | ?{$_.ItemName -eq " SMS_AD_SYSTEM_DISCOVERY_AGENT|SMS Site Server" }).Props | ?{$_.PropertyName -eq " Settings" }).value1.ToLower() -ne " active" )
{
    start-sleep -Seconds 20
    Set-CMDiscoveryMethod -ActiveDirectorySystemDiscovery -SiteCode $WESiteCode -Enabled $true -AddActiveDirectoryContainer " LDAP://DC=$WEDomainName,DC=$lastdomainname" -Recursive
}
" [$(Get-Date -format HH:mm:ss)] Invoke system descovery..." | Out-File -Append $logpath
Invoke-CMSystemDiscovery 


" [$(Get-Date -format HH:mm:ss)] Create boundary group." | Out-File -Append $logpath
New-CMBoundaryGroup -Name $WESiteCode -DefaultSiteCode $WESiteCode -AddSiteSystemServerName $WEDPMPMachineName

; 
$WEClientNameList = $WEClientName.split(" ," )
foreach($client in $WEClientNameList)
{
   ;  $clientIP= (Test-Connection $client -count 1 | select @{Name=" Computername" ;Expression={$_.Address}},Ipv4Address).IpV4Address.IPAddressToString

    " [$(Get-Date -format HH:mm:ss)] $client IP is $clientIP." | Out-File -Append $logpath
    $boundaryrange = $clientIP+" -" +$clientIP
    
    " [$(Get-Date -format HH:mm:ss)] Create boundary..." | Out-File -Append $logpath
    New-CMBoundary -Type IPRange -Name $client -Value $boundaryrange

    " [$(Get-Date -format HH:mm:ss)] Add $client IP to Boundry Group..." | Out-File -Append $logpath
    Add-CMBoundaryToGroup -BoundaryName $client -BoundaryGroupName $WESiteCode
}

; 
$machinelist = (get-cmdevice -CollectionName " all systems" ).Name

foreach($client in $WEClientNameList)
{
    while($machinelist -notcontains $client)
    {
        Invoke-CMDeviceCollectionUpdate -Name " all systems"
        " [$(Get-Date -format HH:mm:ss)] Waiting for " + $client + " appear in all systems collection." | Out-File -Append $logpath
        Start-Sleep -Seconds 20
       ;  $machinelist = (get-cmdevice -CollectionName " all systems" ).Name
    }
    " [$(Get-Date -format HH:mm:ss)] " + $client + " push Client..." | Out-File -Append $logpath
    Install-CMClient -DeviceName $client -SiteCode $WESiteCode -AlwaysInstallClient $true
    " [$(Get-Date -format HH:mm:ss)] " + $client + " push Client Done." | Out-File -Append $logpath
}

$WEConfiguration.InstallClient.Status = 'Completed'
$WEConfiguration.InstallClient.EndTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
$WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
