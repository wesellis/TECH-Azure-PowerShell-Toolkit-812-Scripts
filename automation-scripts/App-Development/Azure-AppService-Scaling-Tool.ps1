# ============================================================================
# Script Name: Azure App Service Scaling Automation Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Automates scaling of Azure App Service Plans by adjusting instance count
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$PlanName,
    [int]$InstanceCount
)

Set-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $PlanName -NumberofWorkers $InstanceCount
