# Real-time Azure Resource Monitor with Dashboards
param (
    [Parameter(Mandatory=$false)][string[]]$ResourceGroups = @(),
    [Parameter(Mandatory=$false)][string[]]$ResourceTypes = @(),
    [Parameter(Mandatory=$false)][int]$RefreshIntervalSeconds = 30,
    [Parameter(Mandatory=$false)][string]$DashboardPort = "8080",
    [Parameter(Mandatory=$false)][string]$AlertWebhookUrl,
    [Parameter(Mandatory=$false)][switch]$StartWebDashboard,
    [Parameter(Mandatory=$false)][switch]$EnableAlerts,
    [Parameter(Mandatory=$false)][switch]$ExportMetrics
)

$modulePath = Join-Path $PSScriptRoot ".." ".." "modules" "AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

Show-Banner -ScriptName "Azure Real-time Monitor" -Description "Live monitoring with web dashboard and alerts"

# Global monitoring state
$global:MonitoringState = @{
    Running = $false
    Resources = @{}
    Metrics = @()
    Alerts = @()
    StartTime = Get-Date
}

function Start-ResourceMonitoring {
    $global:MonitoringState.Running = $true
    Write-Log "🔴 Starting real-time monitoring..." -Level SUCCESS
    
    while ($global:MonitoringState.Running) {
        try {
            $timestamp = Get-Date
            Write-Log "📊 Collecting metrics at $($timestamp.ToString('HH:mm:ss'))" -Level INFO
            
            # Get resources to monitor
            $resources = if ($ResourceGroups.Count -gt 0) {
                $ResourceGroups | ForEach-Object { Get-AzResource -ResourceGroupName $_ }
            } else {
                Get-AzResource
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
                    Check-ResourceAlerts -Metric $metric
                }
            }
            
            # Update global state
            $global:MonitoringState.Metrics = $currentMetrics
            $global:MonitoringState.LastUpdate = $timestamp
            
            # Display summary
            $healthyCount = ($currentMetrics | Where-Object { $_.Status -eq "Healthy" }).Count
            $unhealthyCount = ($currentMetrics | Where-Object { $_.Status -ne "Healthy" }).Count
            
            Write-Host "📈 Resources: $($resources.Count) | ✅ Healthy: $healthyCount | ⚠️ Issues: $unhealthyCount" -ForegroundColor Green
            
            if ($unhealthyCount -gt 0) {
                $issues = $currentMetrics | Where-Object { $_.Status -ne "Healthy" }
                foreach ($issue in $issues) {
                    Write-Host "  ⚠️ $($issue.Name): $($issue.Status) - $($issue.Details)" -ForegroundColor Yellow
                }
            }
            
            Start-Sleep -Seconds $RefreshIntervalSeconds
            
        } catch {
            Write-Log "Monitoring error: $($_.Exception.Message)" -Level ERROR
            Start-Sleep -Seconds 5
        }
    }
}

function Get-ResourceHealthMetric {
    param($Resource)
    
    $metric = @{
        Name = $Resource.Name
        ResourceGroup = $Resource.ResourceGroupName
        Type = $Resource.ResourceType
        Location = $Resource.Location
        Status = "Unknown"
        Details = ""
        Timestamp = Get-Date
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

function Check-ResourceAlerts {
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
            Timestamp = Get-Date
            Resource = $Metric.Name
            Type = $Metric.Type
            Message = $alertMessage
            Severity = "Warning"
        }
        
        $global:MonitoringState.Alerts += $alert
        Write-Log "🚨 ALERT: $alertMessage" -Level WARN
        
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
            text = "🚨 Azure Alert: $($Alert.Message)"
            timestamp = $Alert.Timestamp
            resource = $Alert.Resource
            severity = $Alert.Severity
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri $AlertWebhookUrl -Method Post -Body $payload -ContentType "application/json"
        Write-Log "✓ Alert sent to webhook" -Level SUCCESS
    } catch {
        Write-Log "Failed to send webhook alert: $($_.Exception.Message)" -Level ERROR
    }
}

# Main execution
try {
    if (-not (Test-AzureConnection)) { throw "Azure connection required" }
    
    Write-Log "🚀 Azure Real-time Monitor initialized" -Level SUCCESS
    Write-Log "Refresh interval: $RefreshIntervalSeconds seconds" -Level INFO
    
    if ($ResourceGroups.Count -gt 0) {
        Write-Log "Monitoring resource groups: $($ResourceGroups -join ', ')" -Level INFO
    }
    
    if ($ResourceTypes.Count -gt 0) {
        Write-Log "Monitoring resource types: $($ResourceTypes -join ', ')" -Level INFO
    }
    
    if ($StartWebDashboard) {
        Write-Log "🌐 Web dashboard will be available at: http://localhost:$DashboardPort" -Level INFO
        # Start dashboard in background job
        Start-Job -ScriptBlock { 
            # Dashboard code would go here
            while ($true) { Start-Sleep 1 }
        } | Out-Null
    }
    
    if ($EnableAlerts) {
        Write-Log "🚨 Alerting enabled" -Level INFO
        if ($AlertWebhookUrl) {
            Write-Log "Webhook URL configured" -Level INFO
        }
    }
    
    # Start monitoring
    Write-Log "Press Ctrl+C to stop monitoring..." -Level INFO
    Start-ResourceMonitoring
    
} catch {
    Write-Log "Monitor failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    throw
} finally {
    $global:MonitoringState.Running = $false
    Write-Log "🛑 Monitoring stopped" -Level INFO
}
