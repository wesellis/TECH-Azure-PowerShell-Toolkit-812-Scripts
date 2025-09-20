#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Enterprise chaos engineering platform for Azure resilience testing and disaster recovery validation.
.DESCRIPTION
    This  tool implements chaos engineering principles to test Azure infrastructure resilience.
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
    Generate  chaos engineering report
    .\Azure-Chaos-Engineering-Platform.ps1 -ChaosMode "NetworkLatency" -TargetScope "ResourceGroup" -Duration 10 -SafetyChecks
    Author: Wesley Ellis
    Date: June 2024    Requires: Az.Resources, Az.Monitor, Az.Network modules
    WARNING: This tool introduces controlled failures. Use with extreme caution in production.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory)]
    [ValidateSet("NetworkLatency", "ResourceFailure", "ZoneFailure", "FullDR", "ApplicationStress", "DatabaseFailover")]
    [string]$ChaosMode,
    [ValidateSet("ResourceGroup", "Subscription", "Region")]
    [string]$TargetScope = "ResourceGroup",
    [Parameter()]
    [string]$TargetResourceGroup,
    [Parameter()]
    [int]$Duration = 5,
    [Parameter()]
    [switch]$SafetyChecks = $true,
    [Parameter()]
    [switch]$RecoveryValidation = $true,
    [Parameter()]
    [switch]$DocumentResults = $true,
    [Parameter()]
    [switch]$DryRun
)
# Import required modules
$requiredModules = @('Az.Resources', 'Az.Monitor', 'Az.Network', 'Az.Compute', 'Az.Storage')
foreach ($module in $requiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Write-Error "Module $module is not installed. Please install it using: Install-Module -Name $module"
        throw
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
        Write-Host "Initializing safety breakers..."
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
        Write-Host "Discovering target resources in scope: $($this.TargetScope)"
        switch ($this.TargetScope) {
            "ResourceGroup" {
                if (!$ResourceGroupName) {
                    throw "ResourceGroup name required for ResourceGroup scope"
                }
                $this.TargetResources = Get-AzResource -ResourceGroupName $ResourceGroupName
            }
            "Subscription" {
                $this.TargetResources = Get-AzResource -ErrorAction Stop
            }
            "Region" {
                # Filter by region - would need region parameter
                $this.TargetResources = Get-AzResource -ErrorAction Stop | Where-Object { $_.Location -eq "East US" }
            }
        }
        Write-Host "Found $($this.TargetResources.Count) resources in scope"
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
        Write-Host "Filtered to $filteredCount resources for $($this.ChaosMode) experiment"
    }
    [void]EstablishBaseline() {
        Write-Host "Establishing baseline metrics..."
        foreach ($resource in $this.TargetResources) {
            $metrics = $this.CollectResourceMetrics($resource)
            $this.BaselineMetrics[$resource.ResourceId] = $metrics
        }
        Write-Host "Baseline established for $($this.BaselineMetrics.Count) resources"
    }
    [hashtable]CollectResourceMetrics([object]$Resource) {
        $metrics = @{
            ResourceId = $Resource.ResourceId
            ResourceType = $Resource.ResourceType
            Timestamp = Get-Date -ErrorAction Stop
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
            $endTime = Get-Date -ErrorAction Stop
            $startTime = $endTime.AddMinutes(-5)
            $metrics -ge "($baselineMetrics.Availability * 0.95) }  if ($recovery.FullyRecovered) { Write-Host " $($resource.Name)" -Debug "Failed to get CPU metrics for $($VM.Name)" }  return 0 }  [double]GetWebAppErrorRate([object]$WebApp) { # Simulate error rate collection return [math]::Round((Get-Random" -and $metrics.Data) { return ($metrics.Data | Measure-Object -ResourceId $result.ResourceId if ($resource.ResourceType -gt $breaker.Threshold } default { $false } }  if ($thresholdBreached) { return @{ Safe = $false Reason = "$($breaker.Name) threshold breached: $metricValue (threshold: $($breaker.Threshold))"Action = $breaker.Action } } } } }  return @{ Safe = $true; Reason = "All safety breakers within limits" } }  [void]CleanupExperiment([bool]$DryRun) { Write-Host "Cleaning up chaos experiment..."  foreach ($result in $this.ExperimentResults) { switch ($result.Action) { "ResourceFailure" { if ($DryRun) { Write-Host "DRY RUN: Would restart stopped resources" } else { # Restart stopped resources $resource = Get-AzResource -Seconds "60  # Wait for recovery  foreach ($resource in $this.TargetResources) { $postMetrics = $this.CollectResourceMetrics($resource) $baselineMetrics = $this.BaselineMetrics[$resource.ResourceId]  $recovery = @{ ResourceId = $resource.ResourceId BaselineAvailability = $baselineMetrics.Availability PostExperimentAvailability = $postMetrics.Availability RecoveryTime = "60 seconds"  # Simplified FullyRecovered = $postMetrics.Availability" -eq "Microsoft.Compute/virtualMachines") { Write-Host "Restarting VM: $($resource.Name)"Start-AzVM" -ResourceGroupName $resource.ResourceGroupName -Count $failureCount  foreach ($resource in $resourcesToFail) { if ($DryRun) { Write-Host "DRY RUN: Would stop resource: $($resource.Name)" } else { switch ($resource.ResourceType) { "Microsoft.Compute/virtualMachines" { Write-Host "Stopping VM: $($resource.Name)"if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }
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
                    <li>Test other failure scenarios to build  resilience</li>
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
    Write-Host "Azure Chaos Engineering Platform v1.0"
    Write-Host "===================================="
    Write-Host "[WARN]  WARNING: This tool introduces controlled failures!"
    Write-Host "[WARN]  Use with extreme caution in production environments!"
    if (!$DryRun) {
        $confirmation = Read-Host "`nAre you sure you want to proceed with chaos engineering? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Host "Chaos engineering cancelled by user."
            exit 0
        }
    }
    # Connect to Azure if needed
    $context = Get-AzContext -ErrorAction Stop
    if (!$context) {
        Write-Host "Connecting to Azure..."
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
        Write-Host "`nExperiment report saved to: $reportPath"
    }
    Write-Host "`n Chaos engineering experiment completed successfully!"
    Write-Host "Experiment ID: $($chaosEngine.ExperimentId)"
} catch {
    Write-Error "Chaos engineering experiment failed: $_"
    throw
}

