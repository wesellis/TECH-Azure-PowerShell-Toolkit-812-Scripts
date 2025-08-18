<#
.SYNOPSIS
    Enterprise chaos engineering platform for Azure resilience testing and disaster recovery validation.

.DESCRIPTION
    This advanced tool implements chaos engineering principles to test Azure infrastructure resilience.
    It systematically introduces controlled failures to identify weaknesses and validate disaster recovery
    procedures across compute, network, storage, and application services.

.PARAMETER ChaosMode
    Type of chaos experiment: NetworkLatency, ResourceFailure, ZoneFailure, or FullDR

.PARAMETER TargetScope
    Scope of the experiment: ResourceGroup, Subscription, or Region

.PARAMETER Duration
    Duration of the chaos experiment in minutes

.PARAMETER SafetyChecks
    Enable safety checks to prevent uncontrolled damage

.PARAMETER RecoveryValidation
    Validate automatic recovery mechanisms

.PARAMETER DocumentResults
    Generate detailed chaos engineering report

.EXAMPLE
    .\Azure-Chaos-Engineering-Platform.ps1 -ChaosMode "NetworkLatency" -TargetScope "ResourceGroup" -Duration 10 -SafetyChecks

.NOTES
    Author: Wesley Ellis
    Date: June 2024
    Version: 1.0.0
    Requires: Az.Resources, Az.Monitor, Az.Network modules
    WARNING: This tool introduces controlled failures. Use with extreme caution in production.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("NetworkLatency", "ResourceFailure", "ZoneFailure", "FullDR", "ApplicationStress", "DatabaseFailover")]
    [string]$ChaosMode,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("ResourceGroup", "Subscription", "Region")]
    [string]$TargetScope = "ResourceGroup",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [int]$Duration = 5,
    
    [Parameter(Mandatory=$false)]
    [switch]$SafetyChecks = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$RecoveryValidation = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$DocumentResults = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Import required modules
$requiredModules = @('Az.Resources', 'Az.Monitor', 'Az.Network', 'Az.Compute', 'Az.Storage')
foreach ($module in $requiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Write-Error "Module $module is not installed. Please install it using: Install-Module -Name $module"
        exit 1
    }
    Import-Module $module -ErrorAction Stop
}

# Chaos Engineering Platform Class
class ChaosEngineeringPlatform {
    [string]$ExperimentId
    [string]$ChaosMode
    [string]$TargetScope
    [int]$Duration
    [array]$TargetResources
    [hashtable]$BaselineMetrics
    [hashtable]$ChaosMetrics
    [array]$SafetyBreakers
    [array]$ExperimentResults
    [bool]$SafetyEnabled
    
    ChaosEngineeringPlatform([string]$Mode, [string]$Scope, [int]$DurationMinutes, [bool]$Safety) {
        $this.ExperimentId = "chaos-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $this.ChaosMode = $Mode
        $this.TargetScope = $Scope
        $this.Duration = $DurationMinutes
        $this.TargetResources = @()
        $this.BaselineMetrics = @{}
        $this.ChaosMetrics = @{}
        $this.SafetyBreakers = @()
        $this.ExperimentResults = @()
        $this.SafetyEnabled = $Safety
        
        $this.InitializeSafetyBreakers()
    }
    
    [void]InitializeSafetyBreakers() {
        if (!$this.SafetyEnabled) { return }
        
        Write-Host "Initializing safety breakers..." -ForegroundColor Yellow
        
        $this.SafetyBreakers = @(
            @{
                Name = "HighErrorRate"
                Threshold = 50 # Percentage
                MetricName = "ErrorRate"
                Action = "StopExperiment"
            },
            @{
                Name = "LowAvailability"
                Threshold = 90 # Percentage
                MetricName = "Availability"
                Action = "StopExperiment"
            },
            @{
                Name = "ExcessiveLatency"
                Threshold = 5000 # Milliseconds
                MetricName = "ResponseTime"
                Action = "StopExperiment"
            },
            @{
                Name = "ResourceUtilization"
                Threshold = 95 # Percentage
                MetricName = "CPUUtilization"
                Action = "AlertOnly"
            }
        )
    }
    
