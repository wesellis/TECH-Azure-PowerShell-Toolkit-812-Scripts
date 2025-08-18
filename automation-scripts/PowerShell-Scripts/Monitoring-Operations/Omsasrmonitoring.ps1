<#
.SYNOPSIS
    Omsasrmonitoring

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
    We Enhanced Omsasrmonitoring

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
   Runbook for OMS ASR Log Ingestion
.DESCRIPTION
   This Runbook will ingest ASR related logs to OMS Log Analytics. Preview 0.9 will have limited support for VMware/Physical 2 Azure scenario. 
.AUTHOR
    Kristian Nese (Kristian.Nese@Microsoft.com) ECG OMS CAT


"Logging in to Azure..."
$WEConn = Get-AutomationConnection -Name AzureRunAsConnection 
 Add-AzureRMAccount -ServicePrincipal -Tenant $WEConn.TenantID -ApplicationId $WEConn.ApplicationID -CertificateThumbprint $WEConn.CertificateThumbprint

" Selecting Azure subscription..."
Select-AzureRmSubscription -SubscriptionId $WEConn.SubscriptionID -TenantId $WEConn.tenantid 


$WEOMSWorkspaceId = Get-AutomationVariable -Name 'OMSWorkspaceId'
$WEOMSWorkspaceKey = Get-AutomationVariable -Name 'OMSWorkspaceKey'
$WEAzureSubscriptionId = Get-AutomationVariable -Name 'AzureSubscriptionId'



