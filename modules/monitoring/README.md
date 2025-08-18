# Az.Monitoring.Enterprise Module

Enterprise-grade Azure Monitoring and observability management module with comprehensive automation capabilities.

## Features

### 📊 Log Analytics Workspace Management
- Advanced workspace deployment with enterprise features
- Automated data source configuration
- Solution enablement and management
- Capacity reservation and retention policies
- Network isolation support

### 📈 Custom Metrics Creation
- Business KPI tracking
- Application performance metrics
- Custom dimension support
- Metric aggregation and analysis
- Integration with Azure Monitor

### 🚨 Alert Rule Automation
- Multi-condition metric alerts
- Dynamic threshold support
- KQL-based log query alerts
- Alert correlation and grouping
- Auto-resolution capabilities

### 📋 Dashboard Deployment
- Template-based dashboard creation
- Customizable visualization tiles
- Real-time data integration
- Role-based access control
- Export/import functionality

### 📑 Workbook Templates
- Pre-built analysis templates
- Performance monitoring workbooks
- Availability tracking
- Failure analysis
- Custom visualization support

### 📢 Action Group Management
- Multi-channel notifications
- Email, SMS, and voice alerts
- Webhook integration
- Automation runbook triggers
- Logic App and Function connectors

## Installation

```powershell
# Install from PowerShell Gallery (when published)
Install-Module -Name Az.Monitoring.Enterprise -Scope CurrentUser

# Or install from source
Import-Module .\Az.Monitoring.Enterprise.psd1
```

## Quick Start

### Create Enterprise Log Analytics Workspace

```powershell
# Basic workspace creation
New-AzLogAnalyticsWorkspaceAdvanced -WorkspaceName "Enterprise-LAW" `
    -ResourceGroupName "Monitoring-RG" `
    -Location "eastus" `
    -RetentionInDays 90

# Advanced workspace with solutions
New-AzLogAnalyticsWorkspaceAdvanced -WorkspaceName "Production-LAW" `
    -ResourceGroupName "Monitoring-RG" `
    -Location "eastus" `
    -Sku "PerGB2018" `
    -RetentionInDays 180 `
    -CapacityReservationLevel 500 `
    -Solutions @('Security', 'Updates', 'SQLAssessment', 'VMInsights')
```

### Configure Data Sources

```powershell
# Configure all standard data sources
Set-AzLogAnalyticsDataSources -WorkspaceName "Enterprise-LAW" `
    -ResourceGroupName "Monitoring-RG" `
    -EnableAllDataSources

# Enable specific solutions
Enable-AzLogAnalyticsSolution -WorkspaceName "Enterprise-LAW" `
    -ResourceGroupName "Monitoring-RG" `
    -SolutionName "SecurityInsights"
```

### Create Custom Metrics

```powershell
# Track business metrics
New-AzCustomMetric -ResourceId $appResourceId `
    -MetricName "OrderProcessingTime" `
    -Value 150 `
    -Unit "Milliseconds" `
    -Dimensions @{Region="EastUS"; CustomerTier="Premium"}

# Application performance metrics
New-AzCustomMetric -ResourceId $apiResourceId `
    -MetricName "APIRequestLatency" `
    -Value 50 `
    -Unit "Milliseconds" `
    -Namespace "ApplicationMetrics"
```

### Advanced Alert Rules

```powershell
# Multi-condition CPU and memory alert
$criteria = @(
    @{
        MetricName = "Percentage CPU"
        TimeAggregation = "Average"
        Operator = "GreaterThan"
        Threshold = 80
    },
    @{
        MetricName = "Available Memory Bytes"
        TimeAggregation = "Average"
        Operator = "LessThan"
        Threshold = 1073741824  # 1GB
    }
)

New-AzMetricAlertRuleV2Advanced -AlertName "VM-Performance-Critical" `
    -ResourceGroupName "Production-RG" `
    -TargetResourceId $vmResourceId `
    -Criteria $criteria `
    -Severity 1 `
    -WindowSize 5 `
    -EvaluationFrequency 1 `
    -ActionGroupIds @($criticalAlertsAG.Id) `
    -AutoResolve

# Dynamic threshold alert
$dynamicCriteria = @{
    MetricName = "Transactions"
    TimeAggregation = "Total"
    DynamicThreshold = $true
    AlertSensitivity = "High"
    EvaluationPeriods = 4
    MinFailingPeriods = 3
}

