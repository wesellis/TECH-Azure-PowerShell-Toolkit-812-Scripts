# ============================================================================
# Script Name: Azure Automation Account Management Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Manages Azure Automation Accounts including status, runbooks, and configurations
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AccountName
)

# Get automation account details
$AutomationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AccountName

Write-Information "Automation Account: $($AutomationAccount.AutomationAccountName)"
Write-Information "Resource Group: $($AutomationAccount.ResourceGroupName)"
Write-Information "Location: $($AutomationAccount.Location)"
Write-Information "State: $($AutomationAccount.State)"
Write-Information "Creation Time: $($AutomationAccount.CreationTime)"
Write-Information "Last Modified: $($AutomationAccount.LastModifiedTime)"
