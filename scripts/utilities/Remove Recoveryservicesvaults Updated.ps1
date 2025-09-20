#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Remove Recoveryservicesvaults Updated

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
[OutputType([PSObject])]
 -ErrorAction Stop {
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault] $Vault
    )
    Write-Host "Processing vault: $($Vault.Name) in resource group: $($Vault.ResourceGroupName)" -ForegroundColor Yellow
    # Switch to the vault's subscription context
    Set-AzContext -Subscription $Vault.SubscriptionId -Force | Out-Null
    # Get vault context
    $VaultToDelete = Get-AzRecoveryServicesVault -Name $Vault.Name -ResourceGroupName $Vault.ResourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $VaultToDelete
    # Disable enhanced security
    Set-AzRecoveryServicesVaultProperty -VaultId $VaultToDelete.ID -DisableHybridBackupSecurityFeature $true
    Write-Host "Disabled Security features for the vault"
    # Disable soft delete and delete soft-deleted items
    Set-AzRecoveryServicesVaultProperty -VaultId $VaultToDelete.ID -SoftDeleteFeatureState Disable
    Write-Host "Soft delete disabled for the vault"
    # Handle soft-deleted items
    $containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted" }
    foreach ($softitem in $containerSoftDelete) {
        Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $VaultToDelete.ID -Force
    }
    # Get all protected items and servers
    $backupItemsVM = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID
    $backupItemsSQL = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType MSSQL -VaultId $VaultToDelete.ID
    $backupItemsAFS = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureStorage -WorkloadType AzureFiles -VaultId $VaultToDelete.ID
    $backupItemsSAP = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureWorkload -WorkloadType SAPHanaDatabase -VaultId $VaultToDelete.ID
    $backupContainersSQL = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $VaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq "SQL" }
    $protectableItemsSQL = Get-AzRecoveryServicesBackupProtectableItem -WorkloadType MSSQL -VaultId $VaultToDelete.ID | Where-Object {$_.IsAutoProtected -eq $true}
    $backupContainersSAP = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVMAppContainer -VaultId $VaultToDelete.ID | Where-Object {$_.ExtendedInfo.WorkloadType -eq "SAPHana" }
    $StorageAccounts = Get-AzRecoveryServicesBackupContainer -ContainerType AzureStorage -VaultId $VaultToDelete.ID
    $backupServersMARS = Get-AzRecoveryServicesBackupContainer -ContainerType "Windows" -BackupManagementType MAB -VaultId $VaultToDelete.ID
    $backupServersMABS = Get-AzRecoveryServicesBackupManagementServer -VaultId $VaultToDelete.ID| Where-Object { $_.BackupManagementType -eq "AzureBackupServer" }
    $backupServersDPM = Get-AzRecoveryServicesBackupManagementServer -VaultId $VaultToDelete.ID | Where-Object { $_.BackupManagementType-eq "SCDPM" }
    # Remove VM backups
    foreach($item in $backupItemsVM) {
        Write-Host "Disabling backup for item: $($item.Name)"
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
    # Remove SQL backups
    foreach($item in $backupItemsSQL) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
    # Remove SQL auto-protection
    foreach($item in $protectableItemsSQL) {
        Disable-AzRecoveryServicesBackupAutoProtection -BackupManagementType AzureWorkload -WorkloadType MSSQL -InputItem $item -VaultId $VaultToDelete.ID
    }
    # Remove SQL containers
    foreach($item in $backupContainersSQL) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
    }
    # Remove SAP HANA backups
    foreach($item in $backupItemsSAP) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
    # Remove SAP HANA containers
    foreach($item in $backupContainersSAP) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
    }
    # Remove Azure File Share backups
    foreach($item in $backupItemsAFS) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
    # Remove Storage Account containers
    foreach($item in $StorageAccounts) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
    }
    # Remove MARS servers
    foreach($item in $backupServersMARS) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
    }
    # Remove MABS servers
    foreach($item in $backupServersMABS) {
        Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $VaultToDelete.ID
    }
    # Remove DPM servers
    foreach($item in $backupServersDPM) {
        Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $VaultToDelete.ID
    }
    # Handle ASR items
    $fabricObjects = Get-AzRecoveryServicesAsrFabric -ErrorAction Stop
    if ($null -ne $fabricObjects) {
        foreach ($fabricObject in $fabricObjects) {
            $containerObjects = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $fabricObject
            foreach ($containerObject in $containerObjects) {
                $protectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $containerObject
                foreach ($protectedItem in $protectedItems) {
                    Remove-AzRecoveryServicesAsrReplicationProtectedItem -InputObject $protectedItem -Force
                }
                $containerMappings = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $containerObject
                foreach ($containerMapping in $containerMappings) {
                    Remove-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $containerMapping -Force
                }
            }
            Remove-AzRecoveryServicesAsrFabric -InputObject $fabricObject -Force
        }
    }
    # Remove private endpoints
    $pvtendpoints = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $VaultToDelete.ID
    foreach($item in $pvtendpoints) {
        Remove-AzPrivateEndpointConnection -ResourceId $item.Id -Force
    }
    # Finally, delete the vault
    Write-Host "Attempting to delete vault: $($VaultToDelete.Name)" -ForegroundColor Yellow
    Remove-AzRecoveryServicesVault -Vault $VaultToDelete -Force
    Write-Host "Successfully deleted vault: $($VaultToDelete.Name)" -ForegroundColor Green
}
function Remove-AllRecoveryServicesVaults -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    [CmdletBinding()]
param()
    try {
        # Check if user is logged in
        $context = Get-AzContext -ErrorAction Stop
        if (-not $context) {
            Write-Error "Not logged into Azure. Please run Connect-AzAccount first."
            return
        }
        # Get all subscriptions
        $subscriptions = Get-AzSubscription -ErrorAction Stop
        Write-Host " `nFound $($subscriptions.Count) subscriptions" -ForegroundColor Cyan
        # Get all vaults across all subscriptions
        $allVaults = @()
        foreach ($sub in $subscriptions) {
            try {
$null = Set-AzContext -Subscription $sub.Id -Force
                Write-Host "Scanning subscription: $($sub.Name) ($($sub.Id))" -ForegroundColor Yellow
$vaults = Get-AzRecoveryServicesVault -ErrorAction Stop
                if ($vaults) {
                    Write-Host "Found $($vaults.Count) vaults" -ForegroundColor Cyan
$allVaults = $allVaults + $vaults
                }
                else {
                    Write-Host "No vaults found" -ForegroundColor Gray

} catch {
                Write-Warning "Failed to access subscription: $($sub.Name) - $_"
                continue
            }
        }
        if ($allVaults.Count -eq 0) {
            Write-Host "No Recovery Services vaults found across any subscriptions." -ForegroundColor Green
            return
        }
        Write-Host " `nFound $($allVaults.Count) Recovery Services vaults across all subscriptions:" -ForegroundColor Cyan
        $allVaults | Format-Table -Property Name, ResourceGroupName, @{l='Subscription';e={$_.SubscriptionId}} -AutoSize
        if ($PSCmdlet.ShouldProcess("All Recovery Services vaults" , "Delete" )) {
            $confirmation = Read-Host "Are you sure you want to delete all these vaults? (yes/no)"
            if ($confirmation -ne "yes" ) {
                Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                return
            }
            foreach ($vault in $allVaults) {
                try {
                    Remove-SingleVault -Vault $vault
                }
                catch {
                    Write-Error "Failed to process vault $($vault.Name): $_"
                }
            }

} catch {
        Write-Error "An error occurred: $_"
    }
}
Remove-AllRecoveryServicesVaults -ErrorAction Stop    # To run with confirmation


