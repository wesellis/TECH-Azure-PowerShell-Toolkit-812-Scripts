#Requires -Version 7.4
#Requires -Modules Az.Automation, Az.Accounts

<#
.SYNOPSIS
    Disables all ARO (Azure Resource Optimization) toolkit optimizations

.DESCRIPTION
    This script disables all Azure automation schedules and optimizations related to the ARO toolkit.
    It connects to Azure using a service principal and disables schedules for AutoUpdate, SequencedSnooze,
    ScheduledSnooze, and AutoSnooze features.

.PARAMETER ConnectionName
    The name of the Azure Automation connection to use. Defaults to "AzureRunAsConnection"

.EXAMPLE
    .\Disablealloptimizations.ps1
    Disables all ARO toolkit optimizations using the default connection

.EXAMPLE
    .\Disablealloptimizations.ps1 -ConnectionName "MyConnection"
    Disables all ARO toolkit optimizations using a custom connection

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    2.0

.NOTES
    Requires appropriate permissions and modules
    Updated to use modern Az PowerShell modules
    Version History:
    v1.0 - Initial Release
    v2.0 - Updated to use Az modules instead of deprecated AzureRM
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ConnectionName = "AzureRunAsConnection"
)

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Retrieving Azure Automation connection: $ConnectionName"
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName

    Write-Output "Logging in to Azure using service principal..."
    $connectParams = @{
        ApplicationId         = $ServicePrincipalConnection.ApplicationId
        TenantId             = $ServicePrincipalConnection.TenantId
        CertificateThumbprint = $ServicePrincipalConnection.CertificateThumbprint
        ServicePrincipal     = $true
    }
    Connect-AzAccount @connectParams | Out-Null
    Write-Output "Successfully connected to Azure"
}
catch {
    if (!$ServicePrincipalConnection) {
        $ErrorMessage = "Connection '$ConnectionName' not found."
        Write-Error $ErrorMessage
        throw $ErrorMessage
    }
    else {
        Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
        throw $_.Exception
    }
}

try {
    Write-Output "Starting ARO Toolkit emergency disable procedure..."
    Write-Output "Retrieving automation variables..."

    $SubId = Get-AutomationVariable -Name 'Internal_AzureSubscriptionId'
    $ResourceGroupNames = Get-AutomationVariable -Name 'External_ResourceGroupNames'
    $AutomationAccountName = Get-AutomationVariable -Name 'Internal_AROautomationAccountName'
    $AroResourceGroupName = Get-AutomationVariable -Name 'Internal_AROResourceGroupName'

    Write-Output "Setting Azure context to subscription: $SubId"
    Set-AzContext -SubscriptionId $SubId | Out-Null

    # Disable AutoUpdate schedule
    $AutoUpdate = "Schedule_AROToolkit_AutoUpdate"
    Write-Output "Disabling schedule: $AutoUpdate"
    try {
        Set-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $AutoUpdate -ResourceGroupName $AroResourceGroupName -IsEnabled $false
        Write-Output "Successfully disabled $AutoUpdate"
    }
    catch {
        Write-Warning "Failed to disable $AutoUpdate : $($_.Exception.Message)"
    }

    # Disable SequencedSnooze schedules
    $SequencedStart = "SequencedSnooze-StartVM"
    $SequencedStop = "SequencedSnooze-StopVM"
    Write-Output "Disabling SequencedSnooze schedules..."

    try {
        Set-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $SequencedStart -ResourceGroupName $AroResourceGroupName -IsEnabled $false
        Write-Output "Successfully disabled $SequencedStart"
    }
    catch {
        Write-Warning "Failed to disable $SequencedStart : $($_.Exception.Message)"
    }

    try {
        Set-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $SequencedStop -ResourceGroupName $AroResourceGroupName -IsEnabled $false
        Write-Output "Successfully disabled $SequencedStop"
    }
    catch {
        Write-Warning "Failed to disable $SequencedStop : $($_.Exception.Message)"
    }

    # Disable ScheduledSnooze schedules
    $ScheduleStart = "ScheduledSnooze-StartVM"
    $ScheduleStop = "ScheduledSnooze-StopVM"
    Write-Output "Disabling ScheduledSnooze schedules..."

    try {
        Set-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $ScheduleStart -ResourceGroupName $AroResourceGroupName -IsEnabled $false
        Write-Output "Successfully disabled $ScheduleStart"
    }
    catch {
        Write-Warning "Failed to disable $ScheduleStart : $($_.Exception.Message)"
    }

    try {
        Set-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -Name $ScheduleStop -ResourceGroupName $AroResourceGroupName -IsEnabled $false
        Write-Output "Successfully disabled $ScheduleStop"
    }
    catch {
        Write-Warning "Failed to disable $ScheduleStop : $($_.Exception.Message)"
    }

    # Disable AutoSnooze
    Write-Output "Disabling AutoSnooze schedules and alerts..."
    try {
        Start-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name 'AutoSnooze_Disable' -ResourceGroupName $AroResourceGroupName -Wait
        Write-Output "Successfully executed AutoSnooze_Disable runbook"
    }
    catch {
        Write-Warning "Failed to execute AutoSnooze_Disable runbook: $($_.Exception.Message)"
    }

    Write-Output "ARO Toolkit emergency disable procedure completed successfully"
}
catch {
    Write-Error "Error occurred during ARO Toolkit disable procedure: $($_.Exception.Message)"
    throw $_.Exception
}
