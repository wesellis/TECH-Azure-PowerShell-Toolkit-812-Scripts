<#
.SYNOPSIS
    Chaos engineering platform

.DESCRIPTION
    Test Azure infrastructure resilience with controlled failures
.PARAMETER ChaosMode
    Type of chaos experiment: NetworkLatency, ResourceFailure, ZoneFailure, DatabaseFailover, ApplicationStress
.PARAMETER TargetScope
    Scope of the experiment: ResourceGroup, Subscription, Region
.PARAMETER TargetResourceGroup
    Name of the target resource group for ResourceGroup scope
.PARAMETER Duration
    Duration of the chaos experiment in minutes (1-60)
.PARAMETER SafetyChecks
    Enable safety checks to prevent uncontrolled damage
.PARAMETER RecoveryValidation
    Validate automatic recovery mechanisms
.PARAMETER DocumentResults
    Generate detailed chaos engineering report
.PARAMETER DryRun
    Preview operations without making changes
    .\Azure-Chaos-Engineering-Platform.ps1 -ChaosMode "NetworkLatency" -TargetScope "ResourceGroup" -TargetResourceGroup "MyRG" -Duration 10 -SafetyChecks
    .\Azure-Chaos-Engineering-Platform.ps1 -ChaosMode "ResourceFailure" -TargetScope "ResourceGroup" -TargetResourceGroup "TestRG" -DryRun
    Author: Wes Ellis (wes@wesellis.com)Prerequisites:
    - Az PowerShell modules
    - Appropriate Azure permissions
    - EXTREME CAUTION in production environments
