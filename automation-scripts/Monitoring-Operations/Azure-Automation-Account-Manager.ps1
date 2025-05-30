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

Write-Host "Automation Account: $($AutomationAccount.AutomationAccountName)"
Write-Host "Resource Group: $($AutomationAccount.ResourceGroupName)"
Write-Host "Location: $($AutomationAccount.Location)"
Write-Host "State: $($AutomationAccount.State)"
Write-Host "Creation Time: $($AutomationAccount.CreationTime)"
Write-Host "Last Modified: $($AutomationAccount.LastModifiedTime)"
