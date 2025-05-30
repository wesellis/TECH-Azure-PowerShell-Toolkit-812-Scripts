# ============================================================================
# Script Name: Azure Virtual Machine Restore Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates restore of Azure Virtual Machines from Recovery Services Vault
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName,
    [string]$RestorePoint
)

Restore-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName -RestorePoint $RestorePoint
