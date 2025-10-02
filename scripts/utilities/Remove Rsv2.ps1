#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Remove Rsv2

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
Write-Output "WARNING: Please ensure that you have at least PowerShell 7 before running this script. Visit https://go.microsoft.com/fwlink/?linkid=2181071 for the procedure." # Color: $2
$RSmodule = Get-Module -Name Az.RecoveryServices -ListAvailable
$NWmodule = Get-Module -Name Az.Network -ListAvailable
$RSversion = $RSmodule.Version.ToString()
$NWversion = $NWmodule.Version.ToString()
if($RSversion -lt " 5.3.0" ) {
	Uninstall-Module -Name Az.RecoveryServices
	Set-ExecutionPolicy -ExecutionPolicy Unrestricted
	Install-Module -Name Az.RecoveryServices -Repository PSGallery -Force -AllowClobber
}
if($NWversion -lt " 4.15.0" ) {
	Uninstall-Module -Name Az.Network
	Set-ExecutionPolicy -ExecutionPolicy Unrestricted
	Install-Module -Name Az.Network -Repository PSGallery -Force -AllowClobber
}
Connect-AzAccount
$VaultName = "FGC-Azure-Prod-Recovery-Services-Vault-004" #fetch automatically
$Subscription = "Microsoft Azure - FGC Production - ACTIVE" #fetch automatically
$ResourceGroup = " 004-FGC-Azure-Prod-Recovery-services-Vault-Rg" #fetch automatically
$SubscriptionId = " 3532a85c-c00a-4465-9b09-388248166360" #fetch automatically
$IsVaultSoftDeleteFeatureEnabled = " false" #this paramater is based on Vault soft delete feature is enabled or not in this region.
Select-AzSubscription $Subscription
$VaultToDelete = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroup
Set-AzRecoveryServicesAsrVaultContext -Vault $VaultToDelete
if($IsVaultSoftDeleteFeatureEnabled -eq $false) {
	Set-AzRecoveryServicesVaultProperty -VaultId $VaultToDelete.ID -SoftDeleteFeatureState Disable
	Write-Output "Soft delete disabled for the vault" $VaultName
	$ContainerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted" } #fetch backup items in soft delete state
	foreach ($softitem in $ContainerSoftDelete) {
		Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $VaultToDelete.ID -Force
	}
	$ContainerSoftDeleteSql = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $VaultToDelete.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted" }
	foreach ($softitemsql in $ContainerSoftDeleteSql) {
		Undo-AzRecoveryServicesBackupItemDeletion -Item $softitemsql -VaultId $VaultToDelete.ID -Force
	}
}
Set-AzRecoveryServicesVaultProperty -VaultId $VaultToDelete.ID -DisableHybridBackupSecurityFeature $true
Write-Output "Disabled Security features for the vault"
$BackupItemsVM = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID
$BackupItemsSQL = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $VaultToDelete.ID
$BackupItemsAFS = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureStorage -WorkloadType AzureFiles -VaultId $VaultToDelete.ID
$BackupItemsSAP = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType SAPHanaDatabase -VaultId $VaultToDelete.ID
$BackupContainersSQL = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $VaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq "SQL" }
$ProtectableItemsSQL = Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $VaultToDelete.ID | Where-Object {$_.IsAutoProtected -eq $true}
$BackupContainersSAP = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $VaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq "SAPHana" }
$StorageAccounts = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -VaultId $VaultToDelete.ID
$BackupServersMARS = Get-AzRecoveryServicesBackupContainer -ContainerType "Windows" -BackupManagementType MAB -VaultId $VaultToDelete.ID
$BackupServersMABS = Get-AzRecoveryServicesBackupManagementServer -VaultId $VaultToDelete.ID| Where-Object { $_.BackupManagementType -eq "AzureBackupServer" }
$BackupServersDPM = Get-AzRecoveryServicesBackupManagementServer -VaultId $VaultToDelete.ID | Where-Object { $_.BackupManagementType-eq "SCDPM" }
$pvtendpoints = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $VaultToDelete.ID
foreach($item in $BackupItemsVM) {
	Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
}
Write-Output "Disabled and deleted Azure VM backup items"
foreach($item in $BackupItemsSQL) {
	Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
}
Write-Output "Disabled and deleted SQL Server backup items"
foreach($item in $ProtectableItemsSQL) {
	Disable-AzRecoveryServicesBackupAutoProtection -BackupManagementType AzureWorkload -WorkloadType MSSQL -InputItem $item -VaultId $VaultToDelete.ID
}
Write-Output "Disabled auto-protection and deleted SQL protectable items"
foreach($item in $BackupContainersSQL) {
	Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
}
Write-Output "Deleted SQL Servers in Azure VM containers"
foreach($item in $BackupItemsSAP) {
	Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
}
Write-Output "Disabled and deleted SAP HANA backup items"
foreach($item in $BackupContainersSAP) {
	Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
}
Write-Output "Deleted SAP HANA in Azure VM containers"
foreach($item in $BackupItemsAFS) {
	Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
}
Write-Output "Disabled and deleted Azure File Share backups"
foreach($item in $StorageAccounts) {
	Unregister-AzRecoveryServicesBackupContainer -container $item -Force -VaultId $VaultToDelete.ID
}
Write-Output "Unregistered Storage Accounts"
foreach($item in $BackupServersMARS) {
	Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
}
Write-Output "Deleted MARS Servers"
foreach($item in $BackupServersMABS) {
	Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $VaultToDelete.ID
}
Write-Output "Deleted MAB Servers"
foreach($item in $BackupServersDPM) {
	Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $VaultToDelete.ID
}
Write-Output "Deleted DPM Servers"
Write-Output "Ensure that you stop protection and delete backup items from the respective MARS, MAB and DPM consoles as well. Visit https://go.microsoft.com/fwlink/?linkid=2186234 to learn more." # Color: $2
$FabricObjects = Get-AzRecoveryServicesAsrFabric -ErrorAction Stop
if ($null -ne $FabricObjects) {
	foreach ($FabricObject in $FabricObjects) {
		$ContainerObjects = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $FabricObject
		foreach ($ContainerObject in $ContainerObjects) {
			$ProtectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $ContainerObject
			foreach ($ProtectedItem in $ProtectedItems) {
				Write-Output "Triggering DisableDR(Purge) for item:" $ProtectedItem.Name
				Remove-AzRecoveryServicesAsrReplicationProtectedItem -InputObject $ProtectedItem -Force
				Write-Output "DisableDR(Purge) completed"
			}
			$ContainerMappings = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $ContainerObject
			foreach ($ContainerMapping in $ContainerMappings) {
				Write-Output "Triggering Remove Container Mapping: " $ContainerMapping.Name
				Remove-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $ContainerMapping -Force
				Write-Output "Removed Container Mapping."
			}
		}
		$NetworkObjects = Get-AzRecoveryServicesAsrNetwork -Fabric $FabricObject
		foreach ($NetworkObject in $NetworkObjects)
		{
			$PrimaryNetwork = Get-AzRecoveryServicesAsrNetwork -Fabric $FabricObject -FriendlyName $NetworkObject
			$NetworkMappings = Get-AzRecoveryServicesAsrNetworkMapping -Network $PrimaryNetwork
			foreach ($NetworkMappingObject in $NetworkMappings)
			{
				$NetworkMapping = Get-AzRecoveryServicesAsrNetworkMapping -Name $NetworkMappingObject.Name -Network $PrimaryNetwork
				Remove-AzRecoveryServicesAsrNetworkMapping -InputObject $NetworkMapping
			}
		}
		Write-Output "Triggering Remove Fabric:" $FabricObject.FriendlyName
		Remove-AzRecoveryServicesAsrFabric -InputObject $FabricObject -Force
		Write-Output "Removed Fabric."
	}
}
Write-Output "Warning: This script will only remove the replication configuration from Azure Site Recovery and not from the source. Please cleanup the source manually. Visit https://go.microsoft.com/fwlink/?linkid=2182781 to learn more." # Color: $2
foreach($item in $pvtendpoints) {
	$penamesplit = $item.Name.Split(" ." )
	$pename = $penamesplit[0]
	Remove-AzPrivateEndpointConnection -ResourceId $item.Id -Force
	Remove-AzPrivateEndpoint -Name $pename -ResourceGroupName $ResourceGroup -Force
}
Write-Output "Removed Private Endpoints"
$FabricCount = 0
$ASRProtectedItems = 0
$ASRPolicyMappings = 0
$FabricObjects = Get-AzRecoveryServicesAsrFabric -ErrorAction Stop
if ($null -ne $FabricObjects) {
	foreach ($FabricObject in $FabricObjects) {
		$ContainerObjects = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $FabricObject
		foreach ($ContainerObject in $ContainerObjects) {
			$ProtectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $ContainerObject
			foreach ($ProtectedItem in $ProtectedItems) {
				$ASRProtectedItems++
			}
			$ContainerMappings = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $ContainerObject
			foreach ($ContainerMapping in $ContainerMappings) {
				$ASRPolicyMappings++
			}
		}
		$FabricCount++
	}
}
$BackupItemsVMFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID
$BackupItemsSQLFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $VaultToDelete.ID
$BackupContainersSQLFin = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $VaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq "SQL" }
$ProtectableItemsSQLFin = Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $VaultToDelete.ID | Where-Object {$_.IsAutoProtected -eq $true}
$BackupItemsSAPFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType SAPHanaDatabase -VaultId $VaultToDelete.ID
$BackupContainersSAPFin = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $VaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq "SAPHana" }
$BackupItemsAFSFin = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureStorage -WorkloadType AzureFiles -VaultId $VaultToDelete.ID
$StorageAccountsFin = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -VaultId $VaultToDelete.ID
$BackupServersMARSFin = Get-AzRecoveryServicesBackupContainer -ContainerType "Windows" -BackupManagementType MAB -VaultId $VaultToDelete.ID
$BackupServersMABSFin = Get-AzRecoveryServicesBackupManagementServer -VaultId $VaultToDelete.ID| Where-Object { $_.BackupManagementType -eq "AzureBackupServer" }
$BackupServersDPMFin = Get-AzRecoveryServicesBackupManagementServer -VaultId $VaultToDelete.ID | Where-Object { $_.BackupManagementType-eq "SCDPM" }
$PvtendpointsFin = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $VaultToDelete.ID
if($BackupItemsVMFin.count -ne 0) {Write-Output $BackupItemsVMFin.count "Azure VM backups are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($BackupItemsSQLFin.count -ne 0) {Write-Output $BackupItemsSQLFin.count "SQL Server Backup Items are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($BackupContainersSQLFin.count -ne 0) {Write-Output $BackupContainersSQLFin.count "SQL Server Backup Containers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($ProtectableItemsSQLFin.count -ne 0) {Write-Output $ProtectableItemsSQLFin.count "SQL Server Instances are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($BackupItemsSAPFin.count -ne 0) {Write-Output $BackupItemsSAPFin.count "SAP HANA Backup Items are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($BackupContainersSAPFin.count -ne 0) {Write-Output $BackupContainersSAPFin.count "SAP HANA Backup Containers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($BackupItemsAFSFin.count -ne 0) {Write-Output $BackupItemsAFSFin.count "Azure File Shares are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($StorageAccountsFin.count -ne 0) {Write-Output $StorageAccountsFin.count "Storage Accounts are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($BackupServersMARSFin.count -ne 0) {Write-Output $BackupServersMARSFin.count "MARS Servers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($BackupServersMABSFin.count -ne 0) {Write-Output $BackupServersMABSFin.count "MAB Servers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($BackupServersDPMFin.count -ne 0) {Write-Output $BackupServersDPMFin.count "DPM Servers are still registered to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($ASRProtectedItems -ne 0) {Write-Output $ASRProtectedItems "ASR protected items are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($ASRPolicyMappings -ne 0) {Write-Output $ASRPolicyMappings "ASR policy mappings are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($FabricCount -ne 0) {Write-Output $FabricCount "ASR Fabrics are still present in the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
if($PvtendpointsFin.count -ne 0) {Write-Output $PvtendpointsFin.count "Private endpoints are still linked to the vault. Remove the same for successful vault deletion." -ForegroundColor Red}
$accesstoken = Get-AzAccessToken -ErrorAction Stop
$token = $accesstoken.Token
$AuthHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token
}
$RestUri = "https://management.azure.com//subscriptions/" +$SubscriptionId+'/resourcegroups/'+$ResourceGroup+'/providers/Microsoft.RecoveryServices/vaults/'+$VaultName+'?api-version=2021-06-01&operation=DeleteVaultUsingPS';
$response = Invoke-RestMethod -Uri $RestUri -Headers $AuthHeader -Method DELETE
$VaultDeleted = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroup -erroraction 'silentlycontinue'
if ($null -eq $VaultDeleted) {
	Write-Output "Recovery Services Vault" $VaultName " successfully deleted"`n}