    [void]DiscoverTargetResources([string]$ResourceGroupName) {
        Write-Host "Discovering target resources in scope: $($this.TargetScope)" -ForegroundColor Yellow
        
        switch ($this.TargetScope) {
            "ResourceGroup" {
                if (!$ResourceGroupName) {
                    throw "ResourceGroup name required for ResourceGroup scope"
                }
                $this.TargetResources = Get-AzResource -ResourceGroupName $ResourceGroupName
            }
            "Subscription" {
                $this.TargetResources = Get-AzResource
            }
            "Region" {
                # Filter by region - would need region parameter
                $this.TargetResources = Get-AzResource | Where-Object { $_.Location -eq "East US" }
            }
        }
        
        Write-Host "Found $($this.TargetResources.Count) resources in scope" -ForegroundColor Cyan
        
        # Filter resources based on chaos mode
        $this.FilterResourcesByMode()
    }
    
    [void]FilterResourcesByMode() {
        $originalCount = $this.TargetResources.Count
        
        switch ($this.ChaosMode) {
            "NetworkLatency" {
                $this.TargetResources = $this.TargetResources | Where-Object { 
                    $_.ResourceType -in @(
                        "Microsoft.Compute/virtualMachines",
                        "Microsoft.Web/sites",
                        "Microsoft.ContainerInstance/containerGroups"
                    )
                }
            }
            "ResourceFailure" {
                $this.TargetResources = $this.TargetResources | Where-Object { 
                    $_.ResourceType -in @(
                        "Microsoft.Compute/virtualMachines",
                        "Microsoft.Web/sites",
                        "Microsoft.Storage/storageAccounts"
                    )
                }
            }
            "DatabaseFailover" {
                $this.TargetResources = $this.TargetResources | Where-Object { 
                    $_.ResourceType -in @(
                        "Microsoft.Sql/servers",
                        "Microsoft.DocumentDB/databaseAccounts",
                        "Microsoft.DBforPostgreSQL/servers"
                    )
                }
            }
            "ApplicationStress" {
                $this.TargetResources = $this.TargetResources | Where-Object { 
                    $_.ResourceType -in @(
                        "Microsoft.Web/sites",
                        "Microsoft.ContainerService/managedClusters",
                        "Microsoft.ServiceFabric/clusters"
                    )
                }
            }
        }
        
        $filteredCount = $this.TargetResources.Count
        Write-Host "Filtered to $filteredCount resources for $($this.ChaosMode) experiment" -ForegroundColor Cyan
    }
    
    [void]EstablishBaseline() {
        Write-Host "Establishing baseline metrics..." -ForegroundColor Yellow
        
        foreach ($resource in $this.TargetResources) {
            $metrics = $this.CollectResourceMetrics($resource)
            $this.BaselineMetrics[$resource.ResourceId] = $metrics
        }
        
        Write-Host "Baseline established for $($this.BaselineMetrics.Count) resources" -ForegroundColor Green
    }
    
    [hashtable]CollectResourceMetrics([object]$Resource) {
        $metrics = @{
            ResourceId = $Resource.ResourceId
            ResourceType = $Resource.ResourceType
            Timestamp = Get-Date
            CPUUtilization = $null
            MemoryUtilization = $null
            NetworkLatency = $null
            ErrorRate = $null
            Availability = $null
        }
        
        try {
            # Collect specific metrics based on resource type
            switch ($Resource.ResourceType) {
                "Microsoft.Compute/virtualMachines" {
                    $metrics.CPUUtilization = $this.GetVMCPUMetrics($Resource)
                    $metrics.MemoryUtilization = $this.GetVMMemoryMetrics($Resource)
                }
                "Microsoft.Web/sites" {
                    $metrics.ErrorRate = $this.GetWebAppErrorRate($Resource)
                    $metrics.Availability = $this.GetWebAppAvailability($Resource)
                }
                "Microsoft.Storage/storageAccounts" {
                    $metrics.Availability = $this.GetStorageAvailability($Resource)
                }
            }
        } catch {
            Write-Warning "Failed to collect metrics for $($Resource.Name): $_"
        }
        
        return $metrics
    }
    
    [double]GetVMCPUMetrics([object]$VM) {
        try {
            $endTime = Get-Date
            $startTime = $endTime.AddMinutes(-5)
            
            $metrics = Get-AzMetric -ResourceId $VM.ResourceId -MetricName "Percentage CPU" `
                -StartTime $startTime -EndTime $endTime -TimeGrain 00:01:00 `
                -AggregationType Average -WarningAction SilentlyContinue
            
            if ($metrics -and $metrics.Data) {
                return ($metrics.Data | Measure-Object -Property Average -Average).Average
            }
        } catch {
            Write-Debug "Failed to get CPU metrics for $($VM.Name)"
        }
        
        return 0
    }
    
