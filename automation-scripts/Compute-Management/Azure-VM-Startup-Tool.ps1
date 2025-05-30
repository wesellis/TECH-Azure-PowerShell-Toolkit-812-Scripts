# ============================================================================
# Script Name: Azure Virtual Machine Startup Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates startup of Azure Virtual Machines
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VmName
)

Start-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
