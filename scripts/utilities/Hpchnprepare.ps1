#Requires -Version 7.4

<#
.SYNOPSIS
    HPC Head Node Prepare

.DESCRIPTION
    Prepare the HPC Pack head node.
    This script promotes the virtual machine created from HPC Image to a HPC head node.

    This cmdlet requires:
    1. The current computer is a virtual machine created from HPC Image.
    2. The current computer is domain joined.
    3. The current user is a domain user as well as local administrator.
    4. The current user is the sysadmin of the DB server instance

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER DBServerInstance
    Database server instance

.PARAMETER ManagementDB
    Management database name

.PARAMETER SchedulerDB
    Scheduler database name

.PARAMETER MonitoringDB
    Monitoring database name

.PARAMETER ReportingDB
    Reporting database name

.PARAMETER DiagnosticsDB
    Diagnostics database name

.PARAMETER RemoteDB
    Use remote database

.PARAMETER LogFile
    Log file path

.EXAMPLE
    .\Hpchnprepare.ps1 -DBServerInstance ".\ComputeCluster"
    Prepare the HPC head node with local DB server instance ".\ComputeCluster"

.EXAMPLE
    .\Hpchnprepare.ps1 -DBServerInstance "MyRemoteDB\ComputeCluster" -RemoteDB
    Prepare the HPC head node with remote DB server instance "MyRemoteDB\ComputeCluster"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String]$DBServerInstance,

    [Parameter()]
    [String]$ManagementDB = "HPCManagement",

    [Parameter()]
    [String]$SchedulerDB = "HPCScheduler",

    [Parameter()]
    [String]$MonitoringDB = "HPCMonitoring",

    [Parameter()]
    [String]$ReportingDB = "HPCReporting",

    [Parameter()]
    [String]$DiagnosticsDB = "HPCDiagnostics",

    [Parameter()]
    [Switch]$RemoteDB,

    [Parameter()]
    [String]$LogFile = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 3

$Script:LogFilePath = "$env:windir\Temp\HPCHeadNodePrepare.log"
if(-not [String]::IsNullOrEmpty($LogFile)) {
    $Script:LogFilePath = $LogFile
}

if(Test-Path -Path $Script:LogFilePath -PathType Leaf) {
    Remove-Item -Path $Script:LogFilePath -Force
}

function WriteLog {
    param(
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [String]$Message,

        [Parameter()]
        [ValidateSet("Error","Warning","Verbose")]
        [String]$LogLevel = "Verbose"
    )

    $timestr = Get-Date -Format 'MM/dd/yyyy HH:mm:ss'
    $NewMessage = "$timestr - $Message"

    switch($LogLevel) {
        "Error"     { Write-Error   $NewMessage; break }
        "Warning"   { Write-Warning $NewMessage; break }
        "Verbose"   { Write-Verbose $NewMessage; break }
    }

    try {
        $NewMessage = "[$LogLevel]$timestr - $Message"
        Add-Content $Script:LogFilePath $NewMessage -ErrorAction SilentlyContinue
        $NewMessage | Write-Information
    }
    catch {
        # Silently continue if logging fails
    }
}

