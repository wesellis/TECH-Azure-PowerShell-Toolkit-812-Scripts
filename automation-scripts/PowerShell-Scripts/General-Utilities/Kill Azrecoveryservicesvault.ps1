<#
.SYNOPSIS
    Kill Azrecoveryservicesvault

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
    We Enhanced Kill Azrecoveryservicesvault

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


function Write-WELog {
    [CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
	$WEResourceGroup,
	$WEVaultName
)




$WEVaultToDelete = Get-AzRecoveryServicesVault -Name $WEVaultName -ResourceGroupName $WEResourceGroup
Set-AzRecoveryServicesAsrVaultContext -Vault $WEVaultToDelete

Set-AzRecoveryServicesVaultProperty -Vault $WEVaultToDelete.ID -SoftDeleteFeatureState Disable #disable soft delete
Write-WELog " Soft delete disabled for the vault" " INFO" $WEVaultName
$containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $WEVaultToDelete.ID | Where-Object {$_.DeleteState -eq " ToBeDeleted" } #fetch backup items in soft delete state
foreach ($softitem in $containerSoftDelete)
{
    Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $WEVaultToDelete.ID -Force #undelete items in soft delete state
}



$body = @{properties=@{enhancedSecurityState= " Disabled" }}

$restUri = " $($WEVaultToDelete.ID)/backupconfig/vaultconfig?api-version=2019-05-13"

write-host $restUri

$response = Invoke-AzRestMethod -Method PATCH -Payload ($body | ConvertTo-JSON -Depth 9) -Path " $restUri"
Write-WELog " Disabled Security features for the vault -- response:" " INFO"
Write-Host $response.StatusCode
Write-Host $response.content


$backupItemsVM = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $WEVaultToDelete.ID
$backupItemsSQL = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $WEVaultToDelete.ID
$backupItemsAFS = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureStorage -WorkloadType AzureFiles -VaultId $WEVaultToDelete.ID
$backupItemsSAP = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType SAPHanaDatabase -VaultId $WEVaultToDelete.ID
$backupContainersSQL = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $WEVaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq " SQL" }
$protectableItemsSQL = Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $WEVaultToDelete.ID | Where-Object {$_.IsAutoProtected -eq $true}
$backupContainersSAP = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $WEVaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq " SAPHana" }
$WEStorageAccounts = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -VaultId $WEVaultToDelete.ID
$backupServersMARS = Get-AzRecoveryServicesBackupContainer -ContainerType " Windows" -BackupManagementType MAB -VaultId $WEVaultToDelete.ID
$backupServersMABS = Get-AzRecoveryServicesBackupManagementServer -VaultId $WEVaultToDelete.ID| Where-Object { $_.BackupManagementType -eq " AzureBackupServer" }
$backupServersDPM = Get-AzRecoveryServicesBackupManagementServer -VaultId $WEVaultToDelete.ID | Where-Object { $_.BackupManagementType-eq " SCDPM" }
$pvtendpoints = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $WEVaultToDelete.ID


foreach($item in $protectableItemsSQL)
	{
		Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force 
	}
Write-WELog " Disabled and deleted SQL protectable items" " INFO"

foreach($item in $backupItemsVM)
    {
        Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force #stop backup and delete Azure VM backup items
    }
Write-WELog " Disabled and deleted Azure VM backup items" " INFO"

foreach($item in $backupItemsSQL)
    {
        Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force #stop backup and delete SQL Server in Azure VM backup items
    }
Write-WELog " Disabled and deleted SQL Server backup items" " INFO"

foreach($item in $protectableItems)
    {
        Disable-AzRecoveryServicesBackupAutoProtection -BackupManagementType AzureWorkload -WorkloadType MSSQL -InputItem $item -VaultId $WEVaultToDelete.ID #disable auto-protection for SQL
    }
Write-WELog " Disabled auto-protection and deleted SQL protectable items" " INFO"

foreach($item in $backupContainersSQL)
    {
        Unregister-AzRecoveryServicesBackupContainer -Verbose -Container $item -Force -VaultId $WEVaultToDelete.ID #unregister SQL Server in Azure VM protected server
    }
Write-WELog " Deleted SQL Servers in Azure VM containers" " INFO"

foreach($item in $backupItemsSAP)
    {
        Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force #stop backup and delete SAP HANA in Azure VM backup items
    }
Write-WELog " Disabled and deleted SAP HANA backup items" " INFO"

