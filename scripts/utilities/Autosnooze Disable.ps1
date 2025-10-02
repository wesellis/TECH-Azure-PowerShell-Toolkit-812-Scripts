#Requires -Version 7.4
#Requires -Modules Az.Automation, Az.Monitor

<#
.SYNOPSIS
    Disable AutoSnooze feature

.DESCRIPTION
    Azure automation runbook to disable AutoSnooze feature for virtual machines

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AutomationAccountName,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter()]
    [string]$ConnectionName = "AzureRunAsConnection",

    [Parameter()]
    [string[]]$VMResourceGroupNames,

    [Parameter()]
    [string]$WebhookUri
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    # Connect to Azure using Run As Connection
    $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName -ErrorAction Stop
    Write-Output "Logging in to Azure using service principal..."

    $connectParams = @{
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }

    Connect-AzAccount -ServicePrincipal @connectParams -ErrorAction Stop
    Write-Output "Successfully connected to Azure"
}
catch {
    if (!$servicePrincipalConnection) {
        $errorMessage = "Connection '$ConnectionName' not found."
        Write-Error -Message $errorMessage
        throw $errorMessage
    } else {
        Write-Error -Message "Failed to connect to Azure: $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Output "Performing AutoSnooze disable operation..."

    # Disable AutoSnooze schedule
    $scheduleNameForCreateAlert = "Schedule_AutoSnooze_CreateAlert_Parent"
    Write-Output "Disabling schedule: $scheduleNameForCreateAlert"

    try {
        $schedule = Get-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $scheduleNameForCreateAlert -ErrorAction Stop
        Set-AzAutomationSchedule -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $scheduleNameForCreateAlert -IsEnabled $false -ErrorAction Stop
        Write-Output "Successfully disabled schedule: $scheduleNameForCreateAlert"
    }
    catch {
        Write-Warning "Failed to disable schedule '$scheduleNameForCreateAlert': $($_.Exception.Message)"
    }

    # Get list of VMs to process
    $azureVMList = @()

    if ($VMResourceGroupNames -and $VMResourceGroupNames.Count -gt 0) {
        foreach ($resourceGroupName in $VMResourceGroupNames) {
            $trimmedRGName = $resourceGroupName.Trim()
            Write-Output "Processing resource group: $trimmedRGName"

            try {
                $checkRGName = Get-AzResourceGroup -Name $trimmedRGName -ErrorAction Stop
                $vms = Get-AzVM -ResourceGroupName $trimmedRGName -ErrorAction SilentlyContinue

                if ($vms) {
                    $azureVMList += $vms
                    Write-Output "Found $($vms.Count) VMs in resource group: $trimmedRGName"
                }
            }
            catch {
                Write-Warning "Resource group '$trimmedRGName' not found or inaccessible: $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Output "Getting all VMs from the subscription..."
        $azureVMList = Get-AzVM -ErrorAction SilentlyContinue
    }

    Write-Output "Found $($azureVMList.Count) VMs to process for AutoSnooze disable"

    # Disable alerts for each VM
    $successCount = 0
    $failureCount = 0

    foreach ($vm in $azureVMList) {
        try {
            Write-Output "Disabling AutoSnooze alert for VM: $($vm.Name)"

            $runbookParams = @{
                "VMObject" = $vm
                "AlertAction" = "Disable"
                "WebhookUri" = $WebhookUri
            }

            $job = Start-AzAutomationRunbook -AutomationAccountName $AutomationAccountName -Name 'AutoSnooze_CreateAlert_Child' -ResourceGroupName $ResourceGroupName -Parameters $runbookParams -ErrorAction Stop

            Write-Output "Started child runbook for VM: $($vm.Name), Job ID: $($job.JobId)"
            $successCount++
        }
        catch {
            Write-Warning "Failed to disable alert for VM '$($vm.Name)': $($_.Exception.Message)"
            $failureCount++
        }
    }

    Write-Output "AutoSnooze disable operation completed"
    Write-Output "Success: $successCount VMs, Failures: $failureCount VMs"
}
catch {
    Write-Error "Error occurred during AutoSnooze disable operation: $($_.Exception.Message)"
    throw
}