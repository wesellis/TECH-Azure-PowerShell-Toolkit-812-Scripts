# ============================================================================
# Script Name: Azure Virtual Machine Backup Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates backup of Azure Virtual Machines using Recovery Services Vault
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VaultName,
    [string]$VmName
)

Backup-AzVM -ResourceGroupName $ResourceGroupName -VaultName $VaultName -Name $VmName
