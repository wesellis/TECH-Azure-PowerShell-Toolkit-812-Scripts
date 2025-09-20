#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Omsasrmonitoring

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
   Runbook for OMS ASR Log Ingestion
   This Runbook will ingest ASR related logs to OMS Log Analytics. Preview 0.9 will have limited support for VMware/Physical 2 Azure scenario.
    Kristian Nese (Kristian.Nese@Microsoft.com) ECG OMS CAT
"Logging in to Azure..."
$Conn = Get-AutomationConnection -Name AzureRunAsConnection
 Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
"Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID -TenantId $Conn.tenantid
$OMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId'
$OMSWorkspaceKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'
$AzureSubscriptionId = Get-AutomationVariable -Name 'AzureSubscriptionId'
$Vaults -ResourceType "Microsoft.RecoveryServices/vaults"
Write-Output "Found the following vaults:" $Vaults.name
foreach ($Vault in $Vaults)
{
    # Setting Vault context
    $params = @{
        ErrorAction = "Stop"
        ResourceGroupName = $Vault.ResourceGroupName Write-Output $VaultSettings
        Name = $Vault.Name
    }
    $VaultSettings @params
    $Location = $Vault.Location
    Set-AzureRmSiteRecoveryVaultSettings -ARSVault $VaultSettings # Ingesting ASRJobs into OMS -ErrorAction "Stop"
    $ASRLogs = @()
    $LogData = New-Object -ErrorAction Stop psobject -Property @{}
    $ASRJobs -StartTime "(Get-Date).AddHours(((-1)))" -ErrorAction "Stop"
    if ($null -eq $ASRJobs)
    {
        Write-output "No new logs to collect"
    }
    else
    {
        if ($ASRJobs.EndTime -eq $null)
        {
            foreach ($job in $ASRJobs)
            {
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name LogType -Value ASRJob
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name JobType -Value $job.JobType
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name State -Value $job.State
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name StateDescription -Value $job.StateDescription
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name StartTime -Value $job.StartTime.ToUniversalTime().ToString('yyyy-MM-ddtHH:mm:ss')
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name TargetObjectType -Value $job.TargetObjectType
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name TargetObjectName -Value $job.TargetObjectName
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name ID -Value $job.ID
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name SubscriptionId -Value $azuresubscriptionid
            }
        }
        else
        {
            foreach ($job in $ASRJobs)
            {
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name LogType -Value ASRJob
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name JobType -Value $job.JobType
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name State -Value $job.State
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name StateDescription -Value $job.StateDescription
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name StartTime -Value $job.StartTime.ToUniversalTime().ToString('yyyy-MM-ddtHH:mm:ss')
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name EndTime -Value $job.EndTime.ToUniversalTime().ToString('yyyy-mm-ddtHH:mm:ss')
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name TargetObjectType -Value $job.TargetObjectType
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name TargetObjectName -Value $job.TargetObjectName
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name ID -Value $job.ID
                Add-Member -InputObject $LogData -MemberType NoteProperty -Name SubscriptionId -Value $azuresubscriptionid
            }
        }
    $ASRLogs = $ASRLogs + $LogData
    Write-output $ASRLogs
    $ASRLogsJson = ConvertTo-Json -InputObject $ASRLogs
    $LogType = "RecoveryServices"
    Send-OMSAPIIngestionData -customerId $omsworkspaceId -sharedKey $omsworkspaceKey -body $ASRLogsJson -logType $LogType
    }
    # Get all Protection Containers for the Recovery Vault
    $Containers = Get-AzureRmSiteRecoveryProtectionContainer -ErrorAction Stop
    If ([string]::IsNullOrEmpty($Containers) -eq $true)
    {
        Write-Output "ASR Recovery Vault isn't completely configured yet. No data to ingest from the specific Recovery Vault at this point"
    }
    else
    {
        Write-Output $Containers.FriendlyName
        # Iterate through all Containers, discover protection entities and send data to OMS
        foreach ($Container in $Containers)
        {
            $VMSize -Location $Location -ErrorAction "Stop"
            $CurrentVMUsage -Location $Location -ErrorAction "Stop"
            $CurrentStorageUsage = Get-AzureRmStorageUsage -ErrorAction Stop
            $AllVms = Get-AzureRmVm -ErrorAction Stop
            $DRServer = Get-AzureRmSiteRecoveryServer -ErrorAction Stop
            $RecoveryVms -ProtectionContainer $Container  Write-Output $RecoveryVms.FriendlyName -ErrorAction "Stop"
            # Getting VM Details
            foreach ($RecoveryVm in $RecoveryVms)
            {
                $params = @{
                    Location = $Location | Where-Object {$_.Name
                    eq = $null
                    and = $RecoveryVm.ReplicationProvider
                    ne = "HyperVReplica2012R2" ) { $vNetRgName = "None" $vNetName = "None" $StorageInfo = $RecoveryVm.RecoveryAzureStorageAccount.split(" /" ) $StorageRgName = $StorageInfo[4] $StorageName = $StorageInfo[8]"
                    ErrorAction = "Stop"
                }
                $VMSize @params
                            Write-Output "Found the following Hyper-V Protected machines missing vNet" $RecoveryVm.FriendlyName
                        }
                        # Ignoring On-Prem 2 On-Prem scenario for now
                        else
                        {
                            if ($RecoveryVm.ReplicationProvider -eq "HyperVReplica2012R2" )
                            {
                                    $vNetRgName = "None"
                                    $vNetName = "None"
                                    $StorageRgName = "None"
                                    $StorageName = "None"
                                Write-Output "These VMs are ignored for OMS for now" $RecoveryVm.FriendlyName
                            }
                            # Fetching unprotected VMs with no Azure association
                            else
                            {
                                if($RecoveryVm.ReplicationProvider -eq $null)
                                {
                                    $vNetRgName = "None"
                                    $vNetName = "None"
                                    $StorageRgName = "None"
                                    $StorageName = "None"
                                    Write-Output "Found the following unprotected VMs" $RecoveryVm.FriendlyName
                                }
                            }
                        }
                    }
            #Constructing the data log for OMS Log Analytics
$ASRVMs = @()
$Data = New-Object -ErrorAction Stop psobject -Property @{
                    LogType = 'VM';
                    ASRResourceGroupName = $Vault.ResourceGroupName;
                    ASRVaultName = $vault.Name;
                    ASRVaultLocation = $Location;
                    VMName = $RecoveryVm.FriendlyName;
                    VMId = $RecoveryVm.ID.Split(" /" )[14];
                    ProtectionStatus = $RecoveryVm.ProtectionStatus;
                    ActiveLocation = $RecoveryVm.ActiveLocation;
                    ReplicationHealth = $RecoveryVm.ReplicationHealth;
                    TestFailoverDescription = $RecoveryVm.TestFailoverDescription;
                    AzureFailoverNetwork = $vNetName;
                    AzureStorageAccount = $StorageName;
                    AzurevNetResourceGroupName = $vNetRgName;
                    AzureStorageAccountResourceGroupName = $StorageRgName;
                    Disk = $RecoveryVm.Disks.Name;
                    SubscriptionId = $azuresubscriptionid;
                    ProviderHeartbeat = $DRServer[0].LastHeartbeat.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss');
                    SiteRecoveryServerConnectionStatus = $DRServer[0].Connected;
                    SiteRecoveryProviderVersion = $DRServer[0].ProviderVersion;
                    SiteRecoveryServerVersion = $DRServer[0].ServerVersion;
                    SiteRecoveryServer = $DRServer.FriendlyName;
                    NumberOfCores = $VMSize.NumberOfCores;
                    VMSize = $RecoveryVm.RecoveryAzureVMSize;
                    AzureVMCoresInUse = $CurrentVMUsage[1].CurrentValue;
                    AzureVMCoresTotalLimit = $CurrentVMUsage[1].Limit;
                    AzureVMsInUse = $CurrentVMUsage[2].CurrentValue;
                    AzureVMsTotalLimit = $CurrentVMUsage[2].Limit;
                    AzureVMsInSubscription = $AllVms.count;
                    AzureStorageAccountsInUse = $CurrentStorageUsage.CurrentValue;
                    AzureStorageAccountTotalLimit = $CurrentStorageUsage.Limit;
                    VMReplicationProvider = $RecoveryVm.ReplicationProvider
                    }
         $ASRVMs = $ASRVMs + $Data
         write-output $ASRVMs
$ASRVMsJson = ConvertTo-Json -InputObject $ASRVMs
$LogType = "RecoveryServices"
         Send-OMSAPIIngestionData -customerId $omsworkspaceId -sharedKey $omsworkspaceKey -body $ASRVMsJson -logType $LogType
            }
         }
      }
   }
}


