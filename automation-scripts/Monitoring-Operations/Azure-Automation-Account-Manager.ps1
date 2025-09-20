#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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