try {
    $ComputeInfo = Get-CimInstance -ErrorAction Stop Win32_ComputerSystem
    $DomainRole = $ComputeInfo.DomainRole

    if($DomainRole -lt 3) {
        throw "$env:COMPUTERNAME is not domain joined"
    }

    WriteLog "Updating Cluster Name"
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC -Name ClusterName -Value $env:COMPUTERNAME
    Set-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\Microsoft\HPC -Name ClusterName -Value $env:COMPUTERNAME
    [Environment]::SetEnvironmentVariable("CCP_SCHEDULER", $env:COMPUTERNAME, [System.EnvironmentVariableTarget]::Machine)
    [Environment]::SetEnvironmentVariable("CCP_SCHEDULER", $env:COMPUTERNAME, [System.EnvironmentVariableTarget]::Process)

    $HPCBinPath = [System.IO.Path]::Combine($env:CCP_HOME, "Bin")
    $DBDic = @{
        "HPCManagement"  = $ManagementDB;
        "HPCDiagnostics" = $DiagnosticsDB;
        "HPCScheduler"   = $SchedulerDB;
        "HPCReporting"   = $ReportingDB;
        "HPCMonitoring"  = $MonitoringDB
    }

    WriteLog "Updating DB Connection Strings to Registry Table"
    foreach($db in $DBDic.Keys) {
        $RegDbServerName = $db.Substring(3) + "DbServerName"
        Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC -Name $RegDbServerName -Value $DBServerInstance
        $RegConnStrName = $db.Substring(3) + "DbConnectionString"
        $RegConnStrValue = "Data Source={0};Initial Catalog={1};Integrated Security=True;" -f $DBServerInstance, $DBDic[$db]
        Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\Security -Name $RegConnStrName -Value $RegConnStrValue
    }

    if($RemoteDB.IsPresent) {
        $DomainNetbiosName = $ComputeInfo.Domain.Split(".")[0].ToUpper()
        $MachineAccount = "$DomainNetbiosName\$env:COMPUTERNAME$"

        foreach($db in $DBDic.Keys) {
            WriteLog ("Configuring Database " + $DBDic[$db])
            $DbNameVar = $db + "DBName"
            $sqlfilename = $db + "DB.sql"
            Get-Content -ErrorAction Stop "$HPCBinPath\$sqlfilename" | %{$_.Replace("`$($DbNameVar)", $DBDic[$db])} | Set-Content -ErrorAction Stop "$env:temp\$sqlfilename" -Force
            Invoke-Sqlcmd -ServerInstance $DBServerInstance -Database $DBDic[$db] -InputFile "$env:temp\$sqlfilename" -QueryTimeout 300 -ErrorAction SilentlyContinue
            Invoke-Sqlcmd -ServerInstance $DBServerInstance -Database $DBDic[$db] -InputFile "$HPCBinPath\AddDbUserForHpcService.sql" -Variable "TargetAccount=$MachineAccount" -QueryTimeout 300
        }

        WriteLog "Inserting SDM Documents to HpcManagment database"
        $SdmDocs = @(
            "Microsoft.Ccp.ClusterModel.sdmDocument",
            "Microsoft.Ccp.TemplateModel.sdmDocument",
            "Microsoft.Ccp.NetworkModel.sdmDocument",
            "Microsoft.Ccp.WdsModel.sdmDocument",
            "Microsoft.Ccp.ComputerModel.sdmDocument",
            "Microsoft.Hpc.NetBootModel.sdmDocument"
        )

        $SdmLArgs = @()
        $SdmLArgs = $SdmLArgs + "-sql:`"`""
        foreach($doc in $SdmDocs) {
            $DocFullPath = [System.IO.Path]::Combine($env:CCP_HOME, "Conf\$doc")
            $SdmLArgs = $SdmLArgs + "`"$DocFullPath`""
        }

        $p = Start-Process -FilePath "SdmL.exe" -ArgumentList $SdmLArgs -NoNewWindow -Wait -PassThru
        if($p.ExitCode -ne 0) {
            throw "Failed to insert SDM documents to HpcManagment database: $($p.ExitCode)"
        }
    }
    else {
        WriteLog "Starting SQL Server Services"
        $SQLServices = @('MSSQL$COMPUTECLUSTER', 'SQLBrowser', 'SQLWriter')
        $SQLServices | Set-Service -StartupType Automatic
        $SQLServices | Start-Service
    }

    $HNServiceList = @("HpcManagement", "HpcNodeManager", "HpcScheduler", "HpcSession", "HpcMonitoringServer", "HpcReporting", "HpcBroker")

    foreach($svcname in $HNServiceList) {
        $service = Get-Service -Name $svcname -ErrorAction SilentlyContinue
        if($null -eq $service) {
            throw "The service $svcname doesn't exist"
        }
        else {
            WriteLog "Setting the startup type of the service $svcname to automatic"
            Set-Service -Name $svcname -StartupType Automatic

            if($svcname -ne "HpcBroker") {
                $retry = 0
                while($retry -lt 100) {
                    WriteLog "Starting service $svcname"
                    Start-Service -Name $svcname
                    if(-not $?) {
                        if($retry -lt 100) {
                            $retry++
                            WriteLog "Failed to start service $svcname, will retry after 5 seconds"
                            Start-Sleep -Seconds 5
                        }
                        else {
                            throw ("Failed to start service $svcname : " + $Error[0].Exception.Message)
                        }
                    }
                    else {
                        break
                    }
                }
            }
        }
    }

    WriteLog "Starting service HpcBroker"
    Start-Service -Name "HpcBroker"

    WriteLog "Importing diagnostics test cases"
    Start-Process -FilePath "test.exe" -ArgumentList "add `"$HPCBinPath\microsofttests.xml`"" -NoNewWindow -Wait
    Start-Process -FilePath "test.exe" -ArgumentList "add `"$HPCBinPath\exceltests.xml`"" -NoNewWindow -Wait

    WriteLog "Configuring monitoring service"
    Start-Process -FilePath "HpcMonUtil.exe" -ArgumentList "configure /v" -NoNewWindow -Wait

    WriteLog "HPC head node is now ready for use"
}
catch {
    WriteLog ("Failed to Prepare HPC head node: " + ($_ | Out-String)) -LogLevel Error
    throw
}