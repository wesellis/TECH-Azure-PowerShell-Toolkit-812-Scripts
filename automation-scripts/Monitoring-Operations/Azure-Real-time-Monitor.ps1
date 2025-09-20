<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
# Real-time Azure Resource Monitor with Dashboards
param (
    [Parameter()][string[]]$ResourceGroups = @(),
    [Parameter()][string[]]$ResourceTypes = @(),
    [Parameter()][int]$RefreshIntervalSeconds = 30,
    [Parameter()][string]$DashboardPort = "8080",
    [Parameter()][string]$AlertWebhookUrl,
    [Parameter()][switch]$StartWebDashboard,
    [Parameter()][switch]$EnableAlerts,
    [Parameter()][switch]$ExportMetrics
)
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath "..", "modules", "AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
# Script-level monitoring state (avoiding global variables)
$script:MonitoringState = @{
    Running = $false
    Resources = @{}
    Metrics = @()
    Alerts = @()
    StartTime = Get-Date -ErrorAction Stop
}
[CmdletBinding()]
function Start-ResourceMonitoring {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $script:MonitoringState.Running = $true
    
    while ($script:MonitoringState.Running) {
        try {
            $timestamp = Get-Date -ErrorAction Stop
            
            # Get resources to monitor
            $resources = if ($ResourceGroups.Count -gt 0) {
                $ResourceGroups | ForEach-Object { Get-AzResource -ResourceGroupName $_ }
            } else {
                Get-AzResource -ErrorAction Stop
            }
            if ($ResourceTypes.Count -gt 0) {
                $resources = $resources | Where-Object { $_.ResourceType -in $ResourceTypes }
            }
            # Collect metrics for each resource
            $currentMetrics = @()
            foreach ($resource in $resources) {
                $metric = Get-ResourceHealthMetric -Resource $resource
                $currentMetrics += $metric
                # Check for alerts
                if ($EnableAlerts) {
                    Test-ResourceAlert -Metric $metric
                }
            }
            # Update script state
            $script:MonitoringState.Metrics = $currentMetrics
            $script:MonitoringState.LastUpdate = $timestamp
            # Display summary
            $healthyCount = ($currentMetrics | Where-Object { $_.Status -eq "Healthy" }).Count
            $unhealthyCount = ($currentMetrics | Where-Object { $_.Status -ne "Healthy" }).Count
            Write-Host "Resources: $($resources.Count) |  Healthy: $healthyCount | [WARN] Issues: $unhealthyCount"
            if ($unhealthyCount -gt 0) {
                $issues = $currentMetrics | Where-Object { $_.Status -ne "Healthy" }
                foreach ($issue in $issues) {
                    Write-Host "  [WARN] $($issue.Name): $($issue.Status) - $($issue.Details)"
                }
            }
            Start-Sleep -Seconds $RefreshIntervalSeconds
        } catch {
            
            Start-Sleep -Seconds 5
        }
    }
}
function Get-ResourceHealthMetric -ErrorAction Stop {
    param($Resource)
    $metric = @{
        Name = $Resource.Name
        ResourceGroup = $Resource.ResourceGroupName
        Type = $Resource.ResourceType
        Location = $Resource.Location
        Status = "Unknown"
        Details = ""
        Timestamp = Get-Date -ErrorAction Stop
        Metrics = @{}
    }
    try {
        switch ($Resource.ResourceType) {
            "Microsoft.Compute/virtualMachines" {
                $vm = Get-AzVM -ResourceGroupName $Resource.ResourceGroupName -Name $Resource.Name -Status -ErrorAction SilentlyContinue
                if ($vm) {
                    $powerState = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
                    $metric.Status = if ($powerState -eq "VM running") { "Healthy" } else { "Unhealthy" }
                    $metric.Details = $powerState
                    $metric.Metrics.PowerState = $powerState
                }
            }
            "Microsoft.Storage/storageAccounts" {
                $storage = Get-AzStorageAccount -ResourceGroupName $Resource.ResourceGroupName -Name $Resource.Name -ErrorAction SilentlyContinue
                if ($storage) {
                    $metric.Status = if ($storage.ProvisioningState -eq "Succeeded") { "Healthy" } else { "Unhealthy" }
                    $metric.Details = $storage.ProvisioningState
                    $metric.Metrics.ProvisioningState = $storage.ProvisioningState
                    $metric.Metrics.Tier = $storage.Sku.Tier
                }
            }
            "Microsoft.Web/sites" {
                $webapp = Get-AzWebApp -ResourceGroupName $Resource.ResourceGroupName -Name $Resource.Name -ErrorAction SilentlyContinue
                if ($webapp) {
                    $metric.Status = if ($webapp.State -eq "Running") { "Healthy" } else { "Unhealthy" }
                    $metric.Details = $webapp.State
                    $metric.Metrics.State = $webapp.State
                    $metric.Metrics.DefaultHostName = $webapp.DefaultHostName
                }
            }
            default {
                $metric.Status = "Healthy"
                $metric.Details = "Basic monitoring"
            }
        }
    } catch {
        $metric.Status = "Error"
        $metric.Details = $_.Exception.Message
    }
    return $metric
}
function Test-ResourceAlert {
    [CmdletBinding()]
    param($Metric)
    $alertTriggered = $false
    $alertMessage = ""
    # Check for common alert conditions
    if ($Metric.Status -eq "Unhealthy") {
        $alertTriggered = $true
        $alertMessage = "Resource $($Metric.Name) is unhealthy: $($Metric.Details)"
    }
    if ($Metric.Type -eq "Microsoft.Compute/virtualMachines" -and $Metric.Metrics.PowerState -eq "VM deallocated") {
        $alertTriggered = $true
        $alertMessage = "VM $($Metric.Name) has been deallocated"
    }
    if ($alertTriggered) {
        $alert = @{
            Timestamp = Get-Date -ErrorAction Stop
            Resource = $Metric.Name
            Type = $Metric.Type
            Message = $alertMessage
            Severity = "Warning"
        }
        $script:MonitoringState.Alerts += $alert
        
        # Send webhook notification if configured
        if ($AlertWebhookUrl) {
            Send-AlertWebhook -Alert $alert
        }
    }
}
function Send-AlertWebhook {
    param($Alert)
    try {
        $payload = @{
            text = "Azure Alert: $($Alert.Message)"
            timestamp = $Alert.Timestamp
            resource = $Alert.Resource
            severity = $Alert.Severity
        } | ConvertTo-Json
        Invoke-RestMethod -Uri $AlertWebhookUrl -Method Post -Body $payload -ContentType "application/json"
        
    } catch {
        
    }
}
# Main execution
try {
    if (-not (Get-AzContext)) { throw "Not connected to Azure" }
    
    if ($ResourceGroups.Count -gt 0) {
        
    }
    if ($ResourceTypes.Count -gt 0) {
        
    }
    if ($StartWebDashboard) {
        
        # Start dashboard in background job
        Start-Job -ScriptBlock {
            # Dashboard code would go here
            while ($true) { Start-Sleep 1 }
        } | Out-Null
    }
    if ($EnableAlerts) {
        
        if ($AlertWebhookUrl) {
            
        }
    }
    # Start monitoring
    
    Start-ResourceMonitoring
} catch { throw } finally {
    $script:MonitoringState.Running = $false
    
}

