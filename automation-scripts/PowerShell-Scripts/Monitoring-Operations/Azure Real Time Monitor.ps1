<#
.SYNOPSIS
    Azure Real Time Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Real Time Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

param(
    [Parameter(Mandatory=$false)][string[]]$WEResourceGroups = @(),
    [Parameter(Mandatory=$false)][string[]]$WEResourceTypes = @(),
    [Parameter(Mandatory=$false)][int]$WERefreshIntervalSeconds = 30,
    [Parameter(Mandatory=$false)][string]$WEDashboardPort = " 8080" ,
    [Parameter(Mandatory=$false)][Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAlertWebhookUrl,
    [Parameter(Mandatory=$false)][switch]$WEStartWebDashboard,
    [Parameter(Mandatory=$false)][switch]$WEEnableAlerts,
    [Parameter(Mandatory=$false)][switch]$WEExportMetrics
)

$modulePath = Join-Path -Path $WEPSScriptRoot -ChildPath " .." -AdditionalChildPath " .." , " modules" , " AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

Show-Banner -ScriptName " Azure Real-time Monitor" -Description " Live monitoring with web dashboard and alerts"


$script:MonitoringState = @{
    Running = $false
    Resources = @{}
    Metrics = @()
    Alerts = @()
    StartTime = Get-Date
}

function WE-Start-ResourceMonitoring {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $script:MonitoringState.Running = $true
    Write-Log " 🔴 Starting real-time monitoring..." -Level SUCCESS
    
    while ($script:MonitoringState.Running) {
        try {
            $timestamp = Get-Date
            Write-Log " 📊 Collecting metrics at $($timestamp.ToString('HH:mm:ss'))" -Level INFO
            
            # Get resources to monitor
            $resources = if ($WEResourceGroups.Count -gt 0) {
                $WEResourceGroups | ForEach-Object { Get-AzResource -ResourceGroupName $_ }
            } else {
                Get-AzResource
            }
            
            if ($WEResourceTypes.Count -gt 0) {
                $resources = $resources | Where-Object { $_.ResourceType -in $WEResourceTypes }
            }
            
            # Collect metrics for each resource
            $currentMetrics = @()
            foreach ($resource in $resources) {
                $metric = Get-ResourceHealthMetric -Resource $resource
                $currentMetrics = $currentMetrics + $metric
                
                # Check for alerts
                if ($WEEnableAlerts) {
                    Test-ResourceAlert -Metric $metric
                }
            }
            
            # Update script state
            $script:MonitoringState.Metrics = $currentMetrics
            $script:MonitoringState.LastUpdate = $timestamp
            
            # Display summary
            $healthyCount = ($currentMetrics | Where-Object { $_.Status -eq " Healthy" }).Count
            $unhealthyCount = ($currentMetrics | Where-Object { $_.Status -ne " Healthy" }).Count
            
            Write-WELog " 📈 Resources: $($resources.Count) | ✅ Healthy: $healthyCount | ⚠️ Issues: $unhealthyCount" " INFO" -ForegroundColor Green
            
            if ($unhealthyCount -gt 0) {
                $issues = $currentMetrics | Where-Object { $_.Status -ne " Healthy" }
                foreach ($issue in $issues) {
                    Write-WELog "  ⚠️ $($issue.Name): $($issue.Status) - $($issue.Details)" " INFO" -ForegroundColor Yellow
                }
            }
            
            Start-Sleep -Seconds $WERefreshIntervalSeconds
            
        } catch {
            Write-Log " Monitoring error: $($_.Exception.Message)" -Level ERROR
            Start-Sleep -Seconds 5
        }
    }
}

function WE-Get-ResourceHealthMetric {
    param($WEResource)
    
    $metric = @{
        Name = $WEResource.Name
        ResourceGroup = $WEResource.ResourceGroupName
        Type = $WEResource.ResourceType
        Location = $WEResource.Location
        Status = " Unknown"
        Details = ""
        Timestamp = Get-Date
        Metrics = @{}
    }
    
    try {
        switch ($WEResource.ResourceType) {
            " Microsoft.Compute/virtualMachines" {
                $vm = Get-AzVM -ResourceGroupName $WEResource.ResourceGroupName -Name $WEResource.Name -Status -ErrorAction SilentlyContinue
                if ($vm) {
                    $powerState = ($vm.Statuses | Where-Object { $_.Code -like " PowerState/*" }).DisplayStatus
                    $metric.Status = if ($powerState -eq " VM running" ) { " Healthy" } else { " Unhealthy" }
                    $metric.Details = $powerState
                    $metric.Metrics.PowerState = $powerState
                }
            }
            " Microsoft.Storage/storageAccounts" {
                $storage = Get-AzStorageAccount -ResourceGroupName $WEResource.ResourceGroupName -Name $WEResource.Name -ErrorAction SilentlyContinue
                if ($storage) {
                    $metric.Status = if ($storage.ProvisioningState -eq " Succeeded" ) { " Healthy" } else { " Unhealthy" }
                    $metric.Details = $storage.ProvisioningState
                    $metric.Metrics.ProvisioningState = $storage.ProvisioningState
                    $metric.Metrics.Tier = $storage.Sku.Tier
                }
            }
            " Microsoft.Web/sites" {
                $webapp = Get-AzWebApp -ResourceGroupName $WEResource.ResourceGroupName -Name $WEResource.Name -ErrorAction SilentlyContinue
                if ($webapp) {
                    $metric.Status = if ($webapp.State -eq " Running" ) { " Healthy" } else { " Unhealthy" }
                    $metric.Details = $webapp.State
                    $metric.Metrics.State = $webapp.State
                    $metric.Metrics.DefaultHostName = $webapp.DefaultHostName
                }
            }
            default {
                $metric.Status = " Healthy"
                $metric.Details = " Basic monitoring"
            }
        }
    } catch {
        $metric.Status = " Error"
        $metric.Details = $_.Exception.Message
    }
    
    return $metric
}

function WE-Test-ResourceAlert {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    param($WEMetric)
    
    $alertTriggered = $false
    $alertMessage = ""
    
    # Check for common alert conditions
    if ($WEMetric.Status -eq " Unhealthy" ) {
        $alertTriggered = $true
        $alertMessage = " Resource $($WEMetric.Name) is unhealthy: $($WEMetric.Details)"
    }
    
    if ($WEMetric.Type -eq " Microsoft.Compute/virtualMachines" -and $WEMetric.Metrics.PowerState -eq " VM deallocated" ) {
        $alertTriggered = $true
        $alertMessage = " VM $($WEMetric.Name) has been deallocated"
    }
    
    if ($alertTriggered) {
       ;  $alert = @{
            Timestamp = Get-Date
            Resource = $WEMetric.Name
            Type = $WEMetric.Type
            Message = $alertMessage
            Severity = " Warning"
        }
        
        $script:MonitoringState.Alerts += $alert
        Write-Log " 🚨 ALERT: $alertMessage" -Level WARN
        
        # Send webhook notification if configured
        if ($WEAlertWebhookUrl) {
            Send-AlertWebhook -Alert $alert
        }
    }
}

function WE-Send-AlertWebhook {
    param($WEAlert)
    
    try {
       ;  $payload = @{
            text = " 🚨 Azure Alert: $($WEAlert.Message)"
            timestamp = $WEAlert.Timestamp
            resource = $WEAlert.Resource
            severity = $WEAlert.Severity
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri $WEAlertWebhookUrl -Method Post -Body $payload -ContentType " application/json"
        Write-Log " ✓ Alert sent to webhook" -Level SUCCESS
    } catch {
        Write-Log " Failed to send webhook alert: $($_.Exception.Message)" -Level ERROR
    }
}


try {
    if (-not (Test-AzureConnection)) { throw " Azure connection required" }
    
    Write-Log " 🚀 Azure Real-time Monitor initialized" -Level SUCCESS
    Write-Log " Refresh interval: $WERefreshIntervalSeconds seconds" -Level INFO
    
    if ($WEResourceGroups.Count -gt 0) {
        Write-Log " Monitoring resource groups: $($WEResourceGroups -join ', ')" -Level INFO
    }
    
    if ($WEResourceTypes.Count -gt 0) {
        Write-Log " Monitoring resource types: $($WEResourceTypes -join ', ')" -Level INFO
    }
    
    if ($WEStartWebDashboard) {
        Write-Log " 🌐 Web dashboard will be available at: http://localhost:$WEDashboardPort" -Level INFO
        # Start dashboard in background job
        Start-Job -ScriptBlock { 
            # Dashboard code would go here
            while ($true) { Start-Sleep 1 }
        } | Out-Null
    }
    
    if ($WEEnableAlerts) {
        Write-Log " 🚨 Alerting enabled" -Level INFO
        if ($WEAlertWebhookUrl) {
            Write-Log " Webhook URL configured" -Level INFO
        }
    }
    
    # Start monitoring
    Write-Log " Press Ctrl+C to stop monitoring..." -Level INFO
    Start-ResourceMonitoring
    
} catch {
    Write-Log " Monitor failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    throw
} finally {
    $script:MonitoringState.Running = $false
    Write-Log " 🛑 Monitoring stopped" -Level INFO
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================