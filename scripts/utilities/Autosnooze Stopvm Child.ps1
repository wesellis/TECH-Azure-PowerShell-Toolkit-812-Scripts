#Requires -Version 7.4
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    AutoSnooze Stop VM Child

.DESCRIPTION
    Azure automation webhook-triggered runbook for stopping VMs based on AutoSnooze alerts

.PARAMETER WebhookData
    Webhook data containing alert context information

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    This runbook is meant to be triggered by a webhook from Azure Monitor alerts
#>

[CmdletBinding()]
param(
    [Parameter()]
    [object]$WebhookData,

    [Parameter()]
    [string]$ConnectionName = "AzureRunAsConnection"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# Validate webhook data
if ($null -eq $WebhookData) {
    Write-Error "This runbook is meant to only be started from a webhook. No webhook data received."
    throw "No webhook data provided"
}

try {
    # Parse webhook data
    $webhookName = $WebhookData.WebhookName
    Write-Output "This runbook was started from webhook: $webhookName"

    # Parse webhook body
    if ($WebhookData.RequestBody -is [string]) {
        $webhookBody = ConvertFrom-Json -InputObject $WebhookData.RequestBody
    } else {
        $webhookBody = $WebhookData.RequestBody
    }

    Write-Output "`nWEBHOOK BODY"
    Write-Output "============="
    Write-Output ($webhookBody | ConvertTo-Json -Depth 10)

    # Extract alert context
    $alertContext = $webhookBody.context
    if ($null -eq $alertContext) {
        # Try alternative schema for newer alerts
        $alertContext = $webhookBody.data.context
    }

    if ($null -eq $alertContext) {
        throw "Unable to extract alert context from webhook body"
    }

    Write-Output "`nALERT CONTEXT DATA"
    Write-Output "=================="
    Write-Output "Alert Name: $($alertContext.name)"
    Write-Output "Subscription ID: $($alertContext.subscriptionId)"
    Write-Output "Resource Group: $($alertContext.resourceGroupName)"
    Write-Output "Resource Name: $($alertContext.resourceName)"
    Write-Output "Resource Type: $($alertContext.resourceType)"
    Write-Output "Resource ID: $($alertContext.resourceId)"
    Write-Output "Timestamp: $($alertContext.timestamp)"

    # Validate required alert context fields
    if ([string]::IsNullOrEmpty($alertContext.resourceName)) {
        throw "Resource name not found in alert context"
    }

    if ([string]::IsNullOrEmpty($alertContext.resourceGroupName)) {
        throw "Resource group name not found in alert context"
    }

    # Connect to Azure using Run As Connection
    try {
        $servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName -ErrorAction Stop
        Write-Output "Logging in to Azure using service principal..."

        $connectParams = @{
            ApplicationId = $servicePrincipalConnection.ApplicationId
            TenantId = $servicePrincipalConnection.TenantId
            CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
        }

        Connect-AzAccount -ServicePrincipal @connectParams -ErrorAction Stop
        Write-Output "Successfully connected to Azure"

        # Set subscription context if provided
        if (![string]::IsNullOrEmpty($alertContext.subscriptionId)) {
            Set-AzContext -SubscriptionId $alertContext.subscriptionId -ErrorAction Stop
            Write-Output "Set subscription context to: $($alertContext.subscriptionId)"
        }
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

    # Get VM status before stopping
    Write-Output "`nChecking VM status before stopping..."
    $vm = Get-AzVM -ResourceGroupName $alertContext.resourceGroupName -Name $alertContext.resourceName -Status -ErrorAction Stop
    $vmStatus = $vm.Statuses | Where-Object { $_.Code -like "PowerState/*" } | Select-Object -ExpandProperty DisplayStatus

    Write-Output "Current VM status: $vmStatus"

    if ($vmStatus -eq "VM running") {
        # Stop the VM
        Write-Output "Stopping VM: $($alertContext.resourceName) in resource group: $($alertContext.resourceGroupName)"

        $stopResult = Stop-AzVM -ResourceGroupName $alertContext.resourceGroupName `
                                -Name $alertContext.resourceName `
                                -Force `
                                -ErrorAction Stop

        if ($stopResult.Status -eq "Succeeded") {
            Write-Output "Successfully stopped VM: $($alertContext.resourceName)"

            # Verify VM is stopped
            Start-Sleep -Seconds 10
            $vmAfter = Get-AzVM -ResourceGroupName $alertContext.resourceGroupName -Name $alertContext.resourceName -Status -ErrorAction Stop
            $vmStatusAfter = $vmAfter.Statuses | Where-Object { $_.Code -like "PowerState/*" } | Select-Object -ExpandProperty DisplayStatus

            Write-Output "VM status after stop operation: $vmStatusAfter"
        } else {
            Write-Warning "Stop operation did not succeed. Status: $($stopResult.Status)"
            Write-Warning "Error: $($stopResult.Error)"
        }
    }
    else {
        Write-Output "VM is not in running state (current state: $vmStatus). Skipping stop operation."
    }

    Write-Output "`nAutoSnooze Stop VM operation completed"
}
catch {
    Write-Error "Error occurred in AutoSnooze Stop VM Child runbook: $($_.Exception.Message)"
    Write-Error "Stack Trace: $($_.ScriptStackTrace)"
    throw
}