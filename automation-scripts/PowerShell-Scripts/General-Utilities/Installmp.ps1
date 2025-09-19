#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Installmp

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
    We Enhanced Installmp

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

$logpath = $WEProvisionToolPath+"\InstallMPlog.txt"
$WEConfigurationFile = Join-Path -Path $WEProvisionToolPath -ChildPath " $WERole.json"
$WEConfiguration = Get-Content -Path $WEConfigurationFile | ConvertFrom-Json


$WEConfiguration.InstallMP.Status = 'Running'
$WEConfiguration.InstallMP.StartTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
$WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force

" [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Start running add management point script." | Out-File -Append $logpath
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


$WEDatabaseValue='Database Name'
$WEDatabaseName=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\SQL Server' -Name 'Database Name').$WEDatabaseValue

$WEInstanceValue='Service Name'
$WEInstanceName=(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\SQL Server' -Name 'Service Name').$WEInstanceValue

$WESystemServer = Get-CMSiteSystemServer -SiteSystemServerName $WEMachineName
if(!$WESystemServer)
{
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Creating cm site system server..." | Out-File -Append $logpath
    New-CMSiteSystemServer -SiteSystemServerName $WEMachineName | Out-File -Append $logpath
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Finished creating cm site system server." | Out-File -Append $logpath
    $WEDate = [DateTime]::Now.AddYears(30)
   ;  $WESystemServer = Get-CMSiteSystemServer -SiteSystemServerName $WEMachineName
}

if((Get-CMManagementPoint -SiteSystemServerName $WEMachineName).count -ne 1)
{
    #Install MP
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Adding management point on $WEMachineName ..." | Out-File -Append $logpath
    Add-CMManagementPoint -InputObject $WESystemServer -CommunicationType Http | Out-File -Append $logpath
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Finished adding management point on $WEMachineName ..." | Out-File -Append $logpath
    
   ;  $connectionString = " Data Source=.; Integrated Security=SSPI; Initial Catalog=$WEDatabaseName"
    if($WEInstanceName.ToUpper() -ne 'MSSQLSERVER')
    {
        $connectionString = " Data Source=.\$WEInstanceName; Integrated Security=SSPI; Initial Catalog=$WEDatabaseName"
    }
    $connection = new-object -ErrorAction Stop system.data.SqlClient.SQLConnection($connectionString)
   ;  $sqlCommand = " INSERT INTO [Feature_EC] (FeatureID,Exposed) values (N'49E3EF35-718B-4D93-A427-E743228F4855',0)"
    $connection.Open() | Out-Null
   ;  $command = new-object -ErrorAction Stop system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $command.ExecuteNonQuery() | Out-Null

    if((Get-CMManagementPoint -SiteSystemServerName $WEMachineName).count -eq 1)
    {
        " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Finished running the script." | Out-File -Append $logpath
        $WEConfiguration.InstallMP.Status = 'Completed'
        $WEConfiguration.InstallMP.EndTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
        $WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force
    }
    else
    {
        " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] Failed to run the script." | Out-File -Append $logpath
        $WEConfiguration.InstallMP.Status = 'Failed'
        $WEConfiguration.InstallMP.EndTime = Get-Date -format " yyyy-MM-dd HH:mm:ss"
        $WEConfiguration | ConvertTo-Json | Out-File -FilePath $WEConfigurationFile -Force
    }
}
else
{
    " [$(Get-Date -format " MM/dd/yyyy HH:mm:ss" )] $WEMachineName is already a management point , skip running this script." | Out-File -Append $logpath
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