foreach($item in $backupContainersSAP)
    {
        Unregister-AzRecoveryServicesBackupContainer -Verbose -Container $item -Force -VaultId $WEVaultToDelete.ID #unregister SAP HANA in Azure VM protected server
    }
Write-WELog " Deleted SAP HANA in Azure VM containers" " INFO"

foreach($item in $backupItemsAFS)
    {
        Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force #stop backup and delete Azure File Shares backup items
    }
Write-WELog " Disabled and deleted Azure File Share backups" " INFO"

foreach($item in $WEStorageAccounts)
    {
        Unregister-AzRecoveryServicesBackupContainer -Verbose -container $item -Force -VaultId $WEVaultToDelete.ID #unregister storage accounts
    }
Write-WELog " Unregistered Storage Accounts" " INFO"

foreach($item in $backupServersMARS)
    {
    	Unregister-AzRecoveryServicesBackupContainer -Verbose -Container $item -Force -VaultId $WEVaultToDelete.ID #unregister MARS servers and delete corresponding backup items
    }
Write-WELog " Deleted MARS Servers" " INFO"

foreach($item in $backupServersMABS)
    {
	    Unregister-AzRecoveryServicesBackupManagementServer -Verbose -AzureRmBackupManagementServer $item -VaultId $WEVaultToDelete.ID #unregister MABS servers and delete corresponding backup items
    }
Write-WELog " Deleted MAB Servers" " INFO"

foreach($item in $backupServersDPM)
    {
	    Unregister-AzRecoveryServicesBackupManagementServer -Verbose -AzureRmBackupManagementServer $item -VaultId $WEVaultToDelete.ID #unregister DPM servers and delete corresponding backup items
    }
Write-WELog " Deleted DPM Servers" " INFO"
Write-WELog " Ensure that you stop protection and delete backup items from the respective MARS, MAB and DPM consoles as well. Visit https://go.microsoft.com/fwlink/?linkid=2186234 to learn more." " INFO" -ForegroundColor Yellow


$fabricObjects = Get-AzRecoveryServicesAsrFabric # context must already be set (and should be above)
if ($null -ne $fabricObjects) {
	# First DisableDR all VMs.
	foreach ($fabricObject in $fabricObjects) {
		$containerObjects = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabricObject
		foreach ($containerObject in $containerObjects) {
			$protectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $containerObject
			# DisableDR all protected items
			foreach ($protectedItem in $protectedItems) {
				Write-WELog " Triggering DisableDR(Purge) for item:" " INFO" $protectedItem.Name
				Remove-AzRecoveryServicesAsrReplicationProtectedItem -InputObject $protectedItem -Force
				Write-WELog " DisableDR(Purge) completed" " INFO"
			}

			$containerMappings = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $containerObject
			# Remove all Container Mappings
			foreach ($containerMapping in $containerMappings) {
				Write-WELog " Triggering Remove Container Mapping: " " INFO" $containerMapping.Name
				Remove-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $containerMapping -Force
				Write-WELog " Removed Container Mapping." " INFO"
			}
		}
		$WENetworkObjects = Get-AzRecoveryServicesAsrNetwork -Fabric $fabricObject
		foreach ($networkObject in $WENetworkObjects)
		{
			#Get the PrimaryNetwork
			$WEPrimaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $fabricObject -FriendlyName $networkObject
			$WENetworkMappings = Get-AzRecoveryServicesAsrNetworkMapping -Network $WEPrimaryNetwork
			foreach ($networkMappingObject in $WENetworkMappings)
			{
				#Get the Neetwork Mappings
				$WENetworkMapping = Get-AzRecoveryServicesAsrNetworkMapping -Name $networkMappingObject.Name -Network $WEPrimaryNetwork
				Remove-AzRecoveryServicesAsrNetworkMapping -InputObject $WENetworkMapping
			}
		}
		# Remove Fabric
		Write-WELog " Triggering Remove Fabric:" " INFO" $fabricObject.FriendlyName
		Remove-AzRecoveryServicesAsrFabric -InputObject $fabricObject -Force
		Write-WELog " Removed Fabric." " INFO"
	}
}
Write-WELog " Warning: This script will only remove the replication configuration from Azure Site Recovery and not from the source. Please cleanup the source manually. Visit https://go.microsoft.com/fwlink/?linkid=2182781 to learn more." " INFO" -ForegroundColor Yellow
foreach($item in $pvtendpoints)
	{
		$penamesplit = $item.Name.Split(" ." )
		$pename = $penamesplit[0]
		Remove-AzPrivateEndpointConnection -ResourceId $item.PrivateEndpoint.Id -Force #remove private endpoint connections
		Remove-AzPrivateEndpoint -Name $pename -ResourceGroupName $WEResourceGroup -Force #remove private endpoints
	}