New-AzMetricAlertRuleV2Advanced -AlertName "Storage-Anomaly-Detection" `
    -ResourceGroupName "Storage-RG" `
    -TargetResourceId $storageResourceId `
    -Criteria $dynamicCriteria `
    -Severity 2
```

### Log Query Alerts

```powershell
# Security event alert
$securityQuery = @"
SecurityEvent
| where EventID == 4625  // Failed login
| summarize FailedLogins = count() by Computer, Account
| where FailedLogins > 5
"@

New-AzLogQueryAlert -AlertName "Multiple-Failed-Logins" `
    -ResourceGroupName "Security-RG" `
    -WorkspaceResourceId $workspace.ResourceId `
    -Query $securityQuery `
    -Threshold 0 `
    -Operator "GreaterThan" `
    -WindowSizeInMinutes 15 `
    -FrequencyInMinutes 5 `
    -Severity 2 `
    -ActionGroupIds @($securityAlertsAG.Id)

# Performance degradation alert
$perfQuery = @"
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize AvgCPU = avg(CounterValue) by Computer, bin(TimeGenerated, 5m)
| where AvgCPU > 90
"@

New-AzLogQueryAlert -AlertName "Sustained-High-CPU" `
    -ResourceGroupName "Monitoring-RG" `
    -WorkspaceResourceId $workspace.ResourceId `
    -Query $perfQuery `
    -QueryType "ResultCount" `
    -Threshold 3 `
    -WindowSizeInMinutes 30
```

### Deploy Dashboards

```powershell
# Deploy from template file
Deploy-AzMonitorDashboard -DashboardName "Executive-Overview" `
    -ResourceGroupName "Dashboards-RG" `
    -TemplateFile ".\templates\executive-dashboard.json" `
    -Tags @{Department="IT"; Purpose="Monitoring"}

# Deploy with custom definition
$dashboardDef = @{
    lenses = @{
        "0" = @{
            order = 0
            parts = @{
                "0" = @{
                    position = @{x=0; y=0; colSpan=12; rowSpan=6}
                    metadata = @{
                        type = "Extension/Microsoft_Azure_Monitoring/PartType/MetricsChartPart"
                        settings = @{
                            title = "Resource Health Overview"
                        }
                    }
                }
            }
        }
    }
}

Deploy-AzMonitorDashboard -DashboardName "Custom-Metrics" `
    -ResourceGroupName "Monitoring-RG" `
    -DashboardDefinition $dashboardDef
```

### Deploy Workbooks

```powershell
# Deploy performance analysis workbook
Deploy-AzMonitorWorkbook -WorkbookName "VM-Performance-Analysis" `
    -ResourceGroupName "Monitoring-RG" `
    -SourceId $workspace.ResourceId `
    -DisplayName "Virtual Machine Performance Analysis" `
    -Category "Virtual Machines"

# Deploy from custom template
Deploy-AzMonitorWorkbook -WorkbookName "Cost-Analysis" `
    -ResourceGroupName "FinOps-RG" `
    -SourceId $workspace.ResourceId `
    -TemplateFile ".\workbooks\cost-analysis-template.json"
```

### Action Groups

```powershell
# Create multi-channel action group
New-AzActionGroupAdvanced -ActionGroupName "Critical-Infrastructure-AG" `
    -ResourceGroupName "Monitoring-RG" `
    -EmailReceivers @(
        @{Name="ITOps"; EmailAddress="itops@company.com"},
        @{Name="OnCall"; EmailAddress="oncall@company.com"}
    ) `
    -SmsReceivers @(
        @{Name="OnCallPhone"; CountryCode="1"; PhoneNumber="5551234567"}
    ) `
    -WebhookReceivers @(
        @{Name="Slack"; Uri="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"},
        @{Name="Teams"; Uri="https://outlook.office.com/webhook/YOUR/WEBHOOK/URL"}
    )

# Test action group
Test-AzActionGroup -ActionGroupName "Critical-Infrastructure-AG" `
    -ResourceGroupName "Monitoring-RG" `
    -AlertType "Metric"
```

### Export/Import Configuration

