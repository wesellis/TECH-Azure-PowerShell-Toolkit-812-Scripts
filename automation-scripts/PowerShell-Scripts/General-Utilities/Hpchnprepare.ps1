<#
.SYNOPSIS
    Hpchnprepare

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

<#
.SYNOPSIS
    We Enhanced Hpchnprepare

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.Synopsis
    Prepare the HPC Pack head node.

.DESCRIPTION
    This script promotes the virtual machine created from HPC Image to a HPC head node.

.NOTES
    This cmdlet requires:
    1. The current computer is a virtual machine created from HPC Image.
    2. The current computer is domain joined.
    3. The current user is a domain user as well as local administrator.
    4. The current user is the sysadmin of the DB server instance

.EXAMPLE
    PS > HPCHNPrepare.ps1 -DBServerInstance ".\ComputeCluster"
    Prepare the HPC head node with local DB server instance " .\ComputeCluster"

.EXAMPLE
    PS > HPCHNPrepare.ps1 -DBServerInstance " MyRemoteDB\ComputeCluster" -RemoteDB
    Prepare the HPC head node with remote DB server instance " MyRemoteDB\ComputeCluster"

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    # Specifies the database server instance
    [Parameter(Mandatory=$true)]
    [String] $WEDBServerInstance, 
    
    # (Optional) specifies the database name for HPC Management DB. If not specified, the default value is " HPCManagement"
    [Parameter(Mandatory=$false)]
    [String] $WEManagementDB = " HPCManagement" ,

    # (Optional) specifies the database name for HPC Scheduler DB. If not specified, the default value is " HPCScheduler"
    [Parameter(Mandatory=$false)]
    [String] $WESchedulerDB = " HPCScheduler" ,

    # (Optional) specifies the database name for HPC Monitoring DB. If not specified, the default value is " HPCMonitoring"
    [Parameter(Mandatory=$false)]
    [String] $WEMonitoringDB = " HPCMonitoring" ,

    # (Optional) specifies the database name for HPC Reporting DB. If not specified, the default value is " HPCReporting"
    [Parameter(Mandatory=$false)]
    [String] $WEReportingDB = " HPCReporting" ,

    # (Optional) specifies the database name for HPC Diagnostics DB. If not specified, the default value is " HPCDiagnostics"
    [Parameter(Mandatory=$false)]
    [String] $WEDiagnosticsDB = " HPCDiagnostics" ,

    # (Optional) specifies this parameter if the database server is a remote server.
    [Parameter(Mandatory=$false)]
    [Switch] $WERemoteDB,

    # (Optional) specifies the path of the log file. If not specified, the default value is " $env:windir\Temp\HPCHeadNodePrepare.log"
    [Parameter(Mandatory=$false)]
    [String] $WELogFile = ""
)

Set-StrictMode -Version 3
$WEScript:LogFilePath = " $env:windir\Temp\HPCHeadNodePrepare.log"
if(-not [String]::IsNullOrEmpty($WELogFile))
{
    $WEScript:LogFilePath = $WELogFile
}

if(Test-Path -Path $WEScript:LogFilePath -PathType Leaf)
{
    Remove-Item -Path $WEScript:LogFilePath -Force
}

[CmdletBinding()]
function WE-WriteLog
{
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [String] $WEMessage,

        [Parameter(Mandatory=$false)]
        [ValidateSet(" Error" ," Warning" ," Verbose" )]
        [String] $WELogLevel = " Verbose"
    )
    
   ;  $timestr = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
   ;  $WENewMessage = " $timestr - $WEMessage"
    switch($WELogLevel)
    {
        " Error"     {Write-Error   $WENewMessage; break}
        " Warning"   {Write-Warning $WENewMessage; break}
        " Verbose"   {Write-Verbose $WENewMessage; break}
    }
       
    try
    {
        # Write to both the log file and the console
        $WENewMessage = " [$WELogLevel]$timestr - $WEMessage"
        Add-Content $WEScript:LogFilePath $WENewMessage -ErrorAction SilentlyContinue
        $WENewMessage | Write-Information }
    catch
    {
        #Ignore the error
    }
}