Write-WELog " Removed Private Endpoints" " INFO"

Write-WELog " Sleeping for 120 seconds..." " INFO"
Start-Sleep 120 # sometimes it takes a while for items or config to be removed from the vault


$fabricCount = 0
$WEASRProtectedItems = 0
$WEASRPolicyMappings = 0
$fabricObjects = Get-AzRecoveryServicesAsrFabric
if ($null -ne $fabricObjects) {
	foreach ($fabricObject in $fabricObjects) {
		$containerObjects = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabricObject
		foreach ($containerObject in $containerObjects) {
			$protectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $containerObject
			foreach ($protectedItem in $protectedItems) {
				$WEASRProtectedItems++
			}
			$containerMappings = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $containerObject
			foreach ($containerMapping in $containerMappings) {
				$WEASRPolicyMappings++
			}
		}
		$fabricCount++
	}
}

$backupItemsVMFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $WEVaultToDelete.ID
$backupItemsSQLFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $WEVaultToDelete.ID
$backupContainersSQLFin = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $WEVaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq " SQL" }
$protectableItemsSQLFin = Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $WEVaultToDelete.ID | Where-Object {$_.IsAutoProtected -eq $true}
$backupItemsSAPFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType SAPHanaDatabase -VaultId $WEVaultToDelete.ID
$backupContainersSAPFin = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $WEVaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq " SAPHana" }
$backupItemsAFSFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureStorage -WorkloadType AzureFiles -VaultId $WEVaultToDelete.ID
$WEStorageAccountsFin = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -VaultId $WEVaultToDelete.ID
$backupServersMARSFin = Get-AzRecoveryServicesBackupContainer -ContainerType " Windows" -BackupManagementType MAB -VaultId $WEVaultToDelete.ID
$backupServersMABSFin = Get-AzRecoveryServicesBackupManagementServer -VaultId $WEVaultToDelete.ID| Where-Object { $_.BackupManagementType -eq " AzureBackupServer" }; 
$backupServersDPMFin = Get-AzRecoveryServicesBackupManagementServer -VaultId $WEVaultToDelete.ID | Where-Object { $_.BackupManagementType-eq " SCDPM" }; 
$pvtendpointsFin = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $WEVaultToDelete.ID


if($backupItemsVMFin.count -ne 0) {Write-Host $backupItemsVMFin.count " Azure VM backups are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($backupItemsSQLFin.count -ne 0) {Write-Host $backupItemsSQLFin.count " SQL Server Backup Items are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($backupContainersSQLFin.count -ne 0) {Write-Host $backupContainersSQLFin.count " SQL Server Backup Containers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($protectableItemsSQLFin.count -ne 0) {Write-Host $protectableItemsSQLFin.count " SQL Server Instances are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($backupItemsSAPFin.count -ne 0) {Write-Host $backupItemsSAPFin.count " SAP HANA Backup Items are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($backupContainersSAPFin.count -ne 0) {Write-Host $backupContainersSAPFin.count " SAP HANA Backup Containers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($backupItemsAFSFin.count -ne 0) {Write-Host $backupItemsAFSFin.count " Azure File Shares are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($WEStorageAccountsFin.count -ne 0) {Write-Host $WEStorageAccountsFin.count " Storage Accounts are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($backupServersMARSFin.count -ne 0) {Write-Host $backupServersMARSFin.count " MARS Servers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($backupServersMABSFin.count -ne 0) {Write-Host $backupServersMABSFin.count " MAB Servers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($backupServersDPMFin.count -ne 0) {Write-Host $backupServersDPMFin.count " DPM Servers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($WEASRProtectedItems -ne 0) {Write-Host $WEASRProtectedItems " ASR protected items are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($WEASRPolicyMappings -ne 0) {Write-Host $WEASRPolicyMappings " ASR policy mappings are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($fabricCount -ne 0) {Write-Host $fabricCount " ASR Fabrics are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($pvtendpointsFin.count -ne 0) {Write-Host $pvtendpointsFin.count " Private endpoints are still linked to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}





} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
