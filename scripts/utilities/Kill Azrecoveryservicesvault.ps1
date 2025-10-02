#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Kill Azrecoveryservicesvault

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
function Write-Host {
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    $ResourceGroup,
    $VaultName
)
    $VaultToDelete = Get-AzRecoveryServicesVault -Name $VaultName -ResourceGroupName $ResourceGroup
Set-AzRecoveryServicesAsrVaultContext -Vault $VaultToDelete
Set-AzRecoveryServicesVaultProperty -Vault $VaultToDelete.ID -SoftDeleteFeatureState Disable
Write-Output "Soft delete disabled for the vault" $VaultName
    $ContainerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted" } #fetch backup items in soft delete state
foreach ($softitem in $ContainerSoftDelete)
{
    Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $VaultToDelete.ID -Force
}
    $body = @{properties=@{enhancedSecurityState= "Disabled" }}
    $RestUri = " $($VaultToDelete.ID)/backupconfig/vaultconfig?api-version=2019-05-13"
Write-Output $RestUri
    $response = Invoke-AzRestMethod -Method PATCH -Payload ($body | ConvertTo-JSON -Depth 9) -Path " $RestUri"
Write-Output "Disabled Security features for the vault -- response:"
Write-Output $response.StatusCode
Write-Output $response.content
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
foreach($item in $ProtectableItemsSQL)
	{
		Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
	}
Write-Output "Disabled and deleted SQL protectable items"
foreach($item in $BackupItemsVM)
    {
        Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
Write-Output "Disabled and deleted Azure VM backup items"
foreach($item in $BackupItemsSQL)
    {
        Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
Write-Output "Disabled and deleted SQL Server backup items"
foreach($item in $ProtectableItems)
    {
        Disable-AzRecoveryServicesBackupAutoProtection -BackupManagementType AzureWorkload -WorkloadType MSSQL -InputItem $item -VaultId $VaultToDelete.ID
    }
Write-Output "Disabled auto-protection and deleted SQL protectable items"
foreach($item in $BackupContainersSQL)
    {
        Unregister-AzRecoveryServicesBackupContainer -Verbose -Container $item -Force -VaultId $VaultToDelete.ID
    }
Write-Output "Deleted SQL Servers in Azure VM containers"
foreach($item in $BackupItemsSAP)
    {
        Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
Write-Output "Disabled and deleted SAP HANA backup items"
foreach($item in $BackupContainersSAP)
    {
        Unregister-AzRecoveryServicesBackupContainer -Verbose -Container $item -Force -VaultId $VaultToDelete.ID
    }
Write-Output "Deleted SAP HANA in Azure VM containers"
foreach($item in $BackupItemsAFS)
    {
        Disable-AzRecoveryServicesBackupProtection -Verbose -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
Write-Output "Disabled and deleted Azure File Share backups"
foreach($item in $StorageAccounts)
    {
        Unregister-AzRecoveryServicesBackupContainer -Verbose -container $item -Force -VaultId $VaultToDelete.ID
    }
Write-Output "Unregistered Storage Accounts"
foreach($item in $BackupServersMARS)
    {
    	Unregister-AzRecoveryServicesBackupContainer -Verbose -Container $item -Force -VaultId $VaultToDelete.ID
    }
Write-Output "Deleted MARS Servers"
foreach($item in $BackupServersMABS)
    {
	    Unregister-AzRecoveryServicesBackupManagementServer -Verbose -AzureRmBackupManagementServer $item -VaultId $VaultToDelete.ID
    }
Write-Output "Deleted MAB Servers"
foreach($item in $BackupServersDPM)
    {
	    Unregister-AzRecoveryServicesBackupManagementServer -Verbose -AzureRmBackupManagementServer $item -VaultId $VaultToDelete.ID
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
foreach($item in $pvtendpoints)
	{
    $penamesplit = $item.Name.Split(" ." )
    $pename = $penamesplit[0]
		Remove-AzPrivateEndpointConnection -ResourceId $item.PrivateEndpoint.Id -Force
		Remove-AzPrivateEndpoint -Name $pename -ResourceGroupName $ResourceGroup -Force
	}
Write-Output "Removed Private Endpoints"
Write-Output "Sleeping for 120 seconds..."
Start-Sleep 120
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
    $BackupServersMABSFin = Get-AzRecoveryServicesBackupManagementServer -VaultId $VaultToDelete.ID| Where-Object { $_.BackupManagementType -eq "AzureBackupServer" };
    $BackupServersDPMFin = Get-AzRecoveryServicesBackupManagementServer -VaultId $VaultToDelete.ID | Where-Object { $_.BackupManagementType-eq "SCDPM" };
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
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