try
{
    # 0 for Standalone Workstation, 1 for Member Workstation, 2 for Standalone Server, 3 for Member Server, 4 for Backup Domain Controller, 5 for Primary Domain Controller
    $computeInfo = Get-CimInstance -ErrorAction Stop Win32_ComputerSystem
    $domainRole = $computeInfo.DomainRole
    if($domainRole -lt 3)
    {
        throw " $env:COMPUTERNAME is not domain joined"
    }

    WriteLog " Updating Cluster Name"
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC -Name ClusterName -Value $env:COMPUTERNAME
    Set-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\HPC -Name ClusterName -Value $env:COMPUTERNAME
    [Environment]::SetEnvironmentVariable(" CCP_SCHEDULER" , $env:COMPUTERNAME, [System.EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable(" CCP_SCHEDULER" , $env:COMPUTERNAME, [System.EnvironmentVariableTarget]::Process)
   ;  $WEHPCBinPath = [System.IO.Path]::Combine($env:CCP_HOME, " Bin" )

   ;  $WEDBDic = @{
        " HPCManagement"  = $WEManagementDB; 
        " HPCDiagnostics" = $WEDiagnosticsDB; 
        " HPCScheduler"   = $WESchedulerDB; 
        " HPCReporting"   = $WEReportingDB; 
        " HPCMonitoring"  = $WEMonitoringDB
    }

    WriteLog " Updating DB Connection Strings to Registry Table"
    foreach($db in $WEDBDic.Keys)
    {
        $regDbServerName = $db.Substring(3) + " DbServerName"
        Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC -Name $regDbServerName -Value $WEDBServerInstance
       ;  $regConnStrName = $db.Substring(3) + " DbConnectionString"
       ;  $regConnStrValue = " Data Source={0};Initial Catalog={1};Integrated Security=True;" -f $WEDBServerInstance, $WEDBDic[$db]
        Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\Security -Name $regConnStrName -Value $regConnStrValue
    }


    if($WERemoteDB.IsPresent)
    {
        $domainNetbiosName = $computeInfo.Domain.Split(" ." )[0].ToUpper()
        $machineAccount = " $domainNetbiosName\$env:COMPUTERNAME$"
        Import-Module " sqlps" -DisableNameChecking -Force
        foreach($db in $WEDBDic.Keys)
        {
            WriteLog (" Configuring Database " + $WEDBDic[$db])
            $dbNameVar = $db + " DBName"
            $sqlfilename = $db + " DB.sql"
            Get-Content -ErrorAction Stop " $WEHPCBinPath\$sqlfilename" | %{$_.Replace(" `$($dbNameVar)" , $WEDBDic[$db])} | Set-Content -ErrorAction Stop " $env:temp\$sqlfilename" -Force
            Invoke-Sqlcmd -ServerInstance $WEDBServerInstance -Database $WEDBDic[$db] -InputFile " $env:temp\$sqlfilename" -QueryTimeout 300 -ErrorAction SilentlyContinue
            Invoke-Sqlcmd -ServerInstance $WEDBServerInstance -Database $WEDBDic[$db] -InputFile " $WEHPCBinPath\AddDbUserForHpcService.sql" -Variable " TargetAccount=$machineAccount" -QueryTimeout 300
        }

        WriteLog " Inserting SDM Documents to HpcManagment database"
        $sdmDocs = @(
            " Microsoft.Ccp.ClusterModel.sdmDocument" , 
            " Microsoft.Ccp.TemplateModel.sdmDocument" , 
            " Microsoft.Ccp.NetworkModel.sdmDocument" , 
            " Microsoft.Ccp.WdsModel.sdmDocument" , 
            " Microsoft.Ccp.ComputerModel.sdmDocument" , 
            " Microsoft.Hpc.NetBootModel.sdmDocument"
        )

        $sdmLArgs = @()
        $sdmLArgs = $sdmLArgs + " -sql:`" `""
        foreach($doc in $sdmDocs)
        {
            $docFullPath = [System.IO.Path]::Combine($env:CCP_HOME, " Conf\$doc" )
            $sdmLArgs = $sdmLArgs + " `" $docFullPath`""
        }

        $p = Start-Process -FilePath " SdmL.exe" -ArgumentList $sdmLArgs -NoNewWindow -Wait -PassThru
        if($p.ExitCode -ne 0)
        {
            throw " Failed to insert SDM documents to HpcManagment database: $($p.ExitCode)"
        }
    }
    else
    {
        WriteLog " Starting SQL Server Services"
        $WESQLServices = @('MSSQL$WECOMPUTECLUSTER', 'SQLBrowser', 'SQLWriter')
        $WESQLServices | Set-Service -StartupType Automatic
        $WESQLServices | Start-Service
    }

    $WEHNServiceList = @(" HpcSdm" , " HpcManagement" , " HpcReporting" , " HpcMonitoringClient" , " HpcNodeManager" , " msmpi" , " HpcBroker" , `
        " HpcDiagnostics" , " HpcScheduler" , " HpcMonitoringServer" , " HpcSession" , " HpcSoaDiagMon" )

    foreach($svcname in $WEHNServiceList)
    {
        $service = Get-Service -Name $svcname -ErrorAction SilentlyContinue
        if($null -eq $service)
        {
            throw " The service $svcname doesn't exist"
        }
        else
        {
            WriteLog " Setting the startup type of the service $svcname to automatic"
            Set-Service -Name $svcname -StartupType Automatic

            # HpcBroker service will be started later
            if($svcname -ne " HpcBroker" )
            {
                $retry = 0
                while($retry -lt 100)
                {
                    WriteLog " Starting service $svcname"
                    Start-Service -Name $svcname
                    if(-not $?)
                    {
                        if($retry -lt 100)
                        {
                            $retry++
                            WriteLog " Failed to start service $svcname, will retry after 5 seconds"
                            start-sleep -Seconds 5
                        }
                        else
                        {
                           throw (" Failed to start service $svcname : " + $WEError[0])
                        }
                    }

                    break
                }
            }
        }
    }

    # Custom actions after Start-Serivce
    $retry = 0
    while($retry -lt 100)
    {
        WriteLog " Setting SpoolDir"
        $p = Start-Process -FilePath " cluscfg.exe" -ArgumentList " setparams SpoolDir=`" \\$env:COMPUTERNAME\CcpSpoolDir`"" -NoNewWindow -Wait -PassThru
        if($p.ExitCode -ne 0)
        {
            if($retry -lt 100)
            {
                   $retry++
                    WriteLog " Failed to set SpoolDir, will retry after 5 seconds"
                    start-sleep -Seconds 5
            }
            else
            {
                  throw " Failed to set SpoolDir: $($p.ExitCode)"
            }
        
       }
       break
    }
    

    $retry = 0
    while($retry -lt 100)
    {
        WriteLog " Setting CCP_SERVICEREGISTRATION_PATH"
        $p = Start-Process -FilePath " cluscfg.exe" -ArgumentList " setenvs CCP_SERVICEREGISTRATION_PATH=`" \\$env:COMPUTERNAME\HpcServiceRegistration`"" -NoNewWindow -Wait -PassThru
        if($p.ExitCode -ne 0)
        {
            if($retry -lt 100)
            {
                   $retry++
                    WriteLog " Failed to set CCP_SERVICEREGISTRATION_PATH, will retry after 5 seconds"
                    start-sleep -Seconds 5
            }
            else
            {
                  throw " Failed to set CCP_SERVICEREGISTRATION_PATH: $($p.ExitCode)"
            }
        
       }
       break
    }
    
    $retry = 0
    while($retry -lt 100)
    {
        WriteLog " Setting WDS listener Acls"
        $p = Start-Process -FilePath " sc.exe" -ArgumentList " control hpcmanagement 245" -NoNewWindow -Wait -PassThru
        if($p.ExitCode -ne 0)
        {
            if($retry -lt 100)
            {
                   $retry++
                    WriteLog " Failed to set Wds Listener Acls, will retry after 5 seconds"
                    start-sleep -Seconds 5
            }
            else
            {
                  throw " Failed to set Wds Listener Acls: $($p.ExitCode)"
            }
        
       }
       break
    }
    
    $retry = 0
    while($retry -lt 100)
    {
        WriteLog " Enabling port sharing service"
        $p = Start-Process -FilePath " sc.exe" -ArgumentList " control hpcmanagement 249" -NoNewWindow -Wait -PassThru
        if($p.ExitCode -ne 0)
        {
            if($retry -lt 100)
            {
                   $retry++
                    WriteLog " Failed to enable port sharing service, will retry after 5 seconds"
                    start-sleep -Seconds 5
            }
            else
            {
                  throw " Failed to enable port sharing service: $($p.ExitCode)"
            }
        
       }
       break
    }
    
    WriteLog " Starting service HpcBroker"
    Start-Service -Name " HpcBroker"

    WriteLog " importing diagnostics test cases"
    Start-Process -FilePath " test.exe" -ArgumentList " add `" $WEHPCBinPath\microsofttests.xml`"" -NoNewWindow -Wait
    Start-Process -FilePath " test.exe" -ArgumentList " add `" $WEHPCBinPath\exceltests.xml`"" -NoNewWindow -Wait

    WriteLog " Configuring monitoring service"
    Start-Process -FilePath " HpcMonUtil.exe" -ArgumentList " configure /v" -NoNewWindow -Wait

   ;  $retry = 0
    while($retry -lt 100)
    {
        WriteLog " Publishing HPC runtime data share"
       ;  $p = Start-Process -FilePath " cluscfg.exe" -ArgumentList " setenvs HPC_RUNTIMESHARE=`" \\$env:COMPUTERNAME\Runtime$`"" -NoNewWindow -Wait -PassThru
        if($p.ExitCode -ne 0)
        {
            if($retry -lt 100)
            {
                   $retry++
                    WriteLog " Failed to publish HPC runtime data share, will retry after 5 seconds"
                    start-sleep -Seconds 5
            }
            else
            {
                  throw " Failed to publish HPC runtime data share: $($p.ExitCode)"
            }
        
       }
       break
    }
    
    WriteLog " Reloading HpcSession Service"
    Start-Process -FilePath " sc.exe" -ArgumentList " control HpcSession 128" -NoNewWindow -Wait
    
    WriteLog " HPC head node is now ready for use"
}
catch
{
    WriteLog (" Failed to Prepare HPC head node: " + ($_ | Out-String)) -LogLevel Error
    throw
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================