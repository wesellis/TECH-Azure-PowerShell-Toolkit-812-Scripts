# ============================================================================
# Script Name: Azure Managed Disk Resize Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates resizing of Azure Managed Disks to specified size
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VmName,
    [string]$DiskName,
    [int]$NewSizeGB
)

Update-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $DiskName -DiskSizeGB $NewSizeGB
