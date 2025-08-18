<#
.SYNOPSIS
    We Enhanced Preparehn

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

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true, ParameterSetName='NodePrepare')]
    [String] $WEDomainFQDN, 
        
    [Parameter(Mandatory=$true, ParameterSetName='NodePrepare')]
    [String] $WEAdminUserName,

    # The admin password is in base64 string
    [Parameter(Mandatory=$true, ParameterSetName='NodePrepare')]
    [String] $WEAdminBase64Password,

    [Parameter(Mandatory=$true, ParameterSetName='NodePrepare')]
    [String] $WEPublicDnsName,

    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [String] $WESubscriptionId,

    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [String] $WEVNet,

    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [String] $WESubnet,

    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [String] $WELocation,

    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [String] $WEResourceGroup="" ,

    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [String] $WEAzureStorageConnStr="" ,

    # The PostConfig script url and arguments in base64
    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [String] $WEPostConfigScript="" ,

    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [String] $WECNSize="" ,

    [Parameter(Mandatory=$false, ParameterSetName='NodePrepare')]
    [Switch] $WEUnsecureDNSUpdate,

    [Parameter(Mandatory=$true, ParameterSetName='NodeState')]
    [switch] $WENodeStateCheck
)

function WE-TraceInfo
{
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [String] $log = ""
    )

    " $(Get-Date -format 'MM/dd/yyyy HH:mm:ss') $log" | Out-File -Confirm:$false -FilePath $env:HPCInfoLogFile -Append -ErrorAction Continue
}


$domainRole = (Get-CimInstance Win32_ComputerSystem).DomainRole
if($domainRole -lt 3)
{
    throw " This machine is not domain joined, DomainRole=$domainRole"
}