$WEVaults = Find-AzureRmResource `
                              -ResourceType Microsoft.RecoveryServices/vaults

Write-Output " Found the following vaults:" $WEVaults.name



foreach ($WEVault in $WEVaults)
{
    # Setting Vault context
    $WEVaultSettings = Get-AzureRmRecoveryServicesVault -ErrorAction Stop `
                                                     -Name $WEVault.Name `
                                                     -ResourceGroupName $WEVault.ResourceGroupName
    Write-Output $WEVaultSettings

    $WELocation = $WEVault.Location

    Set-AzureRmSiteRecoveryVaultSettings -ErrorAction Stop `
                                        -ARSVault $WEVaultSettings
    # Ingesting ASRJobs into OMS

    $WEASRLogs = @()
    $WELogData = New-Object -ErrorAction Stop psobject -Property @{}

    $WEASRJobs = Get-AzureRmSiteRecoveryJob -ErrorAction Stop `
                                         -StartTime (Get-Date).AddHours(((-1)))

    if ($null -eq $WEASRJobs)
    {
        Write-output " No new logs to collect"
    } 
    else 
    {
        if ($WEASRJobs.EndTime -eq $null) 
        {
            foreach ($job in $WEASRJobs) 
            {
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name LogType -Value ASRJob
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name JobType -Value $job.JobType
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name State -Value $job.State
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name StateDescription -Value $job.StateDescription                
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name StartTime -Value $job.StartTime.ToUniversalTime().ToString('yyyy-MM-ddtHH:mm:ss')
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name TargetObjectType -Value $job.TargetObjectType
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name TargetObjectName -Value $job.TargetObjectName
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name ID -Value $job.ID
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name SubscriptionId -Value $azuresubscriptionid
            }
        }
        else 
        {
            foreach ($job in $WEASRJobs) 
            {
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name LogType -Value ASRJob
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name JobType -Value $job.JobType
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name State -Value $job.State
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name StateDescription -Value $job.StateDescription
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name StartTime -Value $job.StartTime.ToUniversalTime().ToString('yyyy-MM-ddtHH:mm:ss')                
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name EndTime -Value $job.EndTime.ToUniversalTime().ToString('yyyy-mm-ddtHH:mm:ss')
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name TargetObjectType -Value $job.TargetObjectType
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name TargetObjectName -Value $job.TargetObjectName
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name ID -Value $job.ID
                Add-Member -InputObject $WELogData -MemberType NoteProperty -Name SubscriptionId -Value $azuresubscriptionid
            }
        }
    $WEASRLogs = $WEASRLogs + $WELogData
    Write-output $WEASRLogs

    $WEASRLogsJson = ConvertTo-Json -InputObject $WEASRLogs
    $WELogType = " RecoveryServices"

    Send-OMSAPIIngestionData -customerId $omsworkspaceId -sharedKey $omsworkspaceKey -body $WEASRLogsJson -logType $WELogType

    }

    # Get all Protection Containers for the Recovery Vault

    $WEContainers = Get-AzureRmSiteRecoveryProtectionContainer -ErrorAction Stop

    If ([string]::IsNullOrEmpty($WEContainers) -eq $true)
    {
        Write-Output " ASR Recovery Vault isn't completely configured yet. No data to ingest from the specific Recovery Vault at this point"
    }
    else
    {
        Write-Output $WEContainers.FriendlyName

        # Iterate through all Containers, discover protection entities and send data to OMS
        foreach ($WEContainer in $WEContainers)
        {
            
            $WEVMSize = Get-AzureRmVMSize -ErrorAction Stop `
                                       -Location $WELocation

            $WECurrentVMUsage = Get-AzureRmVMUsage -ErrorAction Stop `
                                       -Location $WELocation

            $WECurrentStorageUsage = Get-AzureRmStorageUsage -ErrorAction Stop

            $WEAllVms = Get-AzureRmVm -ErrorAction Stop

            $WEDRServer = Get-AzureRmSiteRecoveryServer -ErrorAction Stop

            $WERecoveryVms = Get-AzureRmSiteRecoveryVM -ErrorAction Stop `
                                       -ProtectionContainer $WEContainer
            
            Write-Output $WERecoveryVms.FriendlyName

            # Getting VM Details
            foreach ($WERecoveryVm in $WERecoveryVms)
            {
                $WEVMSize = Get-AzureRmVMSize -ErrorAction Stop `
                                           -Location $WELocation | Where-Object {$_.Name -eq $WERecoveryVm.RecoveryAzureVMSize}
                
                # Detect VMs protected by InMageAzureV2 Replication Provider
                if ($WERecoveryVm.ReplicationProvider -eq " InMageAzureV2" )
                {
                    $vNetInfo = " None"
                    $vNetRgName = " None"
                    $WEStorageInfo = " None"
                    $WEStorageRgName = " None"
                    $WEStorageName = " None"
                    
                    Write-Output " Found the following VMware protected machines" $WERecoveryVm.FriendlyName
                }
                # Detect VMs Protected using Hyper-V 2 Azure
                else
                {
                    # Detect VMs that are connected to storage and vNet in Azure
                    if($WERecoveryVm.SelectedRecoveryAzureNetworkId -ne $null -and $WERecoveryVm.RecoveryAzureStorageAccount -ne $null -and $WERecoveryVm.ReplicationProvider -ne " HyperVReplica2012R2" )
                    {
                        $vNetInfo = $WERecoveryVm.SelectedRecoveryAzureNetworkId.split(" /" )
                        $vNetRgName = $vNetInfo[4]
                        $vNetName = $vNetInfo[8]
                        $WEStorageInfo = $WERecoveryVm.RecoveryAzureStorageAccount.split(" /" )
                        $WEStorageRgName = $WEStorageInfo[4]
                        $WEStorageName = $WEStorageInfo[8]
                        
                        Write-Output " Found the following Hyper-V protected machines" $WERecoveryVm.FriendlyName
                    }
                    # Detect VMs that are missing vNet connection in Azure
                    else
                    {
                        if ($WERecoveryVm.RecoveryAzureStorageAccount -ne $null -and $WERecoveryVm.SelectedRecoveryAzureNetworkId -eq $null -and $WERecoveryVm.ReplicationProvider -ne " HyperVReplica2012R2" )
                        {
                            $vNetRgName = " None"
                            $vNetName = " None"
                            $WEStorageInfo = $WERecoveryVm.RecoveryAzureStorageAccount.split(" /" )
                            $WEStorageRgName = $WEStorageInfo[4]
                            $WEStorageName = $WEStorageInfo[8]

                            Write-Output " Found the following Hyper-V Protected machines missing vNet" $WERecoveryVm.FriendlyName
                        }
                        # Ignoring On-Prem 2 On-Prem scenario for now
                        else
                        {
                            if ($WERecoveryVm.ReplicationProvider -eq " HyperVReplica2012R2" )
                            {
                                    $vNetRgName = " None"
                                    $vNetName = " None"
                                    $WEStorageRgName = " None"
                                    $WEStorageName = " None"

                                Write-Output " These VMs are ignored for OMS for now" $WERecoveryVm.FriendlyName
                            }
                            # Fetching unprotected VMs with no Azure association
                            else
                            {
                                if($WERecoveryVm.ReplicationProvider -eq $null)
                                {
                                    $vNetRgName = " None"
                                    $vNetName = " None"
                                    $WEStorageRgName = " None"
                                    $WEStorageName = " None"
                                    
                                    Write-Output " Found the following unprotected VMs" $WERecoveryVm.FriendlyName
                                }
                            }
                        }
                    }
            #Constructing the data log for OMS Log Analytics

           ;  $WEASRVMs = @()
               ;  $WEData = New-Object -ErrorAction Stop psobject -Property @{
                    LogType = 'VM';
                    ASRResourceGroupName = $WEVault.ResourceGroupName;
                    ASRVaultName = $vault.Name;
                    ASRVaultLocation = $WELocation;
                    VMName = $WERecoveryVm.FriendlyName;
                    VMId = $WERecoveryVm.ID.Split(" /" )[14];
                    ProtectionStatus = $WERecoveryVm.ProtectionStatus;
                    ActiveLocation = $WERecoveryVm.ActiveLocation;
                    ReplicationHealth = $WERecoveryVm.ReplicationHealth;
                    TestFailoverDescription = $WERecoveryVm.TestFailoverDescription;
                    AzureFailoverNetwork = $vNetName;
                    AzureStorageAccount = $WEStorageName;
                    AzurevNetResourceGroupName = $vNetRgName;
                    AzureStorageAccountResourceGroupName = $WEStorageRgName;
                    Disk = $WERecoveryVm.Disks.Name;
                    SubscriptionId = $azuresubscriptionid;
                    ProviderHeartbeat = $WEDRServer[0].LastHeartbeat.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss');
                    SiteRecoveryServerConnectionStatus = $WEDRServer[0].Connected;
                    SiteRecoveryProviderVersion = $WEDRServer[0].ProviderVersion;
                    SiteRecoveryServerVersion = $WEDRServer[0].ServerVersion;
                    SiteRecoveryServer = $WEDRServer.FriendlyName;
                    NumberOfCores = $WEVMSize.NumberOfCores;
                    VMSize = $WERecoveryVm.RecoveryAzureVMSize;
                    AzureVMCoresInUse = $WECurrentVMUsage[1].CurrentValue;
                    AzureVMCoresTotalLimit = $WECurrentVMUsage[1].Limit;
                    AzureVMsInUse = $WECurrentVMUsage[2].CurrentValue;
                    AzureVMsTotalLimit = $WECurrentVMUsage[2].Limit;
                    AzureVMsInSubscription = $WEAllVms.count;
                    AzureStorageAccountsInUse = $WECurrentStorageUsage.CurrentValue;
                    AzureStorageAccountTotalLimit = $WECurrentStorageUsage.Limit;
                    VMReplicationProvider = $WERecoveryVm.ReplicationProvider
                    }
                
         $WEASRVMs = $WEASRVMs + $WEData
         write-output $WEASRVMs
         
        ;  $WEASRVMsJson = ConvertTo-Json -InputObject $WEASRVMs

        ;  $WELogType = " RecoveryServices"

         Send-OMSAPIIngestionData -customerId $omsworkspaceId -sharedKey $omsworkspaceKey -body $WEASRVMsJson -logType $WELogType

            }
         }              
      }
   }   
}                                                                                           


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================