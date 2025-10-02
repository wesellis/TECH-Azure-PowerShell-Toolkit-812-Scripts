#Requires -Version 7.4
#Requires -Modules Az.Monitor, Az.Compute

<#
.SYNOPSIS
    AutoSnooze Create Alert Child

.DESCRIPTION
    Azure automation child runbook for creating or disabling AutoSnooze alerts for individual VMs

.PARAMETER VMObject
    The VM object to process

.PARAMETER AlertAction
    Action to perform - Create or Disable

.PARAMETER WebhookUri
    Webhook URI for alert notifications

.PARAMETER Threshold
    CPU threshold for alert

.PARAMETER MetricName
    Metric to monitor (default: Percentage CPU)

.PARAMETER TimeWindow
    Time window for metric evaluation

.PARAMETER Condition
    Condition operator (LessThan, LessThanOrEqual, GreaterThan, GreaterThanOrEqual)

.PARAMETER TimeAggregationOperator
    Time aggregation operator (Average, Minimum, Maximum, Total)

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [object]$VMObject,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Create', 'Disable')]
    [string]$AlertAction,

    [Parameter()]
    [string]$WebhookUri,

    [Parameter()]
    [int]$Threshold = 5,

    [Parameter()]
    [string]$MetricName = "Percentage CPU",

    [Parameter()]
    [timespan]$TimeWindow = [timespan]::FromMinutes(30),

    [Parameter()]
    [ValidateSet('LessThan', 'LessThanOrEqual', 'GreaterThan', 'GreaterThanOrEqual')]
    [string]$Condition = 'LessThan',

    [Parameter()]
    [ValidateSet('Average', 'Minimum', 'Maximum', 'Total')]
    [string]$TimeAggregationOperator = 'Average',

    [Parameter()]
    [string]$Description = "AutoSnooze alert for VM shutdown based on CPU usage",

    [Parameter()]
    [string]$ConnectionName = "AzureRunAsConnection"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Get-NextAlertName {
    param(
        [string]$OldAlertName,
        [string]$VMName
    )

    if ($OldAlertName -match "Alert-.*-(\d+)$") {
        $number = [int]$matches[1] + 1
        return "Alert-$VMName-$number"
    }
    return "Alert-$VMName-1"
}

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
    $resourceGroupName = $VMObject.ResourceGroupName
    $location = $VMObject.Location
    $vmName = $VMObject.Name.Trim()

    # Get current VM state
    $vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Status -ErrorAction SilentlyContinue
    $vmState = $vm.Statuses | Where-Object { $_.Code -like "PowerState/*" } | Select-Object -ExpandProperty Code

    Write-Output "Processing VM: $vmName"
    Write-Output "Current VM state: $vmState"

    # Build resource ID for the VM
    $subscription = (Get-AzContext).Subscription.Id
    $resourceId = "/subscriptions/$subscription/resourceGroups/$resourceGroupName/providers/Microsoft.Compute/virtualMachines/$vmName"

    if ($AlertAction -eq "Disable") {
        Write-Output "Disabling alerts for VM: $vmName"

        # Get existing alerts
        $existingAlerts = Get-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "*$vmName*" }

        foreach ($alert in $existingAlerts) {
            Write-Output "Disabling alert: $($alert.Name)"
            $alert.Enabled = $false
            Set-AzMetricAlertRuleV2 -InputObject $alert -ErrorAction Stop
            Write-Output "Alert '$($alert.Name)' disabled for VM: $vmName"
        }
    }
    elseif ($AlertAction -eq "Create") {
        if ($vmState -eq 'PowerState/running') {
            Write-Output "Creating alert for running VM: $vmName"

            # Remove existing alerts for this VM
            $existingAlerts = Get-AzMetricAlertRuleV2 -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like "*$vmName*" }

            $alertName = "Alert-$vmName-1"

            foreach ($alert in $existingAlerts) {
                Write-Output "Removing existing alert: $($alert.Name)"
                Remove-AzMetricAlertRuleV2 -Name $alert.Name -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                $alertName = Get-NextAlertName -OldAlertName $alert.Name -VMName $vmName
            }

            Write-Output "Creating new alert: $alertName"

            # Create metric criteria
            $criteria = New-AzMetricAlertRuleV2Criteria -MetricName $MetricName `
                -DimensionSelection @() `
                -Operator $Condition `
                -Threshold $Threshold `
                -TimeAggregation $TimeAggregationOperator

            # Create action group if webhook is provided
            $actionGroups = @()
            if ($WebhookUri) {
                $actionGroupName = "AG-$vmName"
                $actionGroupShortName = "AG$(($vmName -replace '[^a-zA-Z0-9]', '').Substring(0, [Math]::Min(10, ($vmName -replace '[^a-zA-Z0-9]', '').Length)))"

                $webhookReceiver = New-AzActionGroupWebhookReceiverObject -Name "AutoSnooze" -ServiceUri $WebhookUri

                $actionGroup = Set-AzActionGroup -Name $actionGroupName `
                    -ResourceGroupName $resourceGroupName `
                    -ShortName $actionGroupShortName `
                    -WebhookReceiver $webhookReceiver `
                    -Location "Global" `
                    -ErrorAction SilentlyContinue

                if (!$actionGroup) {
                    $actionGroup = New-AzActionGroup -Name $actionGroupName `
                        -ResourceGroupName $resourceGroupName `
                        -ShortName $actionGroupShortName `
                        -WebhookReceiver $webhookReceiver `
                        -Location "Global" `
                        -ErrorAction Stop
                }

                $actionGroups = @($actionGroup.Id)
            }

            # Create the alert rule
            Add-AzMetricAlertRuleV2 -Name $alertName `
                -ResourceGroupName $resourceGroupName `
                -TargetResourceId $resourceId `
                -Description $Description `
                -Severity 3 `
                -WindowSize $TimeWindow `
                -Frequency ([timespan]::FromMinutes(5)) `
                -Criteria $criteria `
                -ActionGroupId $actionGroups `
                -ErrorAction Stop

            Write-Output "Alert '$alertName' created for VM: $vmName"
        }
        else {
            Write-Output "VM '$vmName' is not running (state: $vmState). Skipping alert creation."
        }
    }
}
catch {
    Write-Error "Error processing VM '$($VMObject.Name)': $($_.Exception.Message)"
    throw
}