#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Remove Recoveryservicesvaults Updated

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
    We Enhanced Remove Recoveryservicesvaults Updated

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-Remove-SingleVault -ErrorAction Stop {
    

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
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
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault] $WEVault
    )

    Write-WELog " Processing vault: $($WEVault.Name) in resource group: $($WEVault.ResourceGroupName)" " INFO" -ForegroundColor Yellow
    
    # Switch to the vault's subscription context
    Set-AzContext -Subscription $WEVault.SubscriptionId -Force | Out-Null
    
    # Get vault context
    $WEVaultToDelete = Get-AzRecoveryServicesVault -Name $WEVault.Name -ResourceGroupName $WEVault.ResourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $WEVaultToDelete

    # Disable enhanced security
    Set-AzRecoveryServicesVaultProperty -VaultId $WEVaultToDelete.ID -DisableHybridBackupSecurityFeature $true
    Write-WELog " Disabled Security features for the vault" " INFO"

    # Disable soft delete and delete soft-deleted items
    Set-AzRecoveryServicesVaultProperty -VaultId $WEVaultToDelete.ID -SoftDeleteFeatureState Disable
    Write-WELog " Soft delete disabled for the vault" " INFO"

    # Handle soft-deleted items
    $containerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $WEVaultToDelete.ID | Where-Object {$_.DeleteState -eq " ToBeDeleted" }
    foreach ($softitem in $containerSoftDelete) {
        Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $WEVaultToDelete.ID -Force
    }

    # Get all protected items and servers
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

    # Remove VM backups
    foreach($item in $backupItemsVM) {
        Write-WELog " Disabling backup for item: $($item.Name)" " INFO"
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force
    }

    # Remove SQL backups
    foreach($item in $backupItemsSQL) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force
    }

    # Remove SQL auto-protection
    foreach($item in $protectableItemsSQL) {
        Disable-AzRecoveryServicesBackupAutoProtection -BackupManagementType AzureWorkload -WorkloadType MSSQL -InputItem $item -VaultId $WEVaultToDelete.ID
    }

    # Remove SQL containers
    foreach($item in $backupContainersSQL) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $WEVaultToDelete.ID
    }

    # Remove SAP HANA backups
    foreach($item in $backupItemsSAP) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force
    }

    # Remove SAP HANA containers
    foreach($item in $backupContainersSAP) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $WEVaultToDelete.ID
    }

    # Remove Azure File Share backups
    foreach($item in $backupItemsAFS) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $WEVaultToDelete.ID -RemoveRecoveryPoints -Force
    }

    # Remove Storage Account containers
    foreach($item in $WEStorageAccounts) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $WEVaultToDelete.ID
    }

    # Remove MARS servers
    foreach($item in $backupServersMARS) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $WEVaultToDelete.ID
    }

    # Remove MABS servers
    foreach($item in $backupServersMABS) {
        Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $WEVaultToDelete.ID
    }

    # Remove DPM servers
    foreach($item in $backupServersDPM) {
        Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $WEVaultToDelete.ID
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
    $pvtendpoints = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $WEVaultToDelete.ID
    foreach($item in $pvtendpoints) {
        Remove-AzPrivateEndpointConnection -ResourceId $item.Id -Force
    }

    # Finally, delete the vault
    Write-WELog " Attempting to delete vault: $($WEVaultToDelete.Name)" " INFO" -ForegroundColor Yellow
    Remove-AzRecoveryServicesVault -Vault $WEVaultToDelete -Force
    Write-WELog " Successfully deleted vault: $($WEVaultToDelete.Name)" " INFO" -ForegroundColor Green
}

[CmdletBinding()]
function WE-Remove-AllRecoveryServicesVaults -ErrorAction Stop {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param()

    try {
        # Check if user is logged in
        $context = Get-AzContext -ErrorAction Stop
        if (-not $context) {
            Write-Error " Not logged into Azure. Please run Connect-AzAccount first."
            return
        }

        # Get all subscriptions
        $subscriptions = Get-AzSubscription -ErrorAction Stop
        Write-WELog " `nFound $($subscriptions.Count) subscriptions" " INFO" -ForegroundColor Cyan

        # Get all vaults across all subscriptions
        $allVaults = @()
        foreach ($sub in $subscriptions) {
            try {
               ;  $null = Set-AzContext -Subscription $sub.Id -Force
                Write-WELog " Scanning subscription: $($sub.Name) ($($sub.Id))" " INFO" -ForegroundColor Yellow
               ;  $vaults = Get-AzRecoveryServicesVault -ErrorAction Stop
                if ($vaults) {
                    Write-WELog "  Found $($vaults.Count) vaults" " INFO" -ForegroundColor Cyan
                   ;  $allVaults = $allVaults + $vaults
                }
                else {
                    Write-WELog "  No vaults found" " INFO" -ForegroundColor Gray
                }
            }
            catch {
                Write-Warning " Failed to access subscription: $($sub.Name) - $_"
                continue
            }
        }

        if ($allVaults.Count -eq 0) {
            Write-WELog " No Recovery Services vaults found across any subscriptions." " INFO" -ForegroundColor Green
            return
        }

        Write-WELog " `nFound $($allVaults.Count) Recovery Services vaults across all subscriptions:" " INFO" -ForegroundColor Cyan
        $allVaults | Format-Table -Property Name, ResourceGroupName, @{l='Subscription';e={$_.SubscriptionId}} -AutoSize

        if ($WEPSCmdlet.ShouldProcess(" All Recovery Services vaults" , " Delete" )) {
            $confirmation = Read-Host " Are you sure you want to delete all these vaults? (yes/no)"
            if ($confirmation -ne " yes" ) {
                Write-WELog " Operation cancelled by user." " INFO" -ForegroundColor Yellow
                return
            }

            foreach ($vault in $allVaults) {
                try {
                    Remove-SingleVault -Vault $vault
                }
                catch {
                    Write-Error " Failed to process vault $($vault.Name): $_"
                }
            }
        }
    }
    catch {
        Write-Error " An error occurred: $_"
    }
}


Remove-AllRecoveryServicesVaults -ErrorAction Stop    # To run with confirmation



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