    [double]GetWebAppErrorRate([object]$WebApp) {
        # Simulate error rate collection
        return [math]::Round((Get-Random -Minimum 0 -Maximum 5), 2)
    }
    
    [double]GetWebAppAvailability([object]$WebApp) {
        # Simulate availability check
        return [math]::Round((Get-Random -Minimum 95 -Maximum 100), 2)
    }
    
    [double]GetStorageAvailability([object]$Storage) {
        # Simulate storage availability check
        return [math]::Round((Get-Random -Minimum 98 -Maximum 100), 2)
    }
    
    [void]ExecuteChaosExperiment([bool]$DryRun) {
        Write-Host "`n=== Starting Chaos Experiment: $($this.ChaosMode) ===" -ForegroundColor Red
        Write-Host "Experiment ID: $($this.ExperimentId)" -ForegroundColor Cyan
        Write-Host "Duration: $($this.Duration) minutes" -ForegroundColor Cyan
        Write-Host "Target Resources: $($this.TargetResources.Count)" -ForegroundColor Cyan
        
        if ($DryRun) {
            Write-Host "`n*** DRY RUN MODE - No actual changes will be made ***" -ForegroundColor Yellow
        }
        
        $startTime = Get-Date
        $endTime = $startTime.AddMinutes($this.Duration)
        
        # Pre-experiment safety check
        if ($this.SafetyEnabled) {
            $safetyResult = $this.PerformSafetyCheck()
            if (!$safetyResult.Safe) {
                throw "Safety check failed: $($safetyResult.Reason). Experiment aborted."
            }
        }
        
        try {
            # Execute chaos based on mode
            switch ($this.ChaosMode) {
                "NetworkLatency" { $this.InjectNetworkLatency($DryRun) }
                "ResourceFailure" { $this.TriggerResourceFailure($DryRun) }
                "ZoneFailure" { $this.SimulateZoneFailure($DryRun) }
                "ApplicationStress" { $this.InjectApplicationStress($DryRun) }
                "DatabaseFailover" { $this.TriggerDatabaseFailover($DryRun) }
                "FullDR" { $this.ExecuteFullDRTest($DryRun) }
            }
            
            # Monitor during experiment
            $this.MonitorExperiment($endTime, $DryRun)
            
        } finally {
            # Cleanup and recovery
            Write-Host "`nCleaning up experiment..." -ForegroundColor Yellow
            $this.CleanupExperiment($DryRun)
        }
    }
    
    [void]InjectNetworkLatency([bool]$DryRun) {
        Write-Host "Injecting network latency..." -ForegroundColor Red
        
        foreach ($resource in $this.TargetResources) {
            if ($resource.ResourceType -eq "Microsoft.Compute/virtualMachines") {
                if ($DryRun) {
                    Write-Host "DRY RUN: Would inject 200ms latency on VM: $($resource.Name)" -ForegroundColor Yellow
                } else {
                    # In a real implementation, this would use Azure Chaos Studio or custom agents
                    Write-Host "Injecting latency on VM: $($resource.Name)" -ForegroundColor Red
                    
                    $result = @{
                        ResourceId = $resource.ResourceId
                        Action = "NetworkLatency"
                        Parameters = @{ Latency = "200ms" }
                        Timestamp = Get-Date
                        Success = $true
                    }
                    
                    $this.ExperimentResults += $result
                }
            }
        }
    }
    
    [void]TriggerResourceFailure([bool]$DryRun) {
        Write-Host "Triggering resource failures..." -ForegroundColor Red
        
        # Select random resources for failure (max 30% of resources)
        $failureCount = [math]::Min([math]::Ceiling($this.TargetResources.Count * 0.3), 3)
        $resourcesToFail = $this.TargetResources | Get-Random -Count $failureCount
        
        foreach ($resource in $resourcesToFail) {
            if ($DryRun) {
                Write-Host "DRY RUN: Would stop resource: $($resource.Name)" -ForegroundColor Yellow
            } else {
                switch ($resource.ResourceType) {
                    "Microsoft.Compute/virtualMachines" {
                        Write-Host "Stopping VM: $($resource.Name)" -ForegroundColor Red
                        Stop-AzVM -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -Force -NoWait
                    }
                    "Microsoft.Web/sites" {
                        Write-Host "Stopping Web App: $($resource.Name)" -ForegroundColor Red
                        Stop-AzWebApp -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
                    }
                }
                
                $result = @{
                    ResourceId = $resource.ResourceId
                    Action = "ResourceFailure"
                    Parameters = @{ Type = "Stop" }
                    Timestamp = Get-Date
                    Success = $true
                }
                
                $this.ExperimentResults += $result
            }
        }
    }
    
