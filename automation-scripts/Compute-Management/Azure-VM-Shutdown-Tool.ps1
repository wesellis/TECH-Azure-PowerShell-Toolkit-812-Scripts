# ============================================================================
# Script Name: Azure Virtual Machine Shutdown Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates shutdown of Azure Virtual Machines
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VmName
)

Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force
