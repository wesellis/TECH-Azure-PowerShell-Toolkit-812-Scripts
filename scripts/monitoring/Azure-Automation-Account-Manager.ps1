#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$AccountName
)
$AutomationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroupName -Name $AccountName
Write-Output "Automation Account: $($AutomationAccount.AutomationAccountName)"
Write-Output "Resource Group: $($AutomationAccount.ResourceGroupName)"
Write-Output "Location: $($AutomationAccount.Location)"
Write-Output "State: $($AutomationAccount.State)"
Write-Output "Creation Time: $($AutomationAccount.CreationTime)"
Write-Output "Last Modified: $($AutomationAccount.LastModifiedTime)"



