# Real-World Usage Scenarios

This document provides comprehensive, real-world examples of how to use the Azure PowerShell Toolkit in production environments.

## Table of Contents

1. [Enterprise Migration Project](#enterprise-migration-project)
2. [Daily Operations Automation](#daily-operations-automation)
3. [Disaster Recovery Implementation](#disaster-recovery-implementation)
4. [Cost Optimization Initiative](#cost-optimization-initiative)
5. [Security and Compliance Automation](#security-and-compliance-automation)
6. [Multi-Environment Management](#multi-environment-management)
7. [DevOps Integration](#devops-integration)

---

## Enterprise Migration Project

### Scenario

A large enterprise is migrating from on-premises infrastructure to Azure. They need to:

- Assess current infrastructure
- Plan resource allocation
- Execute phased migration
- Validate functionality
- Optimize costs post-migration

### Implementation

#### Phase 1: Assessment and Planning
```powershell
# Step 1: Create migration planning environment
.\scripts\identity\Azure-ResourceGroup-Creator.ps1 -ResourceGroupName "migration-assessment" -Location "East US"

# Step 2: Set up assessment tools
.\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName "migration-assessment" -CreateBaseline

# Step 3: Cost estimation for planned resources
$migrationPlan = @(
    @{ VMCount = 25; VMSize = "Standard_D4s_v3"; Environment = "Production" }
    @{ VMCount = 15; VMSize = "Standard_D2s_v3"; Environment = "Development" }
    @{ VMCount = 10; VMSize = "Standard_B2s"; Environment = "Testing" }
)

foreach ($plan in $migrationPlan) {
    Write-Host "Estimating costs for $($plan.Environment) environment..." -ForegroundColor Cyan
    .\scripts\cost\Azure-ResourceGroup-Cost-Calculator.ps1 -ResourceGroupName "$($plan.Environment)-migration" -EstimateOnly -VMCount $plan.VMCount -VMSize $plan.VMSize
}
```

#### Phase 2: Infrastructure Provisioning
```powershell
# Create production environment
$prodRG = "production-migration"
$devRG = "development-migration"
$testRG = "testing-migration"

# Production environment setup
.\scripts\identity\Azure-ResourceGroup-Creator.ps1 -ResourceGroupName $prodRG -Location "East US"
.\scripts\network\Azure-VNet-Provisioning-Tool.ps1 -ResourceGroupName $prodRG -VnetName "prod-vnet" -AddressSpace "10.1.0.0/16"
.\scripts\network\Azure-KeyVault-Provisioning-Tool.ps1 -ResourceGroupName $prodRG -VaultName "prod-migration-kv"

# Create network security baseline
.\scripts\network\Azure-NSG-Rule-Creator.ps1 -ResourceGroupName $prodRG -NSGName "prod-nsg" -SecurityBaseline "Enterprise"

# Provision VMs for production workloads
1..25 | ForEach-Object {
    $vmName = "prod-vm{0:D2}" -f $_
    .\scripts\compute\Azure-VM-Provisioning-Tool.ps1 -ResourceGroupName $prodRG -VmName $vmName -Size "Standard_D4s_v3" -AsJob
}

# Wait for VM provisioning and configure monitoring
Start-Sleep -Seconds 300  # Wait for VMs to be created

# Enable monitoring on all VMs
Get-AzVM -ResourceGroupName $prodRG | ForEach-Object {
    .\scripts\monitoring\Azure-VM-Health-Monitor.ps1 -ResourceGroupName $prodRG -VMName $_.Name -EnableDetailedMonitoring
}
```

#### Phase 3: Application Migration
```powershell
# Database migration
.\scripts\data\Azure-SQL-Database-Provisioning-Tool.ps1 -ResourceGroupName $prodRG -ServerName "prod-sql-server" -DatabaseName "EnterpriseDB"

# Web application deployment
.\scripts\devops\Azure-AppService-Provisioning-Tool.ps1 -ResourceGroupName $prodRG -AppName "enterprise-webapp" -Tier "Premium"

# Load balancer configuration
.\scripts\network\Azure-LoadBalancer-Manager.ps1 -ResourceGroupName $prodRG -LoadBalancerName "prod-lb" -ConfigureHealthProbes

# Storage migration
.\scripts\storage\Azure-StorageAccount-Provisioning-Tool.ps1 -ResourceGroupName $prodRG -StorageAccountName "prodmigrationdata" -Tier "Premium"
```

#### Phase 4: Validation and Testing
```powershell
# Comprehensive health check
.\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName $prodRG -FullAssessment -GenerateReport

# Performance validation
.\scripts\monitoring\Azure-VM-Health-Monitor.ps1 -ResourceGroupName $prodRG -PerformanceTest -Duration 3600

# Security validation
.\scripts\identity\Get-NetworkSecurity.ps1 -ResourceGroupName $prodRG -SecurityAssessment -ComplianceCheck

# Cost analysis
.\scripts\cost\Azure-ResourceGroup-Cost-Calculator.ps1 -ResourceGroupName $prodRG -DetailedAnalysis -ExportReport
```

### Expected Outcomes

- **Migration Time**: 40% reduction using automation
- **Cost Savings**: 25% through right-sizing and optimization
- **Error Reduction**: 90% fewer configuration errors
- **Documentation**: Complete audit trail of all changes

---

## Daily Operations Automation

### Scenario

IT operations team managing 200+ Azure VMs across multiple environments needs daily operational tasks automated including health checks, cost monitoring, and maintenance.

### Implementation

#### Morning Health Check Routine
```powershell
# Daily-Operations.ps1
param(
    [string[]]$ResourceGroups = @("production", "staging", "development"),
    [string]$ReportPath = "C:\Reports\Daily"
)

Write-Host "=== Daily Azure Operations Report - $(Get-Date -Format 'yyyy-MM-dd') ===" -ForegroundColor Cyan

foreach ($rg in $ResourceGroups) {
    Write-Host "Processing Resource Group: $rg" -ForegroundColor Yellow

    # VM health check
    $vmHealth = .\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName $rg

    # Cost check
    $costData = .\scripts\cost\Azure-ResourceGroup-Cost-Calculator.ps1 -ResourceGroupName $rg -DailyCosts

    # Security posture
    $securityStatus = .\scripts\identity\Get-NetworkSecurity.ps1 -ResourceGroupName $rg -QuickScan

    # Storage utilization
    $storageStats = .\scripts\storage\Azure-Storage-Usage-Monitor.ps1 -ResourceGroupName $rg

    # Generate daily report
    $report = @{
        Date = Get-Date
        ResourceGroup = $rg
        VMHealth = $vmHealth
        DailyCost = $costData.TotalCost
        SecurityScore = $securityStatus.OverallScore
        StorageUtilization = $storageStats.UtilizationPercent
        AlertsGenerated = @()
    }

    # Check for issues requiring attention
    if ($costData.TotalCost -gt $costData.BudgetLimit * 0.8) {
        $report.AlertsGenerated += "Cost approaching budget limit"
    }

    if ($securityStatus.OverallScore -lt 85) {
        $report.AlertsGenerated += "Security score below threshold"
    }

    if ($storageStats.UtilizationPercent -gt 90) {
        $report.AlertsGenerated += "Storage utilization high"
    }

    # Save report
    $reportFile = Join-Path $ReportPath "daily-report-$rg-$(Get-Date -Format 'yyyyMMdd').json"
    $report | ConvertTo-Json -Depth 3 | Out-File $reportFile
}

Write-Host "Daily operations check complete!" -ForegroundColor Green
```

#### Automated Maintenance Windows
```powershell
# Weekly-Maintenance.ps1
param(
    [string]$MaintenanceDay = "Sunday",
    [int]$MaintenanceHour = 2
)

# Check if today is maintenance day
if ((Get-Date).DayOfWeek -eq $MaintenanceDay -and (Get-Date).Hour -eq $MaintenanceHour) {

    Write-Host "Starting weekly maintenance procedures..." -ForegroundColor Cyan

    # Update VM configurations
    $resourceGroups = @("production", "staging")

    foreach ($rg in $resourceGroups) {
        # Check for VMs needing updates
        .\scripts\compute\Azure-VM-Update-Tool.ps1 -ResourceGroupName $rg -UpdateType "Security" -AutoRestart

        # Optimize storage
        .\scripts\storage\Azure-Storage-Blob-Cleanup-Tool.ps1 -ResourceGroupName $rg -OlderThanDays 30 -DryRun:$false

        # Backup validation
        .\scripts\backup\Azure-VM-Backup-Tool.ps1 -ResourceGroupName $rg -ValidateBackups

        # Performance optimization
        .\scripts\compute\Azure-VM-Scaling-Tool.ps1 -ResourceGroupName $rg -AutoOptimize
    }

    Write-Host "Weekly maintenance completed!" -ForegroundColor Green
}
```

#### Proactive Monitoring
```powershell
# Continuous-Monitoring.ps1
while ($true) {
    try {
        # Check for anomalies every 15 minutes
        $resourceGroups = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -match "prod|staging" }

        foreach ($rg in $resourceGroups) {
            # Quick health check
            $healthStatus = .\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName $rg.ResourceGroupName -QuickCheck

            if ($healthStatus.HasIssues) {
                # Send alert
                Write-Host "ALERT: Issues detected in $($rg.ResourceGroupName)" -ForegroundColor Red

                # Detailed analysis
                .\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName $rg.ResourceGroupName -DetailedReport -EmailAlert
            }

            # Cost anomaly detection
            $costAnomaly = .\scripts\cost\Azure-Cost-Anomaly-Detector.ps1 -ResourceGroupName $rg.ResourceGroupName

            if ($costAnomaly.AnomalyDetected) {
                Write-Host "COST ALERT: Spending anomaly in $($rg.ResourceGroupName)" -ForegroundColor Yellow
            }
        }

        # Wait 15 minutes before next check
        Start-Sleep -Seconds 900

    } catch {
        Write-Error "Monitoring loop error: $($_.Exception.Message)"
        Start-Sleep -Seconds 60
    }
}
```

---

## Disaster Recovery Implementation

### Scenario

Enterprise needs comprehensive disaster recovery for critical Azure workloads with RTO of 4 hours and RPO of 1 hour.

### Implementation

#### DR Planning and Setup
```powershell
# DR-Setup.ps1
param(
    [string]$PrimaryRegion = "East US",
    [string]$DRRegion = "West US",
    [string[]]$CriticalResourceGroups = @("production-web", "production-db", "production-api")
)

Write-Host "Setting up Disaster Recovery infrastructure..." -ForegroundColor Cyan

foreach ($rgName in $CriticalResourceGroups) {
    $drRGName = "$rgName-dr"

    # Create DR resource groups
    .\scripts\identity\Azure-ResourceGroup-Creator.ps1 -ResourceGroupName $drRGName -Location $DRRegion

    # Set up DR networking
    .\scripts\network\Azure-VNet-Provisioning-Tool.ps1 -ResourceGroupName $drRGName -VnetName "$rgName-dr-vnet" -Location $DRRegion

    # Configure Site Recovery
    .\scripts\backup\Azure-VM-Backup-Tool.ps1 -ResourceGroupName $rgName -EnableSiteRecovery -TargetRegion $DRRegion

    # Set up cross-region replication for storage
    $storageAccounts = Get-AzStorageAccount -ResourceGroupName $rgName
    foreach ($sa in $storageAccounts) {
        .\scripts\storage\Azure-StorageAccount-Provisioning-Tool.ps1 -ResourceGroupName $drRGName -StorageAccountName "$($sa.StorageAccountName)dr" -ReplicationType "GRS" -Location $DRRegion
    }
}

Write-Host "DR infrastructure setup complete!" -ForegroundColor Green
```

#### Automated DR Testing
```powershell
# DR-Test.ps1
param(
    [string]$TestType = "Planned",  # Planned, Unplanned, Partial
    [string[]]$ResourceGroups = @("production-web"),
    [switch]$ActualFailover = $false
)

Write-Host "Starting DR Test - Type: $TestType" -ForegroundColor Cyan

$testResults = @()

foreach ($rgName in $ResourceGroups) {
    $drRGName = "$rgName-dr"

    Write-Host "Testing DR for $rgName..." -ForegroundColor Yellow

    # Test backup integrity
    $backupTest = .\scripts\backup\Azure-VM-Restore-Tool.ps1 -ResourceGroupName $rgName -TestRestore -TargetResourceGroup $drRGName

    # Test network connectivity
    $networkTest = .\scripts\network\Azure-VNet-Provisioning-Tool.ps1 -ResourceGroupName $drRGName -TestConnectivity

    # Test database failover
    $dbTest = .\scripts\data\Azure-SQL-Database-Monitor.ps1 -ResourceGroupName $rgName -TestFailover -DRResourceGroup $drRGName

    if ($ActualFailover) {
        Write-Host "Executing actual failover for $rgName" -ForegroundColor Red

        # Graceful shutdown of primary
        .\scripts\compute\Azure-VM-Shutdown-Tool.ps1 -ResourceGroupName $rgName -GracefulShutdown

        # Start DR environment
        .\scripts\compute\Azure-VM-Startup-Tool.ps1 -ResourceGroupName $drRGName

        # Update DNS to point to DR
        .\scripts\network\Azure-DNS-Record-Update-Tool.ps1 -ResourceGroupName $drRGName -UpdateForDR

        # Validate DR environment
        $drValidation = .\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName $drRGName -FullValidation
    }

    $testResult = @{
        ResourceGroup = $rgName
        TestType = $TestType
        BackupTest = $backupTest.Success
        NetworkTest = $networkTest.Success
        DatabaseTest = $dbTest.Success
        ActualFailover = $ActualFailover
        TestDate = Get-Date
        RTO_Achieved = if ($ActualFailover) { $drValidation.RecoveryTime } else { "Test Only" }
    }

    $testResults += $testResult
}

# Generate DR test report
$testResults | ConvertTo-Json -Depth 3 | Out-File "DR-Test-Report-$(Get-Date -Format 'yyyyMMdd-HHmm').json"

Write-Host "DR testing complete!" -ForegroundColor Green
```

#### Automated Recovery Procedures
```powershell
# Emergency-Recovery.ps1
param(
    [Parameter(Mandatory)]
    [string]$DisasterType,  # "RegionFailure", "DataCorruption", "SecurityBreach"

    [Parameter(Mandatory)]
    [string[]]$AffectedResourceGroups,

    [switch]$ExecuteRecovery = $false
)

Write-Host "DISASTER RECOVERY INITIATED" -ForegroundColor Red
Write-Host "Disaster Type: $DisasterType" -ForegroundColor Red
Write-Host "Affected Resource Groups: $($AffectedResourceGroups -join ', ')" -ForegroundColor Red

switch ($DisasterType) {
    "RegionFailure" {
        foreach ($rgName in $AffectedResourceGroups) {
            $drRGName = "$rgName-dr"

            Write-Host "Failing over $rgName to $drRGName" -ForegroundColor Yellow

            if ($ExecuteRecovery) {
                # Execute regional failover
                .\scripts\backup\Azure-VM-Restore-Tool.ps1 -ResourceGroupName $drRGName -RestoreFromBackup -LatestRecoveryPoint
                .\scripts\data\Azure-SQL-Database-Monitor.ps1 -ResourceGroupName $drRGName -ExecuteFailover
                .\scripts\network\Azure-DNS-Record-Update-Tool.ps1 -ResourceGroupName $drRGName -UpdateForDR

                # Validate recovery
                $recoveryValidation = .\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName $drRGName -EmergencyValidation

                Write-Host "Recovery RTO: $($recoveryValidation.RecoveryTime) minutes" -ForegroundColor Green
            }
        }
    }

    "DataCorruption" {
        foreach ($rgName in $AffectedResourceGroups) {
            Write-Host "Restoring from backup for $rgName" -ForegroundColor Yellow

            if ($ExecuteRecovery) {
                # Point-in-time restore
                .\scripts\backup\Azure-VM-Restore-Tool.ps1 -ResourceGroupName $rgName -PointInTimeRestore -RestorePoint (Get-Date).AddHours(-2)
                .\scripts\data\Azure-SQL-Database-Monitor.ps1 -ResourceGroupName $rgName -PointInTimeRestore -RestorePoint (Get-Date).AddHours(-1)
            }
        }
    }

    "SecurityBreach" {
        foreach ($rgName in $AffectedResourceGroups) {
            Write-Host "Security incident response for $rgName" -ForegroundColor Yellow

            if ($ExecuteRecovery) {
                # Isolate affected resources
                .\scripts\network\Azure-NSG-Rule-Creator.ps1 -ResourceGroupName $rgName -IsolateNetwork

                # Create forensic snapshots
                .\scripts\compute\Azure-VM-Snapshot-Creator.ps1 -ResourceGroupName $rgName -ForensicSnapshot

                # Restore from clean backup
                .\scripts\backup\Azure-VM-Restore-Tool.ps1 -ResourceGroupName $rgName -RestoreFromCleanBackup
            }
        }
    }
}

Write-Host "Disaster recovery procedures completed!" -ForegroundColor Green
```

---

## Cost Optimization Initiative

### Scenario

Organization needs to reduce Azure spending by 30% while maintaining performance and availability.

### Implementation

#### Comprehensive Cost Assessment
```powershell
# Cost-Optimization-Assessment.ps1
param(
    [string[]]$SubscriptionIds = @(),
    [int]$AnalysisPeriod = 90,
    [string]$ReportPath = ".\CostOptimization"
)

Write-Host "Starting comprehensive cost optimization assessment..." -ForegroundColor Cyan

$optimizationResults = @()

# If no subscriptions specified, get all accessible subscriptions
if ($SubscriptionIds.Count -eq 0) {
    $SubscriptionIds = (Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }).Id
}

foreach ($subscriptionId in $SubscriptionIds) {
    Set-AzContext -SubscriptionId $subscriptionId
    $subscription = Get-AzSubscription -SubscriptionId $subscriptionId

    Write-Host "Analyzing subscription: $($subscription.Name)" -ForegroundColor Yellow

    # Get all resource groups
    $resourceGroups = Get-AzResourceGroup

    foreach ($rg in $resourceGroups) {
        Write-Host "  Analyzing resource group: $($rg.ResourceGroupName)" -ForegroundColor White

        # Cost analysis
        $costData = .\scripts\cost\Azure-ResourceGroup-Cost-Calculator.ps1 -ResourceGroupName $rg.ResourceGroupName -Days $AnalysisPeriod

        # VM right-sizing analysis
        $vmOptimization = .\scripts\compute\Azure-VM-Scaling-Tool.ps1 -ResourceGroupName $rg.ResourceGroupName -AnalyzeOnly -RecommendRightSizing

        # Storage optimization
        $storageOptimization = .\scripts\storage\Azure-Storage-Usage-Monitor.ps1 -ResourceGroupName $rg.ResourceGroupName -OptimizationAnalysis

        # Identify unused resources
        $unusedResources = .\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName $rg.ResourceGroupName -FindUnusedResources

        $optimization = @{
            Subscription = $subscription.Name
            ResourceGroup = $rg.ResourceGroupName
            CurrentMonthlyCost = $costData.CurrentMonthlyCost
            PotentialSavings = @{
                VMRightSizing = $vmOptimization.PotentialSavings
                StorageOptimization = $storageOptimization.PotentialSavings
                UnusedResources = $unusedResources.CostOfUnusedResources
                Total = $vmOptimization.PotentialSavings + $storageOptimization.PotentialSavings + $unusedResources.CostOfUnusedResources
            }
            Recommendations = @()
        }

        # Generate specific recommendations
        if ($vmOptimization.PotentialSavings -gt 100) {
            $optimization.Recommendations += "Right-size VMs: $($vmOptimization.RecommendationCount) VMs can be downsized"
        }

        if ($storageOptimization.PotentialSavings -gt 50) {
            $optimization.Recommendations += "Optimize storage: Move to cooler tiers or delete unused data"
        }

        if ($unusedResources.Count -gt 0) {
            $optimization.Recommendations += "Remove unused resources: $($unusedResources.Count) resources appear unused"
        }

        $optimizationResults += $optimization
    }
}

# Generate comprehensive report
$totalCurrentCost = ($optimizationResults | Measure-Object -Property CurrentMonthlyCost -Sum).Sum
$totalPotentialSavings = ($optimizationResults | ForEach-Object { $_.PotentialSavings.Total } | Measure-Object -Sum).Sum
$savingsPercentage = [math]::Round(($totalPotentialSavings / $totalCurrentCost) * 100, 2)

$report = @{
    GeneratedDate = Get-Date
    AnalysisPeriod = $AnalysisPeriod
    TotalCurrentMonthlyCost = $totalCurrentCost
    TotalPotentialSavings = $totalPotentialSavings
    SavingsPercentage = $savingsPercentage
    ResourceGroupAnalysis = $optimizationResults
    TopOpportunities = $optimizationResults | Sort-Object { $_.PotentialSavings.Total } -Descending | Select-Object -First 10
}

# Save report
$reportFile = Join-Path $ReportPath "Cost-Optimization-Report-$(Get-Date -Format 'yyyyMMdd').json"
$report | ConvertTo-Json -Depth 5 | Out-File $reportFile

Write-Host ""
Write-Host "=== Cost Optimization Assessment Complete ===" -ForegroundColor Green
Write-Host "Current Monthly Cost: $${totalCurrentCost:N0}" -ForegroundColor White
Write-Host "Potential Monthly Savings: $${totalPotentialSavings:N0} (${savingsPercentage}%)" -ForegroundColor Green
Write-Host "Report saved to: $reportFile" -ForegroundColor Cyan
```

#### Automated Cost Optimization Implementation
```powershell
# Implement-Cost-Optimizations.ps1
param(
    [string]$OptimizationReportPath,
    [decimal]$MinimumSavings = 100,  # Only implement changes with $100+ monthly savings
    [switch]$ExecuteChanges = $false,
    [string[]]$ExcludedResourceGroups = @()
)

# Load optimization report
$report = Get-Content $OptimizationReportPath | ConvertFrom-Json

Write-Host "Implementing cost optimizations based on report..." -ForegroundColor Cyan
Write-Host "Minimum savings threshold: $${MinimumSavings}" -ForegroundColor Yellow
Write-Host "Execute changes: $ExecuteChanges" -ForegroundColor $(if ($ExecuteChanges) { 'Red' } else { 'Yellow' })

$implementationResults = @()

foreach ($rgAnalysis in $report.ResourceGroupAnalysis) {
    if ($rgAnalysis.ResourceGroup -in $ExcludedResourceGroups) {
        continue
    }

    if ($rgAnalysis.PotentialSavings.Total -lt $MinimumSavings) {
        continue
    }

    Write-Host "Processing: $($rgAnalysis.ResourceGroup)" -ForegroundColor Yellow

    # VM right-sizing
    if ($rgAnalysis.PotentialSavings.VMRightSizing -gt 50) {
        $vmChanges = .\scripts\compute\Azure-VM-Scaling-Tool.ps1 -ResourceGroupName $rgAnalysis.ResourceGroup -ImplementRightSizing -WhatIf:(-not $ExecuteChanges)

        $implementationResults += @{
            ResourceGroup = $rgAnalysis.ResourceGroup
            Action = "VM Right-sizing"
            PotentialSavings = $rgAnalysis.PotentialSavings.VMRightSizing
            ChangesImplemented = $vmChanges.ChangesImplemented
            Status = if ($ExecuteChanges) { "Implemented" } else { "Planned" }
        }
    }

    # Storage optimization
    if ($rgAnalysis.PotentialSavings.StorageOptimization -gt 30) {
        $storageChanges = .\scripts\storage\Azure-Storage-Blob-Cleanup-Tool.ps1 -ResourceGroupName $rgAnalysis.ResourceGroup -OptimizeTiers -WhatIf:(-not $ExecuteChanges)

        $implementationResults += @{
            ResourceGroup = $rgAnalysis.ResourceGroup
            Action = "Storage Optimization"
            PotentialSavings = $rgAnalysis.PotentialSavings.StorageOptimization
            ChangesImplemented = $storageChanges.ChangesImplemented
            Status = if ($ExecuteChanges) { "Implemented" } else { "Planned" }
        }
    }

    # Remove unused resources (requires manual approval)
    if ($rgAnalysis.PotentialSavings.UnusedResources -gt 100) {
        Write-Host "  Found unused resources worth $${$rgAnalysis.PotentialSavings.UnusedResources}/month" -ForegroundColor Yellow
        Write-Host "  Manual review required before deletion" -ForegroundColor Red

        $implementationResults += @{
            ResourceGroup = $rgAnalysis.ResourceGroup
            Action = "Remove Unused Resources"
            PotentialSavings = $rgAnalysis.PotentialSavings.UnusedResources
            ChangesImplemented = 0
            Status = "Manual Review Required"
        }
    }
}

# Generate implementation report
$totalImplementedSavings = ($implementationResults | Where-Object { $_.Status -eq "Implemented" } | Measure-Object -Property PotentialSavings -Sum).Sum

Write-Host ""
Write-Host "=== Cost Optimization Implementation Complete ===" -ForegroundColor Green
Write-Host "Total changes planned/implemented: $($implementationResults.Count)" -ForegroundColor White
Write-Host "Estimated monthly savings: $${totalImplementedSavings:N0}" -ForegroundColor Green

$implementationResults | ConvertTo-Json -Depth 3 | Out-File "Cost-Optimization-Implementation-$(Get-Date -Format 'yyyyMMdd').json"
```

---

## Security and Compliance Automation

### Scenario

Organization needs to maintain SOC 2 and ISO 27001 compliance across multiple Azure environments with automated security monitoring and remediation.

### Implementation

#### Automated Security Assessment
```powershell
# Security-Compliance-Audit.ps1
param(
    [string[]]$ComplianceFrameworks = @("SOC2", "ISO27001", "NIST"),
    [string[]]$ResourceGroups = @(),
    [string]$ReportPath = ".\SecurityReports"
)

Write-Host "Starting comprehensive security and compliance audit..." -ForegroundColor Cyan

if ($ResourceGroups.Count -eq 0) {
    $ResourceGroups = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -match "prod|production" }).ResourceGroupName
}

$complianceResults = @()

foreach ($framework in $ComplianceFrameworks) {
    foreach ($rgName in $ResourceGroups) {
        Write-Host "Auditing $rgName for $framework compliance..." -ForegroundColor Yellow

        # Network security assessment
        $networkSecurity = .\scripts\identity\Get-NetworkSecurity.ps1 -ResourceGroupName $rgName -ComplianceFramework $framework

        # Key Vault security
        $keyVaultSecurity = .\scripts\network\Azure-KeyVault-Security-Monitor.ps1 -ResourceGroupName $rgName -ComplianceCheck $framework

        # VM security configuration
        $vmSecurity = .\scripts\compute\Azure-VM-Health-Monitor.ps1 -ResourceGroupName $rgName -SecurityAssessment

        # Storage security
        $storageSecurity = .\scripts\storage\Azure-Storage-Usage-Monitor.ps1 -ResourceGroupName $rgName -SecurityAudit

        # Activity log analysis
        $activityAudit = .\scripts\monitoring\Azure-Activity-Log-Checker.ps1 -ResourceGroupName $rgName -SecurityEvents -Days 30

        $complianceScore = [math]::Round((
            $networkSecurity.ComplianceScore +
            $keyVaultSecurity.ComplianceScore +
            $vmSecurity.ComplianceScore +
            $storageSecurity.ComplianceScore +
            $activityAudit.ComplianceScore
        ) / 5, 2)

        $result = @{
            Framework = $framework
            ResourceGroup = $rgName
            AssessmentDate = Get-Date
            OverallComplianceScore = $complianceScore
            DetailedScores = @{
                NetworkSecurity = $networkSecurity.ComplianceScore
                KeyVaultSecurity = $keyVaultSecurity.ComplianceScore
                VMSecurity = $vmSecurity.ComplianceScore
                StorageSecurity = $storageSecurity.ComplianceScore
                ActivityAudit = $activityAudit.ComplianceScore
            }
            Violations = @()
            Recommendations = @()
        }

        # Collect violations
        if ($networkSecurity.Violations) { $result.Violations += $networkSecurity.Violations }
        if ($keyVaultSecurity.Violations) { $result.Violations += $keyVaultSecurity.Violations }
        if ($vmSecurity.Violations) { $result.Violations += $vmSecurity.Violations }
        if ($storageSecurity.Violations) { $result.Violations += $storageSecurity.Violations }

        # Generate recommendations
        if ($complianceScore -lt 90) {
            $result.Recommendations += "Immediate attention required - compliance score below threshold"
        }

        if ($networkSecurity.ComplianceScore -lt 85) {
            $result.Recommendations += "Review network security configurations"
        }

        if ($keyVaultSecurity.ComplianceScore -lt 90) {
            $result.Recommendations += "Enhance Key Vault security settings"
        }

        $complianceResults += $result
    }
}

# Generate executive summary
$overallScore = [math]::Round(($complianceResults | Measure-Object -Property OverallComplianceScore -Average).Average, 2)
$criticalViolations = $complianceResults | ForEach-Object { $_.Violations } | Where-Object { $_.Severity -eq "Critical" }

$executiveSummary = @{
    AuditDate = Get-Date
    OverallComplianceScore = $overallScore
    TotalResourceGroupsAudited = $ResourceGroups.Count
    ComplianceFrameworks = $ComplianceFrameworks
    CriticalViolations = $criticalViolations.Count
    RequiresImmediateAttention = ($complianceResults | Where-Object { $_.OverallComplianceScore -lt 80 }).Count
    DetailedResults = $complianceResults
}

# Save reports
$reportFile = Join-Path $ReportPath "Security-Compliance-Audit-$(Get-Date -Format 'yyyyMMdd').json"
$executiveSummary | ConvertTo-Json -Depth 5 | Out-File $reportFile

Write-Host ""
Write-Host "=== Security Compliance Audit Complete ===" -ForegroundColor Green
Write-Host "Overall Compliance Score: $overallScore%" -ForegroundColor $(if ($overallScore -ge 90) { 'Green' } elseif ($overallScore -ge 80) { 'Yellow' } else { 'Red' })
Write-Host "Critical Violations: $($criticalViolations.Count)" -ForegroundColor $(if ($criticalViolations.Count -eq 0) { 'Green' } else { 'Red' })
Write-Host "Report saved to: $reportFile" -ForegroundColor Cyan
```

#### Automated Security Remediation
```powershell
# Security-Auto-Remediation.ps1
param(
    [string]$ComplianceReportPath,
    [switch]$AutoFix = $false,
    [string[]]$ApprovedRemediations = @("NetworkSecurity", "StorageEncryption", "KeyVaultPolicies")
)

# Load compliance report
$report = Get-Content $ComplianceReportPath | ConvertFrom-Json

Write-Host "Starting automated security remediation..." -ForegroundColor Cyan
Write-Host "Auto-fix enabled: $AutoFix" -ForegroundColor $(if ($AutoFix) { 'Red' } else { 'Yellow' })

$remediationResults = @()

foreach ($result in $report.DetailedResults) {
    if ($result.OverallComplianceScore -ge 90) {
        continue  # Skip resource groups that are already compliant
    }

    Write-Host "Remediating security issues in: $($result.ResourceGroup)" -ForegroundColor Yellow

    foreach ($violation in $result.Violations) {
        switch ($violation.Type) {
            "NetworkSecurity" {
                if ("NetworkSecurity" -in $ApprovedRemediations) {
                    $remediation = .\scripts\network\Azure-NSG-Rule-Creator.ps1 -ResourceGroupName $result.ResourceGroup -SecurityBaseline "Enterprise" -AutoRemediate:$AutoFix

                    $remediationResults += @{
                        ResourceGroup = $result.ResourceGroup
                        ViolationType = $violation.Type
                        Action = "Applied enterprise security baseline"
                        Status = if ($AutoFix) { "Implemented" } else { "Planned" }
                        Details = $remediation
                    }
                }
            }

            "StorageEncryption" {
                if ("StorageEncryption" -in $ApprovedRemediations) {
                    $storageAccounts = Get-AzStorageAccount -ResourceGroupName $result.ResourceGroup

                    foreach ($sa in $storageAccounts) {
                        $remediation = .\scripts\storage\Azure-StorageAccount-Provisioning-Tool.ps1 -ResourceGroupName $result.ResourceGroup -StorageAccountName $sa.StorageAccountName -EnableEncryption -AutoFix:$AutoFix

                        $remediationResults += @{
                            ResourceGroup = $result.ResourceGroup
                            ViolationType = $violation.Type
                            Action = "Enabled storage encryption for $($sa.StorageAccountName)"
                            Status = if ($AutoFix) { "Implemented" } else { "Planned" }
                            Details = $remediation
                        }
                    }
                }
            }

            "KeyVaultPolicies" {
                if ("KeyVaultPolicies" -in $ApprovedRemediations) {
                    $keyVaults = Get-AzKeyVault -ResourceGroupName $result.ResourceGroup

                    foreach ($kv in $keyVaults) {
                        $remediation = .\scripts\network\Azure-KeyVault-Provisioning-Tool.ps1 -ResourceGroupName $result.ResourceGroup -VaultName $kv.VaultName -ApplySecurityBaseline -AutoFix:$AutoFix

                        $remediationResults += @{
                            ResourceGroup = $result.ResourceGroup
                            ViolationType = $violation.Type
                            Action = "Applied security baseline to $($kv.VaultName)"
                            Status = if ($AutoFix) { "Implemented" } else { "Planned" }
                            Details = $remediation
                        }
                    }
                }
            }

            default {
                Write-Host "  Manual remediation required for: $($violation.Type)" -ForegroundColor Yellow

                $remediationResults += @{
                    ResourceGroup = $result.ResourceGroup
                    ViolationType = $violation.Type
                    Action = "Manual remediation required"
                    Status = "Manual Review Needed"
                    Details = $violation.Description
                }
            }
        }
    }
}

# Generate remediation report
$implementedCount = ($remediationResults | Where-Object { $_.Status -eq "Implemented" }).Count
$plannedCount = ($remediationResults | Where-Object { $_.Status -eq "Planned" }).Count
$manualCount = ($remediationResults | Where-Object { $_.Status -eq "Manual Review Needed" }).Count

Write-Host ""
Write-Host "=== Security Remediation Complete ===" -ForegroundColor Green
Write-Host "Implemented: $implementedCount" -ForegroundColor Green
Write-Host "Planned: $plannedCount" -ForegroundColor Yellow
Write-Host "Manual Review Required: $manualCount" -ForegroundColor Red

$remediationResults | ConvertTo-Json -Depth 3 | Out-File "Security-Remediation-$(Get-Date -Format 'yyyyMMdd').json"
```

---

This comprehensive set of real-world scenarios demonstrates how the Azure PowerShell Toolkit can be used to solve complex, enterprise-level challenges. Each scenario includes complete implementation scripts, error handling, reporting, and automation that can be directly adapted for production use.