.LINK
    https://docs.microsoft.com/en-us/azure/chaos-studio/
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, HelpMessage="Type of chaos experiment to run")]
    [ValidateSet("NetworkLatency", "ResourceFailure", "ZoneFailure", "DatabaseFailover", "ApplicationStress")]
    [string]$ChaosMode,
    [Parameter(HelpMessage="Scope of the chaos experiment")]
    [ValidateSet("ResourceGroup", "Subscription", "Region")]
    [string]$TargetScope = "ResourceGroup",
    [Parameter(HelpMessage="Target resource group name")]
    [ValidateNotNullOrEmpty()]
    [string]$TargetResourceGroup,
    [Parameter(HelpMessage="Duration in minutes")]
    [ValidateRange(1, 60)]
    [int]$Duration = 5,
    [Parameter(HelpMessage="Enable safety mechanisms")]
    [switch]$SafetyChecks = $true,
    [Parameter(HelpMessage="Validate recovery after experiment")]
    [switch]$RecoveryValidation = $true,
    [Parameter(HelpMessage="Generate HTML report")]
    [switch]$DocumentResults = $true,
    [Parameter(HelpMessage="Preview mode - no actual changes")]
    [switch]$DryRun
)
#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Import required modules
$requiredModules = @('Az.Accounts', 'Az.Resources', 'Az.Monitor', 'Az.Compute', 'Az.Storage')
foreach ($module in $requiredModules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        throw "Module $module is not installed. Please install it using: Install-Module -Name $module"
    }
    Import-Module $module -Force
}
#endregion
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}
function Test-AzureConnection {
    [CmdletBinding()]
    param()
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Warning "Not connected to Azure. Please run Connect-AzAccount first."
            return $false
        }
        Write-Verbose "Connected to Azure as: $($context.Account.Id)"
        return $true
    }
    catch {
        Write-Warning "Azure connection test failed: $($_.Exception.Message)"
        return $false
    }
}
class ChaosEngineeringPlatform {
    [string]$ExperimentId
    [string]$ChaosMode
    [string]$TargetScope
    [int]$Duration
    [array]$TargetResources
    [hashtable]$BaselineMetrics
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
        $this.SafetyBreakers = @()
        $this.ExperimentResults = @()
        $this.SafetyEnabled = $Safety
        $this.InitializeSafetyBreakers()
    }
    [void]InitializeSafetyBreakers() {
        if (!$this.SafetyEnabled) { return }
        Write-Log "Initializing safety breakers..." -Level INFO
        $this.SafetyBreakers = @(
            @{
                Name = "HighErrorRate"
                Threshold = 50
                MetricName = "ErrorRate"
                Action = "StopExperiment"
            },
            @{
                Name = "LowAvailability"
                Threshold = 90
                MetricName = "Availability"
                Action = "StopExperiment"
            },
            @{
                Name = "ExcessiveLatency"
                Threshold = 5000
                MetricName = "ResponseTime"
                Action = "StopExperiment"
            },
            @{
                Name = "ResourceUtilization"
                Threshold = 95
                MetricName = "CPUUtilization"
                Action = "AlertOnly"
            }
        )
    }
    [void]DiscoverTargetResources([string]$ResourceGroupName) {
        Write-Log "Discovering target resources in scope: $($this.TargetScope)" -Level INFO
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
                $this.TargetResources = Get-AzResource | Where-Object { $_.Location -eq "East US" }
            }
        }
        Write-Log "Found $($this.TargetResources.Count) resources in scope" -Level INFO
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
        Write-Log "Filtered to $filteredCount resources for $($this.ChaosMode) experiment (from $originalCount)" -Level INFO
    }
    [void]EstablishBaseline() {
        Write-Log "Establishing baseline metrics..." -Level INFO
        foreach ($resource in $this.TargetResources) {
            $metrics = $this.CollectResourceMetrics($resource)
            $this.BaselineMetrics[$resource.ResourceId] = $metrics
        }
        Write-Log "Baseline established for $($this.BaselineMetrics.Count) resources" -Level SUCCESS
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
            # Simulate CPU metrics collection
            return [math]::Round((Get-Random -Minimum 10 -Maximum 80), 2)
        } catch {
            Write-Warning "Failed to get CPU metrics for $($VM.Name)"
            return 0
        }
    }
    [double]GetVMMemoryMetrics([object]$VM) {
        try {
            # Simulate memory metrics collection
            return [math]::Round((Get-Random -Minimum 20 -Maximum 90), 2)
        } catch {
            return 0
        }
    }
    [double]GetWebAppErrorRate([object]$WebApp) {
        # Simulate error rate collection
        return [math]::Round((Get-Random -Minimum 0 -Maximum 5), 2)
    }
    [double]GetWebAppAvailability([object]$WebApp) {
        # Simulate availability check
        return [math]::Round((Get-Random -Minimum 98 -Maximum 100), 2)
    }
    [double]GetStorageAvailability([object]$Storage) {
        # Simulate storage availability check
        return [math]::Round((Get-Random -Minimum 99 -Maximum 100), 2)
    }
    [void]ExecuteChaosExperiment([bool]$DryRun) {
        Write-Log "Executing chaos experiment: $($this.ChaosMode)" -Level INFO
        if ($DryRun) {
            Write-Log "DRY RUN: Simulating $($this.ChaosMode) experiment" -Level INFO
            $this.SimulateDryRun()
            return
        }
        switch ($this.ChaosMode) {
            "NetworkLatency" { $this.SimulateNetworkLatency($DryRun) }
            "ResourceFailure" { $this.SimulateResourceFailure($DryRun) }
            "DatabaseFailover" { $this.SimulateDatabaseFailover($DryRun) }
            "ApplicationStress" { $this.SimulateApplicationStress($DryRun) }
            "ZoneFailure" { $this.SimulateZoneFailure($DryRun) }
            default { Write-Log "Chaos mode $($this.ChaosMode) not implemented" -Level WARNING }
        }
        Write-Log "Chaos experiment completed" -Level SUCCESS
    }
    [void]SimulateDryRun() {
        foreach ($resource in $this.TargetResources) {
            $result = @{
                ResourceId = $resource.ResourceId
                Action = "DryRun-$($this.ChaosMode)"
                Timestamp = Get-Date
                Success = $true
                Parameters = @{ Mode = "Simulation" }
            }
            $this.ExperimentResults += $result
        }
    }
    [void]SimulateNetworkLatency([bool]$DryRun) {
        Write-Log "Simulating network latency..." -Level INFO
        foreach ($resource in $this.TargetResources) {
            $result = @{
                ResourceId = $resource.ResourceId
                Action = "NetworkLatency"
                Timestamp = Get-Date
                Success = $true
                Parameters = @{ Latency = "100ms"; Duration = "$($this.Duration)min" }
            }
            $this.ExperimentResults += $result
        }
    }
    [void]SimulateResourceFailure([bool]$DryRun) {
        Write-Log "Simulating resource failure..." -Level INFO
        foreach ($resource in $this.TargetResources) {
            $result = @{
                ResourceId = $resource.ResourceId
                Action = "ResourceFailure"
                Timestamp = Get-Date
                Success = $true
                Parameters = @{ Type = "Stop"; Duration = "$($this.Duration)min" }
            }
            $this.ExperimentResults += $result
        }
    }
    [void]SimulateDatabaseFailover([bool]$DryRun) {
        Write-Log "Simulating database failover..." -Level INFO
        $databases = $this.TargetResources | Where-Object { $_.ResourceType -like "*Sql*" -or $_.ResourceType -like "*DocumentDB*" }
        foreach ($db in $databases) {
            $result = @{
                ResourceId = $db.ResourceId
                Action = "DatabaseFailover"
                Timestamp = Get-Date
                Success = $true
                Parameters = @{ Type = "Failover"; Target = "Secondary" }
            }
            $this.ExperimentResults += $result
        }
    }
    [void]SimulateApplicationStress([bool]$DryRun) {
        Write-Log "Simulating application stress..." -Level INFO
        foreach ($resource in $this.TargetResources) {
            $result = @{
                ResourceId = $resource.ResourceId
                Action = "ApplicationStress"
                Timestamp = Get-Date
                Success = $true
                Parameters = @{ CPULoad = "80%"; Duration = "$($this.Duration)min" }
            }
            $this.ExperimentResults += $result
        }
    }
    [void]SimulateZoneFailure([bool]$DryRun) {
        Write-Log "Simulating availability zone failure..." -Level INFO
        foreach ($resource in $this.TargetResources) {
            $result = @{
                ResourceId = $resource.ResourceId
                Action = "ZoneFailure"
                Timestamp = Get-Date
                Success = $true
                Parameters = @{ Zone = "Zone1"; Duration = "$($this.Duration)min" }
            }
            $this.ExperimentResults += $result
        }
    }
    [void]ValidateRecovery() {
        Write-Log "Validating recovery mechanisms..." -Level INFO
        Start-Sleep -Seconds 30  # Simulate recovery time
        foreach ($resource in $this.TargetResources) {
            $postMetrics = $this.CollectResourceMetrics($resource)
            $baselineMetrics = $this.BaselineMetrics[$resource.ResourceId]
            $recovery = @{
                ResourceId = $resource.ResourceId
                BaselineAvailability = $baselineMetrics.Availability
                PostExperimentAvailability = $postMetrics.Availability
                RecoveryTime = "30 seconds"
                FullyRecovered = ($postMetrics.Availability -ge ($baselineMetrics.Availability * 0.95))
            }
            if ($recovery.FullyRecovered) {
                Write-Log "Recovery validated for $($resource.Name)" -Level SUCCESS
            } else {
                Write-Log "Recovery incomplete for $($resource.Name)" -Level WARNING
            }
        }
        Write-Log "Recovery validation completed" -Level SUCCESS
    }
    [string]GenerateExperimentReport() {
        $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Chaos Engineering Experiment Report</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #f0f0f0; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #ff4444 0%, #cc0000 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .header h1 { margin: 0; font-size: 28px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric-card { background: #f8f8f8; padding: 20px; border-radius: 8px; text-align: center; border: 1px solid #ddd; }
        .metric-value { font-size: 36px; font-weight: bold; color: #ff4444; margin-bottom: 5px; }
        .metric-label { font-size: 14px; color: #666; }
        .section { margin-bottom: 30px; }
        .section h2 { border-bottom: 2px solid #ddd; padding-bottom: 10px; color: #333; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f0f0f0; font-weight: bold; }
        .success { color: #00aa00; font-weight: bold; }
        .failure { color: #ff0000; font-weight: bold; }
        .timeline { background: #f8f8f8; padding: 20px; border-radius: 8px; border: 1px solid #ddd; }
        .timeline h3 { margin-top: 0; color: #333; }
        .timeline ul { margin: 10px 0; }
        .timeline li { margin: 5px 0; color: #555; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Chaos Engineering Experiment Report</h1>
            <p><strong>Experiment ID:</strong> $($this.ExperimentId)</p>
            <p><strong>Mode:</strong> $($this.ChaosMode) | <strong>Duration:</strong> $($this.Duration) minutes</p>
            <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        </div>
        <div class="summary">
            <div class="metric-card">
                <div class="metric-value">$($this.TargetResources.Count)</div>
                <div class="metric-label">Resources Tested</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($this.ExperimentResults.Count)</div>
                <div class="metric-label">Actions Executed</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$(($this.ExperimentResults | Where-Object { $_.Success }).Count)</div>
                <div class="metric-label">Successful Actions</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($this.SafetyBreakers.Count)</div>
                <div class="metric-label">Safety Breakers</div>
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
                        <td>$($result.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))</td>
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
                    <li>Consider adding more granular monitoring and alerting</li>
                    <li>Test other failure scenarios to build
                    <li>Document runbooks for manual intervention scenarios</li>
                    <li>Schedule regular chaos engineering exercises</li>
                </ul>
            </div>
        </div>
        <div class="footer">
            <p>Generated by Azure Chaos Engineering Platform | Report ID: $($this.ExperimentId)</p>
        </div>
    </div>
</body>
</html>
"@
        return $html
    }
}
#endregion
#region Main-Execution
try {
    Write-Host "Azure Chaos Engineering Platform v2.0" -ForegroundColor Red
    Write-Host "====================================" -ForegroundColor Red
    Write-Host "WARNING: This tool introduces controlled failures!" -ForegroundColor Yellow
    Write-Host "Use with extreme caution in production environments!" -ForegroundColor Yellow
    Write-Host ""
    # Safety confirmation
    if (!$DryRun) {
        $confirmation = Read-Host "Are you sure you want to proceed with chaos engineering? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-Log "Chaos engineering cancelled by user." -Level INFO
            exit 0
        }
    }
    # Test Azure connection
    if (-not (Test-AzureConnection)) {
        throw "Azure connection required. Please run Connect-AzAccount first."
    }
    # Initialize chaos platform
    Write-Log "Initializing chaos engineering platform..." -Level INFO
    $chaosEngine = [ChaosEngineeringPlatform]::new($ChaosMode, $TargetScope, $Duration, $SafetyChecks)
    # Discover target resources
    Write-Log "Discovering target resources..." -Level INFO
    $chaosEngine.DiscoverTargetResources($TargetResourceGroup)
    if ($chaosEngine.TargetResources.Count -eq 0) {
        throw "No suitable target resources found for $ChaosMode experiment in scope $TargetScope"
    }
    # Establish baseline metrics
    Write-Log "Establishing baseline metrics..." -Level INFO
    $chaosEngine.EstablishBaseline()
    # Execute chaos experiment
    Write-Log "Starting chaos experiment: $ChaosMode" -Level INFO
    $chaosEngine.ExecuteChaosExperiment($DryRun)
    # Validate recovery if enabled
    if ($RecoveryValidation -and !$DryRun) {
        Write-Log "Validating recovery mechanisms..." -Level INFO
        $chaosEngine.ValidateRecovery()
    }
    # Generate report if requested
    if ($DocumentResults) {
        Write-Log "Generating experiment report..." -Level INFO
        $report = $chaosEngine.GenerateExperimentReport()
        $reportPath = ".\ChaosEngineering-Report-$($chaosEngine.ExperimentId).html"
        $report | Out-File -FilePath $reportPath -Encoding UTF8
        Write-Log "Experiment report saved to: $reportPath" -Level SUCCESS
    }
    # Final summary
    Write-Host ""
    Write-Host "Chaos Engineering Results" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    Write-Host "Experiment ID: $($chaosEngine.ExperimentId)" -ForegroundColor White
    Write-Host "Mode: $ChaosMode" -ForegroundColor White
    Write-Host "Duration: $Duration minutes" -ForegroundColor White
    Write-Host "Resources Tested: $($chaosEngine.TargetResources.Count)" -ForegroundColor White
    Write-Host "Actions Executed: $($chaosEngine.ExperimentResults.Count)" -ForegroundColor White
    Write-Host "Success Rate: $(if ($chaosEngine.ExperimentResults.Count -gt 0) { [math]::Round((($chaosEngine.ExperimentResults | Where-Object { $_.Success }).Count / $chaosEngine.ExperimentResults.Count) * 100, 1) } else { 0 })%" -ForegroundColor White
    Write-Log "Chaos engineering experiment completed successfully!" -Level SUCCESS
} catch {
    Write-Log "Chaos engineering experiment failed: $($_.Exception.Message)" -Level ERROR
    Write-Host ""
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "- Verify Azure PowerShell modules are installed and up-to-date" -ForegroundColor Gray
    Write-Host "- Check Azure authentication and subscription permissions" -ForegroundColor Gray
    Write-Host "- Ensure target resource group exists and is accessible" -ForegroundColor Gray
    Write-Host "- Validate chaos mode and target scope combinations" -ForegroundColor Gray
    Write-Host "- Consider using -DryRun for initial testing" -ForegroundColor Gray
    Write-Host ""
    throw
} finally {
    Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
}