Set-StrictMode -Version 3
$datetimestr = (Get-Date).ToString('yyyyMMddHHmmssfff')
if ($WEPsCmdlet.ParameterSetName -eq 'NodeState')
{
    Add-PSSnapin Microsoft.HPC

    $WEHPCInfoLogFile = " $env:windir\Temp\HpcNodeAutoBringOnline.log"
    [Environment]::SetEnvironmentVariable(" HPCInfoLogFile", $WEHPCInfoLogFile, [System.EnvironmentVariableTarget]::Process)
    $offlineNodes = @()
    $offlineNodes = $offlineNodes + Get-HpcNode -State Offline -ErrorAction SilentlyContinue
    if($offlineNodes.Count -gt 0)
    {
        TraceInfo 'Start to bring nodes online'
        $nodes = @(Set-HpcNodeState -State online -Node $offlineNodes -Confirm:$false)
        if($nodes.Count -gt 0)
        {
           ;  $formatString = '{0,16}{1,12}{2,15}{3,10}';
            TraceInfo ($formatString -f 'NetBiosName','NodeState','NodeHealth','Groups')
            TraceInfo ($formatString -f '-----------','---------','----------','------')
            foreach($node in $nodes)
            {
                TraceInfo ($formatString -f $node.NetBiosName,$node.NodeState,$node.NodeHealth,$node.Groups)
            }
        }
    }
}
else
{
    $WEHPCHNDeployRoot = [IO.Path]::Combine($env:CCP_Data, " LogFiles\HPCHNDeployment")
    $WEHPCInfoLogFile = " $WEHPCHNDeployRoot\ConfigHeadNode-$datetimestr.log"
    $configFlagFile = " $WEHPCHNDeployRoot\HPCPackHeadNodeConfigured.flag"
    $postScriptFlagFile = " $WEHPCHNDeployRoot\PostConfigScriptExecution.flag"

    if(-not (Test-Path -Path $WEHPCHNDeployRoot))
    {
        New-Item -Path $WEHPCHNDeployRoot -ItemType directory -Confirm:$false -Force
        $acl = Get-Acl $WEHPCHNDeployRoot
        $acl.SetAccessRuleProtection($true, $false)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(" SYSTEM"," FullControl", " ContainerInherit, ObjectInherit", " None", " Allow")
        $acl.AddAccessRule($rule)
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(" Administrators"," FullControl", " ContainerInherit, ObjectInherit", " None", " Allow")
        $acl.AddAccessRule($rule)
        $domainNetBios = $WEDomainFQDN.Split('.')[0].ToUpper()
        try
        {
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(" $domainNetBios\$WEAdminUserName"," FullControl", " ContainerInherit, ObjectInherit", " None", " Allow")
            $acl.AddAccessRule($rule)
        }
        catch
        {
            Write-Error " Failed to grant access permissions to user '$domainNetBios\$WEAdminUserName'"
        }

        Set-Acl -Path $WEHPCHNDeployRoot -AclObject $acl -Confirm:$false
    }

    [Environment]::SetEnvironmentVariable(" HPCHNDeployRoot", $WEHPCHNDeployRoot, [System.EnvironmentVariableTarget]::Process)
    [Environment]::SetEnvironmentVariable(" HPCInfoLogFile", $WEHPCInfoLogFile, [System.EnvironmentVariableTarget]::Process)

    TraceInfo " Configuring head node: -DomainFQDN $WEDomainFQDN -PublicDnsName $WEPublicDnsName -AdminUserName $WEAdminUserName -CNSize $WECNSize -UnsecureDNSUpdate:$WEUnsecureDNSUpdate -PostConfigScript $WEPostConfigScript"
    if(Test-Path -Path $configFlagFile)
    {
        TraceInfo 'This head node was already configured'
    }
    else
    {
        if(-not [string]::IsNullOrEmpty($WESubscriptionId))
        {
            New-Item -Path HKLM:\SOFTWARE\Microsoft\HPC -Name IaaSInfo -Force -Confirm:$false
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\IaaSInfo -Name SubscriptionId -Value $WESubscriptionId -Force -Confirm:$false
            $deployId = " 00000000" + [System.Guid]::NewGuid().ToString().Substring(8)
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\IaaSInfo -Name DeploymentId -Value $deployId -Force -Confirm:$false
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\IaaSInfo -Name VNet -Value $WEVNet -Force -Confirm:$false
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\IaaSInfo -Name Subnet -Value $WESubnet -Force -Confirm:$false
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\IaaSInfo -Name AffinityGroup -Value "" -Force -Confirm:$false
            Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\IaaSInfo -Name Location -Value $WELocation -Force -Confirm:$false
            if(-not [string]::IsNullOrEmpty($WEResourceGroup))
            {
                Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\HPC\IaaSInfo -Name ResourceGroup -Value $WEResourceGroup -Force -Confirm:$false
            }

            TraceInfo " The information needed for in-box management scripts succcessfully configured."
        }

        Import-Module ScheduledTasks
        $WEAdminPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($WEAdminBase64Password))
        $domainNetBios = $WEDomainFQDN.Split('.')[0].ToUpper()
        $domainUserCred = New-Object -TypeName System.Management.Automation.PSCredential `
                -ArgumentList @(" $domainNetBios\$WEAdminUserName", (ConvertTo-SecureString -String $WEAdminPassword -AsPlainText -Force))

         $job = Start-Job -ScriptBlock {
             [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($scriptPath, $domainUserCred, $WEAzureStorageConnStr, $WEPublicDnsName, $WECNSize)

             function WE-TraceInfo($log)
             {
                 " $(Get-Date -format 'MM/dd/yyyy HH:mm:ss') $log" | Out-File -Confirm:$false -FilePath $env:HPCInfoLogFile -Append -ErrorAction Continue
             }

             $WEHPCPrepareTaskName = 'HPCPrepare'
             $prepareTask = Get-ScheduledTask -TaskName $WEHPCPrepareTaskName -ErrorAction SilentlyContinue
             if($null -ne $prepareTask)
             {
                 TraceInfo 'This head node is on preparing'
             }
             else
             {
                 TraceInfo 'register HPC Head Node Preparation Task'
                 # prepare headnode
                 $dbArgs = '-DBServerInstance .\COMPUTECLUSTER'
                 $WEHNPreparePsFile = " $scriptPath\HPCHNPrepare.ps1"
                 $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument " -ExecutionPolicy Unrestricted -Command `"& '$WEHNPreparePsFile' $dbArgs`""
                 Register-ScheduledTask -TaskName $WEHPCPrepareTaskName -Action $action -User $domainUserCred.UserName -Password $domainUserCred.GetNetworkCredential().Password -RunLevel Highest
                 if(-not $?)
                 {
                     TraceInfo 'Failed to schedule HPC Head Node Preparation Task'
                     throw
                 }

                 TraceInfo 'HPC Head Node Preparation Task scheduled'
                 Start-ScheduledTask -TaskName $WEHPCPrepareTaskName
                 TraceInfo 'Running HPC Head Node Preparation Task'
             }

             Start-Sleep -Milliseconds 500
             $taskSucceeded = $false
             do
             {
                 $taskState = (Get-ScheduledTask -TaskName $WEHPCPrepareTaskName).State
                 if($taskState -eq 'Ready')
                 {
                     $taskInfo = Get-ScheduledTaskInfo -TaskName $WEHPCPrepareTaskName
                     if($taskInfo.LastRunTime -eq $null)
                     {
                         Start-ScheduledTask -TaskName $WEHPCPrepareTaskName
                     }
                     else
                     {
                         if($taskInfo.LastTaskResult -eq 0)
                         {
                             $taskSucceeded = $true
                             break
                         }
                         else
                         {
                             TraceInfo ('The scheduled task for HPC Head Node Preparation failed:' + $taskInfo.LastTaskResult)
                             break
                         }
                     }
                 }
                 elseif($taskState -ne 'Queued' -and $taskState -ne 'Running')
                 {
                     TraceInfo " The scheduled task for HPC Head Node Preparation entered into unexpected state: $taskState"
                     break
                 }

                 Start-Sleep -Seconds 2
             } while ($true)

             if($taskSucceeded)
             {
                 TraceInfo 'Checking the Head Node Services status ...'
                 $WEHNServiceList = @('HpcSdm', 'HpcManagement', 'HpcNodeManager', 'msmpi', 'HpcBroker', 'HpcScheduler', 'HpcSession')
                 foreach($svcname in $WEHNServiceList)
                 {
                     $service = Get-Service -Name $svcname -ErrorAction SilentlyContinue
                     if($service -eq $null)
                     {
                         TraceInfo " Service $svcname not found"
                         $taskSucceeded = $false
                     }
                     elseif($service.Status -eq 'Running')
                     {
                         TraceInfo " Service $svcname is running"
                     }
                     else
                     {
                         TraceInfo " Service $svcname is in $($service.Status) status"
                         $taskSucceeded = $false
                     }
                 }
             }

             Unregister-ScheduledTask -TaskName $WEHPCPrepareTaskName -Confirm:$false

             if($taskSucceeded)
             {
                 TraceInfo 'Succeeded to prepare HPC Head Node'
                 # HPC to do list
                 Add-PSSnapin Microsoft.HPC
                 # setting network topology to 5 (enterprise)
                 TraceInfo 'Setting HPC cluster network topologogy...'
                 $nics = @(Get-CimInstance win32_networkadapterconfiguration -filter " IPEnabled='true' AND DHCPEnabled='true'")
                 if ($nics.Count -ne 1)
                 {
                     throw " Cannot find a suitable network adapter for enterprise topology"
                 }
                 $startTime = Get-Date
                 while($true)
                 {
                     Set-HpcNetwork -Topology 'Enterprise' -Enterprise $nics.Description -EnterpriseFirewall $true -ErrorAction SilentlyContinue
                    ;  $topo = Get-HpcNetworkTopology -ErrorAction SilentlyContinue
                     if ([String]::IsNullOrWhiteSpace($topo))
                     {
                         TraceInfo " Failed to set Hpc network topology, maybe the head node is still on initialization, retry after 10 seconds"
                         Start-Sleep -Seconds 10
                     }
                     else
                     {
                         TraceInfo " Network topology is set to $topo"
                         break;
                     }
                 }

                 # Set installation credentials
                 Set-HpcClusterProperty -InstallCredential $domainUserCred
                 $hpccred = Get-HpcClusterProperty -InstallCredential
                 TraceInfo ('Installation Credentials set to ' + $hpccred.Value)

                 # set node naming series
                 $nodenaming = 'AzureVMCN-%0000%'
                 Set-HpcClusterProperty -NodeNamingSeries $nodenaming
                 TraceInfo " Node naming series set to $nodenaming"

                 # Create a default compute node template
                 New-HpcNodeTemplate -Name 'Default ComputeNode Template' -Description 'This is the default compute node template' -ErrorAction SilentlyContinue
                 TraceInfo " 'Default ComputeNode Template' created"

                 # Disable the ComputeNode role for head node.
                 Set-HpcNode -Name $env:COMPUTERNAME -Role BrokerNode
                 TraceInfo " Disabled ComputeNode role for head node"

                 #set azure stroage connection string
                 if(-not [string]::IsNullOrEmpty($WEAzureStorageConnStr))
                 {
                     Set-HpcClusterProperty -AzureStorageConnectionString $WEAzureStorageConnStr
                     TraceInfo " Azure storage connection string configured"
                 }

                 $hpcBinPath = [System.IO.Path]::Combine($env:CCP_HOME, 'Bin')
                 $restWebCert = Get-ChildItem -Path Cert:\LocalMachine\My | ?{($_.Subject -eq " CN=$WEPublicDnsName") -and $_.HasPrivateKey} | select -First(1)
                 if($null -eq $restWebCert)
                 {
                     TraceInfo " Generating a self-signed certificate(CN=$WEPublicDnsName) for the HPC web service ..."
                     $thumbprint = . $hpcBinPath\New-HpcCert.ps1 -MachineName $WEPublicDnsName -SelfSigned
                     TraceInfo " A self-signed certificate $thumbprint was created and installed"
                 }
                 else
                 {
                     TraceInfo " Use the existing certificate $thumbprint (CN=$WEPublicDnsName) for the HPC web service."
                     $thumbprint = $restWebCert.Thumbprint
                 }

                 TraceInfo 'Enabling HPC Pack web portal ...'
                 . $hpcBinPath\Set-HPCWebComponents.ps1 -Service Portal -enable -Certificate $thumbprint | Out-Null
                 TraceInfo 'HPC Pack web portal enabled.'

                 TraceInfo 'Starting HPC web service ...'
                 Set-Service -Name 'HpcWebService' -StartupType Automatic | Out-Null
                 Start-Service -Name 'HpcWebService' | Out-Null
                 TraceInfo 'HPC web service started.'

                 TraceInfo 'Enabling HPC Pack REST API ...'
                 . $hpcBinPath\Set-HPCWebComponents.ps1 -Service REST -enable -Certificate $thumbprint | Out-Null
                 TraceInfo 'HPC Pack REST API enabled.'

                 TraceInfo 'Restarting HPCScheduler service ...'
                 Restart-Service -Name 'HpcScheduler' -Force | Out-Null
                 TraceInfo 'HPCScheduler service restarted.'

                 # If the VMSize of the compute nodes is A8/A9, set the MPI net mask.
                 if($WECNSize -match " (A8|A9)$")
                 {
                     $mpiNetMask = " 172.16.0.0/255.255.0.0"
                     ## Wait for the completion of the " Updating cluster configuration" operation after setting network topology,
                     ## because in the operation, the CCP_MPI_NETMASK may be reset.
                     $waitLoop = 0
                     while ($null -eq (Get-HpcOperation -StartTime $startTime -State Committed | ?{$_.Name -eq " Updating cluster configuration"}))
                     {
                         if($waitLoop++ -ge 10)
                         {
                             break
                         }

                         Start-Sleep -Seconds 10
                     }

                     Set-HpcClusterProperty -Environment " CCP_MPI_NETMASK=$mpiNetMask"  | Out-Null
                     TraceInfo " Set cluster environment CCP_MPI_NETMASK to $mpiNetMask"
                 }

                 # register scheduler task to bring node online
                 $task = Get-ScheduledTask -TaskName 'HpcNodeOnlineCheck' -ErrorAction SilentlyContinue
                 if($null -eq $task)
                 {
                     TraceInfo 'Start to register HpcNodeOnlineCheck Task'
                     $WEHpcNodeOnlineCheckFile = " $scriptPath\PrepareHN.ps1"
                     $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument " -ExecutionPolicy Unrestricted -Command `"& '$WEHpcNodeOnlineCheckFile' -NodeStateCheck`""
                     $trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 1) -At (get-date) -RepetitionDuration (New-TimeSpan -Minutes 90) -Once
                     Register-ScheduledTask -TaskName 'HpcNodeOnlineCheck' -Action $action -Trigger $trigger -User $domainUserCred.UserName -Password $domainUserCred.GetNetworkCredential().Password -RunLevel Highest | Out-Null
                     TraceInfo 'Finish to register task HpcNodeOnlineCheck'
                     if(-not $?)
                     {
                         TraceInfo 'Failed to schedule HpcNodeOnlineCheck Task'
                     }
                 }
                 else
                 {
                     TraceInfo 'Task HpcNodeOnlineCheck already exists'
                 }
             }
             else
             {
                 TraceInfo 'Failed to prepare HPC Head Node'
                 throw " Failed to prepare HPC Head Node"
             }
        } -ArgumentList $WEPSScriptRoot,$domainUserCred, $WEAzureStorageConnStr, $WEPublicDnsName, $WECNSize

         if($domainRole -eq 5)
         {
             if($null -ne (Get-DnsServerForwarder).IPAddress)
             {
                 foreach($fwdIP in @((Get-DnsServerForwarder).IPAddress))
                 {
                     if(($fwdIP -eq " fec0:0:0:ffff::1") -or ($fwdIP -eq " fec0:0:0:ffff::2") -or ($fwdIP -eq " fec0:0:0:ffff::3"))
                     {
                         TraceInfo " Removing DNS forwarder from the domain controller: $fwdIP"
                         Remove-DnsServerForwarder -IPAddress $fwdIP -Force
                     }
                 }
             }

             if($WEUnsecureDNSUpdate.IsPresent)
             {
                 TraceInfo " Waiting for default zone directory partitions ready"
                 $retry = 0
                 while ($true)
                 {
                     try
                     {
                         $ddzState = (Get-DnsServerDirectoryPartition -Name " DomainDnsZones.$WEDomainFQDN").State
                         $fdzState = (Get-DnsServerDirectoryPartition -Name " ForestDnsZones.$WEDomainFQDN").State
                         if (0 -eq $ddzState -and 0 -eq $fdzState)
                         {
                             TraceInfo " Default zone directory partitions ready"
                             break
                         }

                         TraceInfo " Default zone directory partitions are not ready. DomainDnsZones: $ddzState ForestDnsZones: $fdzState"
                     }
                     catch
                     {
                         TraceInfo " Exception while getting zone directory partitions state: $($_ | Out-String)"
                     }
                     if ($retry++ -lt 60)
                     {
                         TraceInfo " Retry after 10 seconds"
                         Start-Sleep -Seconds 10
                     }
                     else
                     {
                         throw " Default zone directory partitions not ready after 20 retries"
                     }
                 }

                 try
                 {
                     Set-DnsServerPrimaryZone -Name $WEDomainFQDN -DynamicUpdate NonsecureAndSecure -Confirm:$false -ErrorAction Stop
                     TraceInfo " Updated DNS DynamicUpdate to NonsecureAndSecure"
                 }
                 catch
                 {
                     TraceInfo " Failed to update DNS DynamicUpdate to NonsecureAndSecure: $_"
                 }
             }
         }

         Wait-Job $job
         if($job.State -eq " Completed")
         {
            " done" | Out-File $configFlagFile -Confirm:$false -Force
         }
         else
         {
            TraceInfo " PrepareHeadNode Job State: $($job.ChildJobs[0].JobStateInfo | fl | Out-String)"
            if($job.ChildJobs[0].Error.Count -ne 0)
            {
                $job.ChildJobs[0].Error | %{TraceInfo ($_ | Out-String)}
            }

            if ($null -ne $job.ChildJobs[0].JobStateInfo.Reason)
            {
                TraceInfo $job.ChildJobs[0].JobStateInfo.Reason
                if($null -ne $job.ChildJobs[0].JobStateInfo.Reason.SerializedRemoteInvocationInfo)
                {
                    TraceInfo ($job.ChildJobs[0].JobStateInfo.Reason.SerializedRemoteInvocationInfo | Out-String)
                }
            }
         
         }
    }

    if([String]::IsNullOrWhiteSpace($WEPostConfigScript))
    {
        TraceInfo " No Post configuration script is specified."
    }
    else
    {
        $WEPostConfigScript = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($WEPostConfigScript.Trim()))
        $WEPostConfigScript = $WEPostConfigScript.Trim()
        if((Test-Path $postScriptFlagFile) -and ($WEPostConfigScript -eq (Get-Content $postScriptFlagFile | select -First 1)))
        {
            TraceInfo " The Post configuration script was already executed"
        }
        else
        {
            $firstSpace = $WEPostConfigScript.IndexOf(' ')
            if($firstSpace -gt 0)
            {
                $scriptUrl = $WEPostConfigScript.Substring(0, $firstSpace)
                $scriptArgs = $WEPostConfigScript.Substring($firstSpace + 1).Trim()
            }
            else
            {
                $scriptUrl = $WEPostConfigScript
                $scriptArgs = ""
            }

            if(-not [system.uri]::IsWellFormedUriString($scriptUrl,[System.UriKind]::Absolute) -or $scriptUrl -notmatch '[^/]/[^/]+\.ps1$')
            {
                TraceInfo " Invalid url or not PowerShell script: $scriptUrl"
                throw " Invalid url or not PowerShell script: $scriptUrl"
            }
            else
            {
                $scriptFileName = $($scriptUrl -split '/')[-1]
                $scriptFilePath = " $env:HPCHNDeployRoot\$scriptFileName"

                $downloader = New-Object System.Net.WebClient
                $downloadRetry = 0
                $downloaded = $false
                while($true)
                {
                    try
                    {
                        TraceInfo " Downloading custom script file from $scriptUrl to $scriptFilePath(Retry=$downloadRetry)."
                        $downloader.DownloadFile($scriptUrl, $scriptFilePath)
                        TraceInfo " Downloaded custom script file from $scriptUrl to $scriptFilePath."
                        $downloaded = $true
                        break
                    }
                    catch
                    {
                        if($downloadRetry -lt 10)
                        {
                            TraceInfo (" Failed to download $scriptUrl, retry after 20 seconds:" + $_)
                            Clear-DnsClientCache
                            Start-Sleep -Seconds 20
                            $downloadRetry++
                        }
                        else
                        {
                            throw " Failed to download from $scriptUrl after 10 retries"
                        }
                    }
                }

                # Sometimes the new process failed to run due to system not ready, we try to create a test file to check whether the process works
                $testFileName = " $env:HPCHNDeployRoot\HPCPostConfigScriptTest."  + (Get-Random)
                if(-not $scriptArgs.Contains(' *> '))
                {
                    $logFilePath = [IO.Path]::ChangeExtension($scriptFilePath, $null) + (Get-Date -Format " yyyy_MM_dd-hh_mm_ss") + " .log"
                    $scriptArgs = $scriptArgs + " *> `" $logFilePath`""
                }
               ;  $scriptCmd = " 'test' | Out-File '$testFileName' -Confirm:`$false -Force;& '$scriptFilePath' $scriptArgs"
                $encodedCmd = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptCmd))
                $scriptRetry = 0
                while($downloaded)
                {
                   ;  $pobj = Invoke-WmiMethod -Path win32_process -Name Create -ArgumentList " PowerShell.exe -NoProfile -NonInteractive -ExecutionPolicy Unrestricted -EncodedCommand $encodedCmd"
                    if($pobj.ReturnValue -eq 0)
                    {
                        Start-Sleep -Seconds 5
                        if(Test-Path -Path $testFileName)
                        {
                            # Remove the test file
                            Remove-Item -Path $testFileName -Force -ErrorAction Continue
                            TraceInfo " Started to run: $scriptFilePath $scriptArgs."
                            $WEPostConfigScript | Out-File $postScriptFlagFile -Confirm:$false -Force
                            break
                        }
                        else
                        {
                            TraceInfo " The new process failed to run, stop it."
                            Stop-Process -Id $pobj.ProcessId
                        }
                    }
                    else
                    {
                        TraceInfo " Failed to start process: $scriptFilePath $scriptArgs."
                    }

                    if($scriptRetry -lt 10)
                    {
                        $scriptRetry++
                        Start-Sleep -Seconds 10
                    }
                    else
                    {
                        throw " Failed to run post configuration script: $scriptFilePath $scriptArgs."
                    }
                }
            }
        }
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================