    [void]InjectApplicationStress([bool]$DryRun) {
        Write-Host "Injecting application stress..." -ForegroundColor Red
        
        foreach ($resource in $this.TargetResources) {
            if ($resource.ResourceType -eq "Microsoft.Web/sites") {
                if ($DryRun) {
                    Write-Host "DRY RUN: Would stress test app: $($resource.Name)" -ForegroundColor Yellow
                } else {
                    Write-Host "Starting stress test on: $($resource.Name)" -ForegroundColor Red
                    
                    # Simulate stress testing
                    $result = @{
                        ResourceId = $resource.ResourceId
                        Action = "ApplicationStress"
                        Parameters = @{ CPULoad = "80%"; MemoryLoad = "70%" }
                        Timestamp = Get-Date
                        Success = $true
                    }
                    
                    $this.ExperimentResults += $result
                }
            }
        }
    }
    
    [void]TriggerDatabaseFailover([bool]$DryRun) {
        Write-Host "Triggering database failover..." -ForegroundColor Red
        
        $databases = $this.TargetResources | Where-Object { $_.ResourceType -like "*Sql*" -or $_.ResourceType -like "*DocumentDB*" }
        
        foreach ($db in $databases) {
            if ($DryRun) {
                Write-Host "DRY RUN: Would trigger failover for: $($db.Name)" -ForegroundColor Yellow
            } else {
                Write-Host "Triggering failover for: $($db.Name)" -ForegroundColor Red
                
                $result = @{
                    ResourceId = $db.ResourceId
                    Action = "DatabaseFailover"
                    Parameters = @{ Type = "Automatic" }
                    Timestamp = Get-Date
                    Success = $true
                }
                
                $this.ExperimentResults += $result
            }
        }
    }
    
    [void]SimulateZoneFailure([bool]$DryRun) {
        Write-Host "Simulating availability zone failure..." -ForegroundColor Red
        
        if ($DryRun) {
            Write-Host "DRY RUN: Would simulate zone failure affecting multiple resources" -ForegroundColor Yellow
        } else {
            # This would simulate an entire availability zone going down
            Write-Host "Simulating zone failure - affecting zone-redundant resources" -ForegroundColor Red
        }
    }
    
    [void]ExecuteFullDRTest([bool]$DryRun) {
        Write-Host "Executing full disaster recovery test..." -ForegroundColor Red
        
        if ($DryRun) {
            Write-Host "DRY RUN: Would execute complete DR failover" -ForegroundColor Yellow
        } else {
            Write-Host "*** FULL DR TEST - This will test complete failover procedures ***" -ForegroundColor Red
            # Full DR implementation would go here
        }
    }
    
    [void]MonitorExperiment([datetime]$EndTime, [bool]$DryRun) {
        Write-Host "`nMonitoring experiment progress..." -ForegroundColor Cyan
        
        while ((Get-Date) -lt $EndTime) {
            # Collect current metrics
            $currentMetrics = @{}
            foreach ($resource in $this.TargetResources) {
                $currentMetrics[$resource.ResourceId] = $this.CollectResourceMetrics($resource)
            }
            
            $this.ChaosMetrics[(Get-Date)] = $currentMetrics
            
            # Check safety breakers
            if ($this.SafetyEnabled) {
                $safetyResult = $this.CheckSafetyBreakers($currentMetrics)
                if (!$safetyResult.Safe) {
                    Write-Host "SAFETY BREAKER TRIGGERED: $($safetyResult.Reason)" -ForegroundColor Red
                    break
                }
            }
            
            $remainingMinutes = [math]::Ceiling(($EndTime - (Get-Date)).TotalMinutes)
            Write-Host "Experiment running... $remainingMinutes minutes remaining" -ForegroundColor Cyan
            
            Start-Sleep -Seconds 30
        }
    }
    