```powershell
# Export all monitoring configuration
Export-AzMonitoringConfiguration -ResourceGroupName "Production-RG" `
    -OutputPath ".\monitoring-config-backup.json" `
    -IncludeAll

# Selective export
Export-AzMonitoringConfiguration -ResourceGroupName "Production-RG" `
    -OutputPath ".\alerts-backup.json" `
    -IncludeAlerts `
    -IncludeActionGroups

# Import configuration to new environment
Import-AzMonitoringConfiguration -ConfigurationFile ".\monitoring-config-backup.json" `
    -ResourceGroupName "Staging-RG" `
    -Force
```

### Health Monitoring

```powershell
# Check monitoring infrastructure health
$healthReport = Get-AzMonitoringHealth -ResourceGroupName "Monitoring-RG" `
    -WorkspaceNames @("Enterprise-LAW", "Security-LAW")

# Display health summary
$healthReport | Format-List

# Check specific issues
if ($healthReport.OverallHealth -ne "Healthy") {
    Write-Warning "Monitoring issues detected:"
    $healthReport.Issues | ForEach-Object { Write-Warning " - $_" }
}
```

## Advanced Scenarios

### Multi-Region Monitoring

```powershell
# Deploy workspaces in multiple regions
$regions = @("eastus", "westeurope", "southeastasia")
$workspaces = @()

foreach ($region in $regions) {
    $ws = New-AzLogAnalyticsWorkspaceAdvanced `
        -WorkspaceName "Enterprise-LAW-$region" `
        -ResourceGroupName "Global-Monitoring-RG" `
        -Location $region `
        -RetentionInDays 90 `
        -Solutions @('Security', 'Updates')
    
    $workspaces += $ws
}

# Create global dashboard
Deploy-AzMonitorDashboard -DashboardName "Global-Operations" `
    -ResourceGroupName "Global-Monitoring-RG" `
    -TemplateFile ".\templates\multi-region-dashboard.json"
```

### Automated Remediation

```powershell
# Alert with automation runbook
$remediationWebhook = "https://webhook.azure-automation.net/webhooks/YOUR-WEBHOOK"

New-AzActionGroupAdvanced -ActionGroupName "Auto-Remediation-AG" `
    -ResourceGroupName "Automation-RG" `
    -WebhookReceivers @(
        @{
            Name = "RestartService"
            Uri = $remediationWebhook
        }
    )

# Create alert that triggers remediation
New-AzLogQueryAlert -AlertName "Service-Down-Auto-Restart" `
    -ResourceGroupName "Production-RG" `
    -WorkspaceResourceId $workspace.ResourceId `
    -Query "Heartbeat | where Computer == 'WebServer01' | summarize LastHeartbeat = max(TimeGenerated) | where LastHeartbeat < ago(5m)" `
    -Threshold 0 `
    -ActionGroupIds @($autoRemediationAG.Id)
```

## Best Practices

1. **Workspace Architecture**
   - Use centralized workspaces for cross-resource monitoring
   - Implement appropriate retention policies (30-730 days)
   - Enable capacity reservation for predictable costs

2. **Alert Strategy**
   - Start with baseline alerts, refine thresholds over time
   - Use dynamic thresholds for variable workloads
   - Implement alert suppression during maintenance

3. **Dashboard Design**
   - Create role-specific dashboards (Executive, Operations, Security)
   - Use consistent color coding and layouts
   - Include drill-down capabilities

4. **Action Groups**
   - Define escalation paths
   - Test notification channels regularly
   - Document on-call procedures

5. **Cost Optimization**
   - Review data ingestion regularly
   - Implement data sampling where appropriate
   - Archive old data to storage accounts

## Troubleshooting

### Common Issues

1. **Workspace Not Found**
   - Verify workspace exists and you have access
   - Check resource group and subscription context

2. **Alert Not Firing**
   - Verify query returns results
   - Check threshold and time window settings
   - Ensure action groups are configured

3. **Missing Metrics**
   - Confirm diagnostic settings are enabled
   - Verify agent installation on VMs
   - Check metric namespace and dimensions

4. **Dashboard Not Loading**
   - Validate JSON template syntax
   - Ensure all referenced resources exist
   - Check RBAC permissions

## Support

For issues, feature requests, or contributions:
- GitHub: [azure-enterprise-toolkit](https://github.com/wesellis/azure-enterprise-toolkit)
- Email: support@enterprise-azure.com

## License

This module is part of the Azure Enterprise Toolkit and is licensed under the MIT License.