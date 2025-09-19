#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Installdp

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
    We Enhanced Installdp

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Param($WEDomainFullName,$WEDPMPName,$WERole,$WEProvisionToolPath)

$logpath = $WEProvisionToolPath+"\InstallDPlog.txt"
$WEConfigurationFile = Join-Path -Path $WEProvisionToolPath -ChildPath " $WERole.json"
$WEConfiguration = Get-Content -Path $WEConfigurationFile | ConvertFrom-Json


$WEConfiguration.InstallDP.Status = 'Running'
$WEConfiguration.InstallDP.StartTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
$WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force

" [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Start running add distribution point script." | Out-File -Append $logpath
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
$WEMachineName = $WEDPMPName + " ." + $WEDomainFullName
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

$WESystemServer = Get-CMSiteSystemServer -SiteSystemServerName $WEMachineName
if(!$WESystemServer)
{
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Creating cm site system server..." | Out-File -Append $logpath
    New-CMSiteSystemServer -SiteSystemServerName $WEMachineName | Out-File -Append $logpath
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Finished creating cm site system server." | Out-File -Append $logpath
   ;  $WEDate = [DateTime]::Now.AddYears(30)
   ;  $WESystemServer = Get-CMSiteSystemServer -SiteSystemServerName $WEMachineName
}
if((get-cmdistributionpoint -SiteSystemServerName $WEMachineName).count -ne 1)
{
    #Install DP
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Adding distribution point on $WEMachineName ..." | Out-File -Append $logpath
    Add-CMDistributionPoint -InputObject $WESystemServer -CertificateExpirationTimeUtc $WEDate | Out-File -Append $logpath
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Finished adding distribution point on $WEMachineName ..." | Out-File -Append $logpath


    if((get-cmdistributionpoint -SiteSystemServerName $WEMachineName).count -eq 1)
    {
        " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Finished running the script." | Out-File -Append $logpath
        $WEConfiguration.InstallDP.Status = 'Completed'
        $WEConfiguration.InstallDP.EndTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
        $WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force
    }
    else
    {
        " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Failed to run the script." | Out-File -Append $logpath
        $WEConfiguration.InstallDP.Status = 'Failed'
        $WEConfiguration.InstallDP.EndTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
        $WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force
    }
}
else
{
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] $WEMachineName is already a distribution point , skip running this script." | Out-File -Append $logpath
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
