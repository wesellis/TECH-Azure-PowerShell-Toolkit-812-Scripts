#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Remove Recoveryservicesvaults Updated

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[OutputType([PSObject])]
 -ErrorAction Stop {
function Write-Host {
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
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.RecoveryServices.ARSVault] $Vault
    )
    Write-Output "Processing vault: $($Vault.Name) in resource group: $($Vault.ResourceGroupName)" # Color: $2
    Set-AzContext -Subscription $Vault.SubscriptionId -Force | Out-Null
    $VaultToDelete = Get-AzRecoveryServicesVault -Name $Vault.Name -ResourceGroupName $Vault.ResourceGroupName
    Set-AzRecoveryServicesVaultContext -Vault $VaultToDelete
    Set-AzRecoveryServicesVaultProperty -VaultId $VaultToDelete.ID -DisableHybridBackupSecurityFeature $true
    Write-Output "Disabled Security features for the vault"
    Set-AzRecoveryServicesVaultProperty -VaultId $VaultToDelete.ID -SoftDeleteFeatureState Disable
    Write-Output "Soft delete disabled for the vault"
    $ContainerSoftDelete = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -VaultId $VaultToDelete.ID | Where-Object {$_.DeleteState -eq "ToBeDeleted" }
    foreach ($softitem in $ContainerSoftDelete) {
        Undo-AzRecoveryServicesBackupItemDeletion -Item $softitem -VaultId $VaultToDelete.ID -Force
    }
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
    foreach($item in $BackupItemsVM) {
        Write-Output "Disabling backup for item: $($item.Name)"
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
    foreach($item in $BackupItemsSQL) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
    foreach($item in $ProtectableItemsSQL) {
        Disable-AzRecoveryServicesBackupAutoProtection -BackupManagementType AzureWorkload -WorkloadType MSSQL -InputItem $item -VaultId $VaultToDelete.ID
    }
    foreach($item in $BackupContainersSQL) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
    }
    foreach($item in $BackupItemsSAP) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
    foreach($item in $BackupContainersSAP) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
    }
    foreach($item in $BackupItemsAFS) {
        Disable-AzRecoveryServicesBackupProtection -Item $item -VaultId $VaultToDelete.ID -RemoveRecoveryPoints -Force
    }
    foreach($item in $StorageAccounts) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
    }
    foreach($item in $BackupServersMARS) {
        Unregister-AzRecoveryServicesBackupContainer -Container $item -Force -VaultId $VaultToDelete.ID
    }
    foreach($item in $BackupServersMABS) {
        Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $VaultToDelete.ID
    }
    foreach($item in $BackupServersDPM) {
        Unregister-AzRecoveryServicesBackupManagementServer -AzureRmBackupManagementServer $item -VaultId $VaultToDelete.ID
    }
    $FabricObjects = Get-AzRecoveryServicesAsrFabric -ErrorAction Stop
    if ($null -ne $FabricObjects) {
        foreach ($FabricObject in $FabricObjects) {
    $ContainerObjects = Get-AzRecoveryServicesAsrProtectionContainer -Fabric $FabricObject
            foreach ($ContainerObject in $ContainerObjects) {
    $ProtectedItems = Get-AzRecoveryServicesAsrReplicationProtectedItem -ProtectionContainer $ContainerObject
                foreach ($ProtectedItem in $ProtectedItems) {
                    Remove-AzRecoveryServicesAsrReplicationProtectedItem -InputObject $ProtectedItem -Force
                }
    $ContainerMappings = Get-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainer $ContainerObject
                foreach ($ContainerMapping in $ContainerMappings) {
                    Remove-AzRecoveryServicesAsrProtectionContainerMapping -ProtectionContainerMapping $ContainerMapping -Force
                }
            }
            Remove-AzRecoveryServicesAsrFabric -InputObject $FabricObject -Force
        }
    }
    $pvtendpoints = Get-AzPrivateEndpointConnection -PrivateLinkResourceId $VaultToDelete.ID
    foreach($item in $pvtendpoints) {
        Remove-AzPrivateEndpointConnection -ResourceId $item.Id -Force
    }
    Write-Output "Attempting to delete vault: $($VaultToDelete.Name)" # Color: $2
    Remove-AzRecoveryServicesVault -Vault $VaultToDelete -Force
    Write-Output "Successfully deleted vault: $($VaultToDelete.Name)" # Color: $2
}
function Remove-AllRecoveryServicesVaults -ErrorAction Stop {
    param()
    try {
    $context = Get-AzContext -ErrorAction Stop
        if (-not $context) {
            Write-Error "Not logged into Azure. Please run Connect-AzAccount first."
            return
        }
    $subscriptions = Get-AzSubscription -ErrorAction Stop
        Write-Output " `nFound $($subscriptions.Count) subscriptions" # Color: $2
    $AllVaults = @()
        foreach ($sub in $subscriptions) {
            try {
    $null = Set-AzContext -Subscription $sub.Id -Force
                Write-Output "Scanning subscription: $($sub.Name) ($($sub.Id))" # Color: $2
    $vaults = Get-AzRecoveryServicesVault -ErrorAction Stop
                if ($vaults) {
                    Write-Output "Found $($vaults.Count) vaults" # Color: $2
    $AllVaults = $AllVaults + $vaults
                }
                else {
                    Write-Output "No vaults found" # Color: $2

} catch {
                Write-Warning "Failed to access subscription: $($sub.Name) - $_"
                continue
            }
        }
        if ($AllVaults.Count -eq 0) {
            Write-Output "No Recovery Services vaults found across any subscriptions." # Color: $2
            return
        }
        Write-Output " `nFound $($AllVaults.Count) Recovery Services vaults across all subscriptions:" # Color: $2
    $AllVaults | Format-Table -Property Name, ResourceGroupName, @{l='Subscription';e={$_.SubscriptionId}} -AutoSize
        if ($PSCmdlet.ShouldProcess("All Recovery Services vaults" , "Delete" )) {
    $confirmation = Read-Host "Are you sure you want to delete all these vaults? (yes/no)"
            if ($confirmation -ne "yes" ) {
                Write-Output "Operation cancelled by user." # Color: $2
                return
            }
            foreach ($vault in $AllVaults) {
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
Remove-AllRecoveryServicesVaults -ErrorAction Stop



