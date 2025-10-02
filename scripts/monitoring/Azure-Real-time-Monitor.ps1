#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]
param(
    [Parameter()][string[]]$ResourceGroups = @(),
    [Parameter()][string[]]$ResourceTypes = @(),
    [Parameter()][int]$RefreshIntervalSeconds = 30,
    [Parameter()][string]$DashboardPort = "8080",
    [Parameter()][string]$AlertWebhookUrl,
    [Parameter()][switch]$StartWebDashboard,
    [Parameter()][switch]$EnableAlerts,
    [Parameter()][switch]$ExportMetrics
)
    [string]$ErrorActionPreference = 'Stop'
    [string]$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath "..", "modules", "AzureAutomationCommon"
if (Test-Path $ModulePath) {
    [string]$script:MonitoringState = @{
    Running = $false
    Resources = @{}
    Metrics = @()
    Alerts = @()
    StartTime = Get-Date -ErrorAction Stop
}
function Write-Log {
    param()
    [string]$script:MonitoringState.Running = $true

    while ($script:MonitoringState.Running) {
        try {
    [string]$timestamp = Get-Date -ErrorAction Stop
    [string]$resources = if ($ResourceGroups.Count -gt 0) {
    [string]$ResourceGroups | ForEach-Object { Get-AzResource -ResourceGroupName $_ }
            } else {
                Get-AzResource -ErrorAction Stop
            }
            if ($ResourceTypes.Count -gt 0) {
    [string]$resources = $resources | Where-Object { $_.ResourceType -in $ResourceTypes }
            }
    [string]$CurrentMetrics = @()
            foreach ($resource in $resources) {
    [string]$metric = Get-ResourceHealthMetric -Resource $resource
    [string]$CurrentMetrics += $metric
                if ($EnableAlerts) {
                    Test-ResourceAlert -Metric $metric
                }
            }
    [string]$script:MonitoringState.Metrics = $CurrentMetrics
    [string]$script:MonitoringState.LastUpdate = $timestamp
    [string]$HealthyCount = ($CurrentMetrics | Where-Object { $_.Status -eq "Healthy" }).Count
    [string]$UnhealthyCount = ($CurrentMetrics | Where-Object { $_.Status -ne "Healthy" }).Count
            Write-Output "Resources: $($resources.Count) |  Healthy: $HealthyCount | [WARN] Issues: $UnhealthyCount"
            if ($UnhealthyCount -gt 0) {
    [string]$issues = $CurrentMetrics | Where-Object { $_.Status -ne "Healthy" }
                foreach ($issue in $issues) {
                    Write-Output "  [WARN] $($issue.Name): $($issue.Status) - $($issue.Details)"
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
    $VmSplat = @{
    ResourceGroupName = $Resource.ResourceGroupName
    Name = $Resource.Name
    ErrorAction = SilentlyContinue
}
Get-AzVM @vmSplat
                if ($vm) {
    [string]$PowerState = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
    [string]$metric.Status = if ($PowerState -eq "VM running") { "Healthy" } else { "Unhealthy" }
    [string]$metric.Details = $PowerState
    [string]$metric.Metrics.PowerState = $PowerState
                }
            }
            "Microsoft.Storage/storageAccounts" {
    [string]$storage = Get-AzStorageAccount -ResourceGroupName $Resource.ResourceGroupName -Name $Resource.Name -ErrorAction SilentlyContinue
                if ($storage) {
    [string]$metric.Status = if ($storage.ProvisioningState -eq "Succeeded") { "Healthy" } else { "Unhealthy" }
    [string]$metric.Details = $storage.ProvisioningState
    [string]$metric.Metrics.ProvisioningState = $storage.ProvisioningState
    [string]$metric.Metrics.Tier = $storage.Sku.Tier
                }
            }
            "Microsoft.Web/sites" {
    [string]$webapp = Get-AzWebApp -ResourceGroupName $Resource.ResourceGroupName -Name $Resource.Name -ErrorAction SilentlyContinue
                if ($webapp) {
    [string]$metric.Status = if ($webapp.State -eq "Running") { "Healthy" } else { "Unhealthy" }
    [string]$metric.Details = $webapp.State
    [string]$metric.Metrics.State = $webapp.State
    [string]$metric.Metrics.DefaultHostName = $webapp.DefaultHostName
                }
            }
            default {
    [string]$metric.Status = "Healthy"
    [string]$metric.Details = "Basic monitoring"
            }
        }
    } catch {
    [string]$metric.Status = "Error"
    [string]$metric.Details = $_.Exception.Message
    }
    return $metric
}
function Test-ResourceAlert {
    param($Metric)
    [string]$AlertTriggered = $false
    [string]$AlertMessage = ""
    if ($Metric.Status -eq "Unhealthy") {
    [string]$AlertTriggered = $true
    [string]$AlertMessage = "Resource $($Metric.Name) is unhealthy: $($Metric.Details)"
    }
    if ($Metric.Type -eq "Microsoft.Compute/virtualMachines" -and $Metric.Metrics.PowerState -eq "VM deallocated") {
    [string]$AlertTriggered = $true
    [string]$AlertMessage = "VM $($Metric.Name) has been deallocated"
    }
    if ($AlertTriggered) {
    $alert = @{
            Timestamp = Get-Date -ErrorAction Stop
            Resource = $Metric.Name
            Type = $Metric.Type
            Message = $AlertMessage
            Severity = "Warning"
        }
    [string]$script:MonitoringState.Alerts += $alert

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
try {
    if (-not (Get-AzContext)) { throw "Not connected to Azure" }

    if ($ResourceGroups.Count -gt 0) {

    }
    if ($ResourceTypes.Count -gt 0) {

    }
    if ($StartWebDashboard) {

        Start-Job -ScriptBlock {
            while ($true) { Start-Sleep 1 }
        } | Out-Null
    }
    if ($EnableAlerts) {

        if ($AlertWebhookUrl) {

        }
    }

    Start-ResourceMonitoring
} catch { throw } finally {
    [string]$script:MonitoringState.Running = $false`n}