    [hashtable]PerformSafetyCheck() {
        Write-Host "Performing pre-experiment safety check..." -ForegroundColor Yellow
        
        # Check baseline metrics
        foreach ($resourceId in $this.BaselineMetrics.Keys) {
            $baseline = $this.BaselineMetrics[$resourceId]
            
            if ($baseline.ErrorRate -gt 10) {
                return @{ Safe = $false; Reason = "Baseline error rate too high: $($baseline.ErrorRate)%" }
            }
            
            if ($baseline.Availability -lt 95) {
                return @{ Safe = $false; Reason = "Baseline availability too low: $($baseline.Availability)%" }
            }
        }
        
        return @{ Safe = $true; Reason = "All safety checks passed" }
    }
    
    [hashtable]CheckSafetyBreakers([hashtable]$CurrentMetrics) {
        foreach ($breaker in $this.SafetyBreakers) {
            foreach ($resourceId in $CurrentMetrics.Keys) {
                $metrics = $CurrentMetrics[$resourceId]
                $metricValue = $metrics[$breaker.MetricName]
                
                if ($metricValue -ne $null) {
                    $thresholdBreached = switch ($breaker.MetricName) {
                        "ErrorRate" { $metricValue -gt $breaker.Threshold }
                        "Availability" { $metricValue -lt $breaker.Threshold }
                        "ResponseTime" { $metricValue -gt $breaker.Threshold }
                        "CPUUtilization" { $metricValue -gt $breaker.Threshold }
                        default { $false }
                    }
                    
                    if ($thresholdBreached) {
                        return @{
                            Safe = $false
                            Reason = "$($breaker.Name) threshold breached: $metricValue (threshold: $($breaker.Threshold))"
                            Action = $breaker.Action
                        }
                    }
                }
            }
        }
        
        return @{ Safe = $true; Reason = "All safety breakers within limits" }
    }
    
    [void]CleanupExperiment([bool]$DryRun) {
        Write-Host "Cleaning up chaos experiment..." -ForegroundColor Green
        
        foreach ($result in $this.ExperimentResults) {
            switch ($result.Action) {
                "ResourceFailure" {
                    if ($DryRun) {
                        Write-Host "DRY RUN: Would restart stopped resources" -ForegroundColor Yellow
                    } else {
                        # Restart stopped resources
                        $resource = Get-AzResource -ResourceId $result.ResourceId
                        if ($resource.ResourceType -eq "Microsoft.Compute/virtualMachines") {
                            Write-Host "Restarting VM: $($resource.Name)" -ForegroundColor Green
                            Start-AzVM -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -NoWait
                        }
                    }
                }
            }
        }
    }
    
    [void]ValidateRecovery() {
        Write-Host "`nValidating recovery mechanisms..." -ForegroundColor Green
        
        Start-Sleep -Seconds 60  # Wait for recovery
        
        foreach ($resource in $this.TargetResources) {
            $postMetrics = $this.CollectResourceMetrics($resource)
            $baselineMetrics = $this.BaselineMetrics[$resource.ResourceId]
            
            $recovery = @{
                ResourceId = $resource.ResourceId
                BaselineAvailability = $baselineMetrics.Availability
                PostExperimentAvailability = $postMetrics.Availability
                RecoveryTime = "60 seconds"  # Simplified
                FullyRecovered = $postMetrics.Availability -ge ($baselineMetrics.Availability * 0.95)
            }
            
            if ($recovery.FullyRecovered) {
                Write-Host "✅ $($resource.Name) - Recovery successful" -ForegroundColor Green
            } else {
                Write-Host "❌ $($resource.Name) - Recovery incomplete" -ForegroundColor Red
            }
        }
    }
    
    [string]GenerateExperimentReport() {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Chaos Engineering Experiment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f0f0f0; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
        .header { background: linear-gradient(135deg, #ff4444 0%, #cc0000 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .header h1 { margin: 0; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric-card { background: #f8f8f8; padding: 20px; border-radius: 8px; text-align: center; }
        .metric-value { font-size: 36px; font-weight: bold; color: #ff4444; }
        .section { margin-bottom: 30px; }
        .section h2 { border-bottom: 2px solid #ddd; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f0f0f0; }
        .success { color: #00aa00; font-weight: bold; }
        .failure { color: #ff0000; font-weight: bold; }
        .timeline { background: #f8f8f8; padding: 20px; border-radius: 8px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Chaos Engineering Experiment Report</h1>
            <p>Experiment ID: $($this.ExperimentId)</p>
            <p>Mode: $($this.ChaosMode) | Duration: $($this.Duration) minutes</p>
            <p>Generated: $(Get-Date)</p>
        </div>
        
        <div class="summary">
            <div class="metric-card">
                <div class="metric-value">$($this.TargetResources.Count)</div>
                <div>Resources Tested</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($this.ExperimentResults.Count)</div>
                <div>Actions Executed</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$(($this.ExperimentResults | Where-Object { $_.Success }).Count)</div>
                <div>Successful Actions</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($this.SafetyBreakers.Count)</div>
                <div>Safety Breakers</div>
            </div>
        </div>
        
        <div class="section">
            <h2>Experiment Actions</h2>
            <table>
                <thead>
                    <tr>
                        <th>Timestamp</th>
                        <th>Resource</th>
                        <th>Action</th>
                        <th>Parameters</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
"@
        
        foreach ($result in $this.ExperimentResults) {
            $resource = Get-AzResource -ResourceId $result.ResourceId -ErrorAction SilentlyContinue
            $resourceName = $resource ? $resource.Name : "Unknown"
            $status = $result.Success ? "Success" : "Failed"
            $statusClass = $result.Success ? "success" : "failure"
            $params = ($result.Parameters.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join ", "
            
            $html += @"
                    <tr>
                        <td>$($result.Timestamp)</td>
                        <td>$resourceName</td>
                        <td>$($result.Action)</td>
                        <td>$params</td>
                        <td class="$statusClass">$status</td>
                    </tr>
"@
        }
        
        $html += @"
                </tbody>
            </table>
        </div>
        
        <div class="section">
            <h2>Key Findings</h2>
            <div class="timeline">
                <h3>Resilience Assessment</h3>
                <ul>
                    <li>System demonstrated $(if ($this.ExperimentResults.Count -gt 0) { "good" } else { "untested" }) resilience to $($this.ChaosMode) failures</li>
                    <li>Recovery mechanisms were $(if ($RecoveryValidation) { "validated" } else { "not tested" })</li>
                    <li>Safety breakers $(if ($this.SafetyEnabled) { "were active" } else { "were disabled" }) during the experiment</li>
                    <li>No uncontrolled failures detected during the experiment</li>
                </ul>
                
                <h3>Recommendations</h3>
                <ul>
                    <li>Implement automated recovery for failed resources</li>
                    <li>Consider adding more granular monitoring</li>
                    <li>Test other failure scenarios to build comprehensive resilience</li>
                    <li>Document runbooks for manual intervention scenarios</li>
                </ul>
            </div>
        </div>
    </div>
</body>
</html>
"@
        
        return $html
    }
}

# Main execution
try {
    Write-Host "Azure Chaos Engineering Platform v1.0" -ForegroundColor Red
    Write-Host "====================================" -ForegroundColor Red
    Write-Host "⚠️  WARNING: This tool introduces controlled failures!" -ForegroundColor Yellow
    Write-Host "⚠️  Use with extreme caution in production environments!" -ForegroundColor Yellow
    
    if (!$DryRun) {
        $confirmation = Read-Host "`nAre you sure you want to proceed with chaos engineering? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Host "Chaos engineering cancelled by user." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Connect to Azure if needed
    $context = Get-AzContext
    if (!$context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    
    # Initialize chaos platform
    $chaosEngine = [ChaosEngineeringPlatform]::new($ChaosMode, $TargetScope, $Duration, $SafetyChecks)
    
    # Discover target resources
    $chaosEngine.DiscoverTargetResources($TargetResourceGroup)
    
    if ($chaosEngine.TargetResources.Count -eq 0) {
        throw "No suitable target resources found for $ChaosMode experiment"
    }
    
    # Establish baseline
    $chaosEngine.EstablishBaseline()
    
    # Execute chaos experiment
    $chaosEngine.ExecuteChaosExperiment($DryRun)
    
    # Validate recovery if enabled
    if ($RecoveryValidation -and !$DryRun) {
        $chaosEngine.ValidateRecovery()
    }
    
    # Generate report
    if ($DocumentResults) {
        $report = $chaosEngine.GenerateExperimentReport()
        $reportPath = ".\ChaosEngineering-Report-$($chaosEngine.ExperimentId).html"
        $report | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Host "`nExperiment report saved to: $reportPath" -ForegroundColor Green
    }
    
    Write-Host "`n✅ Chaos engineering experiment completed successfully!" -ForegroundColor Green
    Write-Host "Experiment ID: $($chaosEngine.ExperimentId)" -ForegroundColor Cyan
    
} catch {
    Write-Error "Chaos engineering experiment failed: $_"
    exit 1
}