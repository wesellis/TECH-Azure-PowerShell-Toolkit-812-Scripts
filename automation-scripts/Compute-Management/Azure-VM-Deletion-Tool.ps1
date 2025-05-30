# ============================================================================
# Script Name: Azure Virtual Machine Deletion Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates deletion of Azure Virtual Machines with force option
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$VmName
)

Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force
