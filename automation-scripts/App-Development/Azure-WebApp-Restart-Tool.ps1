# ============================================================================
# Script Name: Azure Web Application Restart Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates restart of Azure Web Applications for maintenance and troubleshooting
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AppName
)

Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName
