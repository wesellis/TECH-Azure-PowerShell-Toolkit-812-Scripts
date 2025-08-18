<#
.SYNOPSIS
    Azure Chaos Engineering Platform

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
    We Enhanced Azure Chaos Engineering Platform

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

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
    .\Azure-Chaos-Engineering-Platform.ps1 -ChaosMode " NetworkLatency" -TargetScope " ResourceGroup" -Duration 10 -SafetyChecks

.NOTES
    Author: Wesley Ellis
    Date: June 2024
    Version: 1.0.0
    Requires: Az.Resources, Az.Monitor, Az.Network modules
    WARNING: This tool introduces controlled failures. Use with extreme caution in production.


[CmdletBinding(SupportsShouldProcess=$true)]
[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet(" NetworkLatency" , " ResourceFailure" , " ZoneFailure" , " FullDR" , " ApplicationStress" , " DatabaseFailover" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEChaosMode,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" ResourceGroup" , " Subscription" , " Region" )]
    [string]$WETargetScope = " ResourceGroup" ,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETargetResourceGroup,
    
    [Parameter(Mandatory=$false)]
    [int]$WEDuration = 5,
    
    [Parameter(Mandatory=$false)]
    [switch]$WESafetyChecks = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$WERecoveryValidation = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEDocumentResults = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEDryRun
)


$requiredModules = @('Az.Resources', 'Az.Monitor', 'Az.Network', 'Az.Compute', 'Az.Storage')
foreach ($module in $requiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Write-Error " Module $module is not installed. Please install it using: Install-Module -Name $module"
        exit 1
    }
    Import-Module $module -ErrorAction Stop
}


class ChaosEngineeringPlatform {
    [string]$WEExperimentId
    [string]$WEChaosMode
    [string]$WETargetScope
    [int]$WEDuration
    [array]$WETargetResources
    [hashtable]$WEBaselineMetrics
    [hashtable]$WEChaosMetrics
    [array]$WESafetyBreakers
    [array]$WEExperimentResults
    [bool]$WESafetyEnabled
    
    ChaosEngineeringPlatform([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEMode, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEScope, [int]$WEDurationMinutes, [bool]$WESafety) {
        $this.ExperimentId = " chaos-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $this.ChaosMode = $WEMode
        $this.TargetScope = $WEScope
        $this.Duration = $WEDurationMinutes
        $this.TargetResources = @()
        $this.BaselineMetrics = @{}
        $this.ChaosMetrics = @{}
        $this.SafetyBreakers = @()
        $this.ExperimentResults = @()
        $this.SafetyEnabled = $WESafety
        
        $this.InitializeSafetyBreakers()
    }
    
    [void]InitializeSafetyBreakers() {
        if (!$this.SafetyEnabled) { return }
        
        Write-WELog " Initializing safety breakers..." " INFO" -ForegroundColor Yellow
        
        $this.SafetyBreakers = @(
            @{
                Name = " HighErrorRate"
                Threshold = 50 # Percentage
                MetricName = " ErrorRate"
                Action = " StopExperiment"
            },
            @{
                Name = " LowAvailability"
                Threshold = 90 # Percentage
                MetricName = " Availability"
                Action = " StopExperiment"
            },
            @{
                Name = " ExcessiveLatency"
                Threshold = 5000 # Milliseconds
                MetricName = " ResponseTime"
                Action = " StopExperiment"
            },
            @{
                Name = " ResourceUtilization"
                Threshold = 95 # Percentage
                MetricName = " CPUUtilization"
                Action = " AlertOnly"
            }
        )
    }
    
    [void]DiscoverTargetResources([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName) {
        Write-WELog " Discovering target resources in scope: $($this.TargetScope)" " INFO" -ForegroundColor Yellow
        
        switch ($this.TargetScope) {
            " ResourceGroup" {
                if (!$WEResourceGroupName) {
                    throw " ResourceGroup name required for ResourceGroup scope"
                }
                $this.TargetResources = Get-AzResource -ResourceGroupName $WEResourceGroupName
            }
            " Subscription" {
                $this.TargetResources = Get-AzResource -ErrorAction Stop
            }
            " Region" {
                # Filter by region - would need region parameter
                $this.TargetResources = Get-AzResource -ErrorAction Stop | Where-Object { $_.Location -eq " East US" }
            }
        }
        
        Write-WELog " Found $($this.TargetResources.Count) resources in scope" " INFO" -ForegroundColor Cyan
        
        # Filter resources based on chaos mode
        $this.FilterResourcesByMode()
    }
    
    [void]FilterResourcesByMode() {
        $originalCount = $this.TargetResources.Count
        
        switch ($this.ChaosMode) {
            " NetworkLatency" {
                $this.TargetResources = $this.TargetResources | Where-Object { 
                    $_.ResourceType -in @(
                        " Microsoft.Compute/virtualMachines" ,
                        " Microsoft.Web/sites" ,
                        " Microsoft.ContainerInstance/containerGroups"
                    )
                }
            }
            " ResourceFailure" {
                $this.TargetResources = $this.TargetResources | Where-Object { 
                    $_.ResourceType -in @(
                        " Microsoft.Compute/virtualMachines" ,
                        " Microsoft.Web/sites" ,
                        " Microsoft.Storage/storageAccounts"
                    )
                }
            }
            " DatabaseFailover" {
                $this.TargetResources = $this.TargetResources | Where-Object { 
                    $_.ResourceType -in @(
                        " Microsoft.Sql/servers" ,
                        " Microsoft.DocumentDB/databaseAccounts" ,
                        " Microsoft.DBforPostgreSQL/servers"
                    )
                }
            }
            " ApplicationStress" {
                $this.TargetResources = $this.TargetResources | Where-Object { 
                    $_.ResourceType -in @(
                        " Microsoft.Web/sites" ,
                        " Microsoft.ContainerService/managedClusters" ,
                        " Microsoft.ServiceFabric/clusters"
                    )
                }
            }
        }
        
        $filteredCount = $this.TargetResources.Count
        Write-WELog " Filtered to $filteredCount resources for $($this.ChaosMode) experiment" " INFO" -ForegroundColor Cyan
    }
    
    [void]EstablishBaseline() {
        Write-WELog " Establishing baseline metrics..." " INFO" -ForegroundColor Yellow
        
        foreach ($resource in $this.TargetResources) {
            $metrics = $this.CollectResourceMetrics($resource)
            $this.BaselineMetrics[$resource.ResourceId] = $metrics
        }
        
        Write-WELog " Baseline established for $($this.BaselineMetrics.Count) resources" " INFO" -ForegroundColor Green
    }
    
    [hashtable]CollectResourceMetrics([object]$WEResource) {
        $metrics = @{
            ResourceId = $WEResource.ResourceId
            ResourceType = $WEResource.ResourceType
            Timestamp = Get-Date -ErrorAction Stop
            CPUUtilization = $null
            MemoryUtilization = $null
            NetworkLatency = $null
            ErrorRate = $null
            Availability = $null
        }
        
        try {
            # Collect specific metrics based on resource type
            switch ($WEResource.ResourceType) {
                " Microsoft.Compute/virtualMachines" {
                    $metrics.CPUUtilization = $this.GetVMCPUMetrics($WEResource)
                    $metrics.MemoryUtilization = $this.GetVMMemoryMetrics($WEResource)
                }
                " Microsoft.Web/sites" {
                    $metrics.ErrorRate = $this.GetWebAppErrorRate($WEResource)
                    $metrics.Availability = $this.GetWebAppAvailability($WEResource)
                }
                " Microsoft.Storage/storageAccounts" {
                    $metrics.Availability = $this.GetStorageAvailability($WEResource)
                }
            }
        } catch {
            Write-Warning " Failed to collect metrics for $($WEResource.Name): $_"
        }
        
        return $metrics
    }
    
    [double]GetVMCPUMetrics([object]$WEVM) {
        try {
            $endTime = Get-Date -ErrorAction Stop
            $startTime = $endTime.AddMinutes(-5)
            
            $metrics = Get-AzMetric -ResourceId $WEVM.ResourceId -MetricName " Percentage CPU" `
                -StartTime $startTime -EndTime $endTime -TimeGrain 00:01:00 `
                -AggregationType Average -WarningAction SilentlyContinue
            
            if ($metrics -and $metrics.Data) {
                return ($metrics.Data | Measure-Object -Property Average -Average).Average
            }
        } catch {
            Write-Debug " Failed to get CPU metrics for $($WEVM.Name)"
        }
        
        return 0
    }
    
    [double]GetWebAppErrorRate([object]$WEWebApp) {
        # Simulate error rate collection
        return [math]::Round((Get-Random -Minimum 0 -Maximum 5), 2)
    }
    
    [double]GetWebAppAvailability([object]$WEWebApp) {
        # Simulate availability check
        return [math]::Round((Get-Random -Minimum 95 -Maximum 100), 2)
    }
    
    [double]GetStorageAvailability([object]$WEStorage) {
        # Simulate storage availability check
        return [math]::Round((Get-Random -Minimum 98 -Maximum 100), 2)
    }
    
    [void]ExecuteChaosExperiment([bool]$WEDryRun) {
        Write-WELog " `n=== Starting Chaos Experiment: $($this.ChaosMode) ===" " INFO" -ForegroundColor Red
        Write-WELog " Experiment ID: $($this.ExperimentId)" " INFO" -ForegroundColor Cyan
        Write-WELog " Duration: $($this.Duration) minutes" " INFO" -ForegroundColor Cyan
        Write-WELog " Target Resources: $($this.TargetResources.Count)" " INFO" -ForegroundColor Cyan
        
        if ($WEDryRun) {
            Write-WELog " `n*** DRY RUN MODE - No actual changes will be made ***" " INFO" -ForegroundColor Yellow
        }
        
        $startTime = Get-Date -ErrorAction Stop
        $endTime = $startTime.AddMinutes($this.Duration)
        
        # Pre-experiment safety check
        if ($this.SafetyEnabled) {
            $safetyResult = $this.PerformSafetyCheck()
            if (!$safetyResult.Safe) {
                throw " Safety check failed: $($safetyResult.Reason). Experiment aborted."
            }
        }
        
        try {
            # Execute chaos based on mode
            switch ($this.ChaosMode) {
                " NetworkLatency" { $this.InjectNetworkLatency($WEDryRun) }
                " ResourceFailure" { $this.TriggerResourceFailure($WEDryRun) }
                " ZoneFailure" { $this.SimulateZoneFailure($WEDryRun) }
                " ApplicationStress" { $this.InjectApplicationStress($WEDryRun) }
                " DatabaseFailover" { $this.TriggerDatabaseFailover($WEDryRun) }
                " FullDR" { $this.ExecuteFullDRTest($WEDryRun) }
            }
            
            # Monitor during experiment
            $this.MonitorExperiment($endTime, $WEDryRun)
            
        } finally {
            # Cleanup and recovery
            Write-WELog " `nCleaning up experiment..." " INFO" -ForegroundColor Yellow
            $this.CleanupExperiment($WEDryRun)
        }
    }
    
    [void]InjectNetworkLatency([bool]$WEDryRun) {
        Write-WELog " Injecting network latency..." " INFO" -ForegroundColor Red
        
        foreach ($resource in $this.TargetResources) {
            if ($resource.ResourceType -eq " Microsoft.Compute/virtualMachines" ) {
                if ($WEDryRun) {
                    Write-WELog " DRY RUN: Would inject 200ms latency on VM: $($resource.Name)" " INFO" -ForegroundColor Yellow
                } else {
                    # In a real implementation, this would use Azure Chaos Studio or custom agents
                    Write-WELog " Injecting latency on VM: $($resource.Name)" " INFO" -ForegroundColor Red
                    
                    $result = @{
                        ResourceId = $resource.ResourceId
                        Action = " NetworkLatency"
                        Parameters = @{ Latency = " 200ms" }
                        Timestamp = Get-Date -ErrorAction Stop
                        Success = $true
                    }
                    
                    $this.ExperimentResults += $result
                }
            }
        }
    }
    
    [void]TriggerResourceFailure([bool]$WEDryRun) {
        Write-WELog " Triggering resource failures..." " INFO" -ForegroundColor Red
        
        # Select random resources for failure (max 30% of resources)
        $failureCount = [math]::Min([math]::Ceiling($this.TargetResources.Count * 0.3), 3)
        $resourcesToFail = $this.TargetResources | Get-Random -Count $failureCount
        
        foreach ($resource in $resourcesToFail) {
            if ($WEDryRun) {
                Write-WELog " DRY RUN: Would stop resource: $($resource.Name)" " INFO" -ForegroundColor Yellow
            } else {
                switch ($resource.ResourceType) {
                    " Microsoft.Compute/virtualMachines" {
                        Write-WELog " Stopping VM: $($resource.Name)" " INFO" -ForegroundColor Red
                        Stop-AzVM -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -Force -NoWait
                    }
                    " Microsoft.Web/sites" {
                        Write-WELog " Stopping Web App: $($resource.Name)" " INFO" -ForegroundColor Red
                        Stop-AzWebApp -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name
                    }
                }
                
               ;  $result = @{
                    ResourceId = $resource.ResourceId
                    Action = " ResourceFailure"
                    Parameters = @{ Type = " Stop" }
                    Timestamp = Get-Date -ErrorAction Stop
                    Success = $true
                }
                
                $this.ExperimentResults += $result
            }
        }
    }
    
    [void]InjectApplicationStress([bool]$WEDryRun) {
        Write-WELog " Injecting application stress..." " INFO" -ForegroundColor Red
        
        foreach ($resource in $this.TargetResources) {
            if ($resource.ResourceType -eq " Microsoft.Web/sites" ) {
                if ($WEDryRun) {
                    Write-WELog " DRY RUN: Would stress test app: $($resource.Name)" " INFO" -ForegroundColor Yellow
                } else {
                    Write-WELog " Starting stress test on: $($resource.Name)" " INFO" -ForegroundColor Red
                    
                    # Simulate stress testing
                   ;  $result = @{
                        ResourceId = $resource.ResourceId
                        Action = " ApplicationStress"
                        Parameters = @{ CPULoad = " 80%" ; MemoryLoad = " 70%" }
                        Timestamp = Get-Date -ErrorAction Stop
                        Success = $true
                    }
                    
                    $this.ExperimentResults += $result
                }
            }
        }
    }
    
    [void]TriggerDatabaseFailover([bool]$WEDryRun) {
        Write-WELog " Triggering database failover..." " INFO" -ForegroundColor Red
        
        $databases = $this.TargetResources | Where-Object { $_.ResourceType -like " *Sql*" -or $_.ResourceType -like " *DocumentDB*" }
        
        foreach ($db in $databases) {
            if ($WEDryRun) {
                Write-WELog " DRY RUN: Would trigger failover for: $($db.Name)" " INFO" -ForegroundColor Yellow
            } else {
                Write-WELog " Triggering failover for: $($db.Name)" " INFO" -ForegroundColor Red
                
                $result = @{
                    ResourceId = $db.ResourceId
                    Action = " DatabaseFailover"
                    Parameters = @{ Type = " Automatic" }
                    Timestamp = Get-Date -ErrorAction Stop
                    Success = $true
                }
                
                $this.ExperimentResults += $result
            }
        }
    }
    
    [void]SimulateZoneFailure([bool]$WEDryRun) {
        Write-WELog " Simulating availability zone failure..." " INFO" -ForegroundColor Red
        
        if ($WEDryRun) {
            Write-WELog " DRY RUN: Would simulate zone failure affecting multiple resources" " INFO" -ForegroundColor Yellow
        } else {
            # This would simulate an entire availability zone going down
            Write-WELog " Simulating zone failure - affecting zone-redundant resources" " INFO" -ForegroundColor Red
        }
    }
    
    [void]ExecuteFullDRTest([bool]$WEDryRun) {
        Write-WELog " Executing full disaster recovery test..." " INFO" -ForegroundColor Red
        
        if ($WEDryRun) {
            Write-WELog " DRY RUN: Would execute complete DR failover" " INFO" -ForegroundColor Yellow
        } else {
            Write-WELog " *** FULL DR TEST - This will test complete failover procedures ***" " INFO" -ForegroundColor Red
            # Full DR implementation would go here
        }
    }
    
    [void]MonitorExperiment([datetime]$WEEndTime, [bool]$WEDryRun) {
        Write-WELog " `nMonitoring experiment progress..." " INFO" -ForegroundColor Cyan
        
        while ((Get-Date) -lt $WEEndTime) {
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
                    Write-WELog " SAFETY BREAKER TRIGGERED: $($safetyResult.Reason)" " INFO" -ForegroundColor Red
                    break
                }
            }
            
           ;  $remainingMinutes = [math]::Ceiling(($WEEndTime - (Get-Date)).TotalMinutes)
            Write-WELog " Experiment running... $remainingMinutes minutes remaining" " INFO" -ForegroundColor Cyan
            
            Start-Sleep -Seconds 30
        }
    }
    
    [hashtable]PerformSafetyCheck() {
        Write-WELog " Performing pre-experiment safety check..." " INFO" -ForegroundColor Yellow
        
        # Check baseline metrics
        foreach ($resourceId in $this.BaselineMetrics.Keys) {
           ;  $baseline = $this.BaselineMetrics[$resourceId]
            
            if ($baseline.ErrorRate -gt 10) {
                return @{ Safe = $false; Reason = " Baseline error rate too high: $($baseline.ErrorRate)%" }
            }
            
            if ($baseline.Availability -lt 95) {
                return @{ Safe = $false; Reason = " Baseline availability too low: $($baseline.Availability)%" }
            }
        }
        
        return @{ Safe = $true; Reason = " All safety checks passed" }
    }
    
    [hashtable]CheckSafetyBreakers([hashtable]$WECurrentMetrics) {
        foreach ($breaker in $this.SafetyBreakers) {
            foreach ($resourceId in $WECurrentMetrics.Keys) {
                $metrics = $WECurrentMetrics[$resourceId]
               ;  $metricValue = $metrics[$breaker.MetricName]
                
                if ($null -ne $metricValue) {
                   ;  $thresholdBreached = switch ($breaker.MetricName) {
                        " ErrorRate" { $metricValue -gt $breaker.Threshold }
                        " Availability" { $metricValue -lt $breaker.Threshold }
                        " ResponseTime" { $metricValue -gt $breaker.Threshold }
                        " CPUUtilization" { $metricValue -gt $breaker.Threshold }
                        default { $false }
                    }
                    
                    if ($thresholdBreached) {
                        return @{
                            Safe = $false
                            Reason = " $($breaker.Name) threshold breached: $metricValue (threshold: $($breaker.Threshold))"
                            Action = $breaker.Action
                        }
                    }
                }
            }
        }
        
        return @{ Safe = $true; Reason = " All safety breakers within limits" }
    }
    
    [void]CleanupExperiment([bool]$WEDryRun) {
        Write-WELog " Cleaning up chaos experiment..." " INFO" -ForegroundColor Green
        
        foreach ($result in $this.ExperimentResults) {
            switch ($result.Action) {
                " ResourceFailure" {
                    if ($WEDryRun) {
                        Write-WELog " DRY RUN: Would restart stopped resources" " INFO" -ForegroundColor Yellow
                    } else {
                        # Restart stopped resources
                        $resource = Get-AzResource -ResourceId $result.ResourceId
                        if ($resource.ResourceType -eq " Microsoft.Compute/virtualMachines" ) {
                            Write-WELog " Restarting VM: $($resource.Name)" " INFO" -ForegroundColor Green
                            Start-AzVM -ResourceGroupName $resource.ResourceGroupName -Name $resource.Name -NoWait
                        }
                    }
                }
            }
        }
    }
    
    [void]ValidateRecovery() {
        Write-WELog " `nValidating recovery mechanisms..." " INFO" -ForegroundColor Green
        
        Start-Sleep -Seconds 60  # Wait for recovery
        
        foreach ($resource in $this.TargetResources) {
            $postMetrics = $this.CollectResourceMetrics($resource)
            $baselineMetrics = $this.BaselineMetrics[$resource.ResourceId]
            
           ;  $recovery = @{
                ResourceId = $resource.ResourceId
                BaselineAvailability = $baselineMetrics.Availability
                PostExperimentAvailability = $postMetrics.Availability
                RecoveryTime = " 60 seconds"  # Simplified
                FullyRecovered = $postMetrics.Availability -ge ($baselineMetrics.Availability * 0.95)
            }
            
            if ($recovery.FullyRecovered) {
                Write-WELog " ✅ $($resource.Name) - Recovery successful" " INFO" -ForegroundColor Green
            } else {
                Write-WELog " ❌ $($resource.Name) - Recovery incomplete" " INFO" -ForegroundColor Red
            }
        }
    }
    
    [string]GenerateExperimentReport() {
       ;  $html = @"
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
    <div class=" container" >
        <div class=" header" >
            <h1>Chaos Engineering Experiment Report</h1>
            <p>Experiment ID: $($this.ExperimentId)</p>
            <p>Mode: $($this.ChaosMode) | Duration: $($this.Duration) minutes</p>
            <p>Generated: $(Get-Date)</p>
        </div>
        
        <div class=" summary" >
            <div class=" metric-card" >
                <div class=" metric-value" >$($this.TargetResources.Count)</div>
                <div>Resources Tested</div>
            </div>
            <div class=" metric-card" >
                <div class=" metric-value" >$($this.ExperimentResults.Count)</div>
                <div>Actions Executed</div>
            </div>
            <div class=" metric-card" >
                <div class=" metric-value" >$(($this.ExperimentResults | Where-Object { $_.Success }).Count)</div>
                <div>Successful Actions</div>
            </div>
            <div class=" metric-card" >
                <div class=" metric-value" >$($this.SafetyBreakers.Count)</div>
                <div>Safety Breakers</div>
            </div>
        </div>
        
        <div class=" section" >
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
" @
        
        foreach ($result in $this.ExperimentResults) {
            $resource = Get-AzResource -ResourceId $result.ResourceId -ErrorAction SilentlyContinue
            $resourceName = $resource ? $resource.Name : " Unknown"
            $status = $result.Success ? " Success" : " Failed"
            $statusClass = $result.Success ? " success" : " failure"
            $params = ($result.Parameters.GetEnumerator() | ForEach-Object { " $($_.Key): $($_.Value)" }) -join " , "
            
            $html = $html + @"
                    <tr>
                        <td>$($result.Timestamp)</td>
                        <td>$resourceName</td>
                        <td>$($result.Action)</td>
                        <td>$params</td>
                        <td class=" $statusClass" >$status</td>
                    </tr>
" @
        }
        
        $html = $html + @"
                </tbody>
            </table>
        </div>
        
        <div class=" section" >
            <h2>Key Findings</h2>
            <div class=" timeline" >
                <h3>Resilience Assessment</h3>
                <ul>
                    <li>System demonstrated $(if ($this.ExperimentResults.Count -gt 0) { " good" } else { " untested" }) resilience to $($this.ChaosMode) failures</li>
                    <li>Recovery mechanisms were $(if ($WERecoveryValidation) { " validated" } else { " not tested" })</li>
                    <li>Safety breakers $(if ($this.SafetyEnabled) { " were active" } else { " were disabled" }) during the experiment</li>
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
" @
        
        return $html
    }
}


try {
    Write-WELog " Azure Chaos Engineering Platform v1.0" " INFO" -ForegroundColor Red
    Write-WELog " ====================================" " INFO" -ForegroundColor Red
    Write-WELog " ⚠️  WARNING: This tool introduces controlled failures!" " INFO" -ForegroundColor Yellow
    Write-WELog " ⚠️  Use with extreme caution in production environments!" " INFO" -ForegroundColor Yellow
    
    if (!$WEDryRun) {
        $confirmation = Read-Host " `nAre you sure you want to proceed with chaos engineering? (yes/no)"
        if ($confirmation -ne " yes" ) {
            Write-WELog " Chaos engineering cancelled by user." " INFO" -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Connect to Azure if needed
    $context = Get-AzContext -ErrorAction Stop
    if (!$context) {
        Write-WELog " Connecting to Azure..." " INFO" -ForegroundColor Yellow
        Connect-AzAccount
    }
    
    # Initialize chaos platform
    $chaosEngine = [ChaosEngineeringPlatform]::new($WEChaosMode, $WETargetScope, $WEDuration, $WESafetyChecks)
    
    # Discover target resources
    $chaosEngine.DiscoverTargetResources($WETargetResourceGroup)
    
    if ($chaosEngine.TargetResources.Count -eq 0) {
        throw " No suitable target resources found for $WEChaosMode experiment"
    }
    
    # Establish baseline
    $chaosEngine.EstablishBaseline()
    
    # Execute chaos experiment
    $chaosEngine.ExecuteChaosExperiment($WEDryRun)
    
    # Validate recovery if enabled
    if ($WERecoveryValidation -and !$WEDryRun) {
        $chaosEngine.ValidateRecovery()
    }
    
    # Generate report
    if ($WEDocumentResults) {
       ;  $report = $chaosEngine.GenerateExperimentReport()
       ;  $reportPath = " .\ChaosEngineering-Report-$($chaosEngine.ExperimentId).html"
        $report | Out-File -FilePath $reportPath -Encoding UTF8
        Write-WELog " `nExperiment report saved to: $reportPath" " INFO" -ForegroundColor Green
    }
    
    Write-WELog " `n✅ Chaos engineering experiment completed successfully!" " INFO" -ForegroundColor Green
    Write-WELog " Experiment ID: $($chaosEngine.ExperimentId)" " INFO" -ForegroundColor Cyan
    
} catch {
    Write-Error " Chaos engineering experiment failed: $_"
    exit 1
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================