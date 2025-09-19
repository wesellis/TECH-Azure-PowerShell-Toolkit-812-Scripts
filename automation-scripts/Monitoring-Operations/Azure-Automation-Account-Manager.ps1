#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$ResourceGroupName,
    [string]$AccountName
)

#region Functions

# Get automation account details
$AutomationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AccountName

Write-Information "Automation Account: $($AutomationAccount.AutomationAccountName)"
Write-Information "Resource Group: $($AutomationAccount.ResourceGroupName)"
Write-Information "Location: $($AutomationAccount.Location)"
Write-Information "State: $($AutomationAccount.State)"
Write-Information "Creation Time: $($AutomationAccount.CreationTime)"
Write-Information "Last Modified: $($AutomationAccount.LastModifiedTime)"


#endregion
