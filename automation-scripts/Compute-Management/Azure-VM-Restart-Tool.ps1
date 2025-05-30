# ============================================================================
# Script Name: Azure Virtual Machine Restart Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates restart of Azure Virtual Machines
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VmName
)

Restart-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
