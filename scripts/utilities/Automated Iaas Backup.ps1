#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.RecoveryServices

<#
.SYNOPSIS
    Automated IaaS VM Backup

.DESCRIPTION
    Azure automation runbook for automated IaaS VM Backup using Recovery Services

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$RecoveryVaultName,

    [Parameter(Mandatory = $true)]
    [string]$RecoveryVaultResourceGroupName,

    [Parameter()]
    [string]$Location,

    [Parameter()]
    [string]$PolicyName = "DefaultPolicy",

    [Parameter()]
    [string[]]$VMResourceGroupNames,

    [Parameter()]
    [pscredential]$Credential
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    # Connect to Azure
    if ($Credential) {
        Connect-AzAccount -Credential $Credential -ErrorAction Stop
    } else {
        Connect-AzAccount -Identity -ErrorAction Stop
    }

    Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    Write-Output "Successfully connected to Azure subscription: $SubscriptionId"
}
catch {
    $errorMessage = "Failed to connect to Azure: $($_.Exception.Message)"
    Write-Error -Message $errorMessage
    throw
}

try {
    # Get Recovery Services Vault
    $vault = Get-AzRecoveryServicesVault -Name $RecoveryVaultName -ResourceGroupName $RecoveryVaultResourceGroupName -ErrorAction Stop
    $vaultLocation = $vault.Location

    if ($Location -and $Location -ne $vaultLocation) {
        Write-Warning "Specified location '$Location' differs from vault location '$vaultLocation'. Using vault location."
    }
    $Location = $vaultLocation

    Write-Output "Retrieved Recovery Services Vault: $RecoveryVaultName in location: $Location"
}
catch {
    $errorMessage = "Failed to retrieve Recovery Services Vault '$RecoveryVaultName': $($_.Exception.Message)"
    Write-Error -Message $errorMessage
    throw
}

try {
    # Get VMs to backup
    if ($VMResourceGroupNames) {
        $vms = @()
        foreach ($rgName in $VMResourceGroupNames) {
            $vms += Get-AzVM -ResourceGroupName $rgName -ErrorAction Stop | Where-Object { $_.Location -eq $Location }
        }
    } else {
        $vms = Get-AzVM -ErrorAction Stop | Where-Object { $_.Location -eq $Location }
    }

    Write-Output "Found $($vms.Count) VMs in location '$Location' to configure for backup"
}
catch {
    $errorMessage = "Failed to retrieve VMs: $($_.Exception.Message)"
    Write-Error -Message $errorMessage
    throw
}

try {
    # Set vault context
    Set-AzRecoveryServicesVaultContext -Vault $vault -ErrorAction Stop

    # Get backup policy
    $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $PolicyName -ErrorAction Stop
    Write-Output "Using backup policy: $PolicyName"

    $successCount = 0
    $failureCount = 0

    foreach ($vm in $vms) {
        try {
            Write-Output "Configuring backup for VM: $($vm.Name)"

            # Check if VM is already protected
            $existingItem = Get-AzRecoveryServicesBackupItem -BackupManagementType AzureVM -WorkloadType AzureVM -Name $vm.Name -ErrorAction SilentlyContinue

            if ($existingItem) {
                Write-Output "VM '$($vm.Name)' is already protected. Skipping."
                continue
            }

            # Enable backup protection
            Enable-AzRecoveryServicesBackupProtection -Policy $policy -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -ErrorAction Stop
            Write-Output "Successfully enabled backup for VM: $($vm.Name)"
            $successCount++
        }
        catch {
            Write-Warning "Failed to enable backup for VM '$($vm.Name)': $($_.Exception.Message)"
            $failureCount++
        }
    }

    Write-Output "Backup configuration completed. Success: $successCount, Failures: $failureCount"
}
catch {
    $errorMessage = "Failed to configure VM backups: $($_.Exception.Message)"
    Write-Error -Message $errorMessage
    throw
}