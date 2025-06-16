# Azure Enterprise Monitoring & Observability Assets

This folder contains comprehensive monitoring and observability assets for enterprise Azure environments, providing deep insights into infrastructure, security, cost optimization, and application performance.

## 📁 Folder Structure

```
monitoring/
├── azure-monitor-workbooks/     # Azure Monitor workbook templates
├── grafana-dashboards/          # Grafana dashboard configurations
├── power-bi-templates/          # Power BI dashboard templates
├── kql-queries/                 # KQL query libraries
├── alert-templates/             # ARM templates for alerting
├── custom-metrics/              # Custom telemetry definitions
└── README.md                    # This documentation
```

## 🎯 Overview

The monitoring assets are designed to provide enterprise-grade observability across multiple dimensions:

- **Infrastructure Monitoring**: VM performance, storage health, network metrics
- **Security Posture**: Threat detection, compliance tracking, incident investigation
- **Cost Optimization**: Spending analysis, resource utilization, budget tracking
- **Application Health**: Performance metrics, error tracking, user experience

## 📊 Azure Monitor Workbooks

### Azure Infrastructure Overview
**File**: `azure-monitor-workbooks/azure-infrastructure-overview.json`

Comprehensive dashboard showing:
- Resource distribution by type and location
- Virtual machine status and performance
- Storage account details and health
- Network infrastructure overview
- Resource creation trends

**Import Instructions**:
1. Open Azure Monitor in the Azure portal
2. Navigate to Workbooks
3. Click "New" → "Advanced Editor"
4. Paste the JSON content
5. Save the workbook

### Security Posture Dashboard
**File**: `azure-monitor-workbooks/security-posture-dashboard.json`

Security-focused monitoring including:
- Overall security score trends
- Security recommendations by severity
- Active security alerts
- Compliance status monitoring
- Identity and access management metrics
- Network security assessments

### Cost Optimization Workbook
**File**: `azure-monitor-workbooks/cost-optimization-workbook.json`

Cost analysis and optimization featuring:
- Resource cost analysis by type and group
- VM rightsizing opportunities
- Storage optimization recommendations
- Unattached resource identification
- Resource tagging compliance
- Cost optimization action items

## 📈 Grafana Dashboards

### Azure Performance Dashboard
**File**: `grafana-dashboards/azure-performance-dashboard.json`

Real-time performance monitoring:
- VM CPU, memory, disk, and network metrics
- Storage account availability and performance
- Configurable resource group and VM filters
- 30-second refresh intervals
- Performance thresholds and alerts

### Application Health Dashboard
**File**: `grafana-dashboards/application-health-dashboard.json`

Application-centric monitoring:
- App Service response times and request rates
- HTTP error rate tracking
- Function App execution metrics
- Application Insights integration
- User experience monitoring

**Setup Instructions**:
1. Import JSON into Grafana
2. Configure Azure Monitor data source
3. Set up authentication to Azure
4. Customize variables for your environment

## 💼 Power BI Templates

### Executive Azure Dashboard
**File**: `power-bi-templates/executive-azure-dashboard.pbit`

Executive-level reporting featuring:
- Total Azure spend trends
- Budget vs. actual analysis
- Resource distribution insights
- Cost forecasting
- ROI and savings opportunities

### Azure Security Scorecard
**File**: `power-bi-templates/azure-security-scorecard.pbit`

Security metrics for leadership:
- Security score tracking
- Compliance framework status
- Risk assessment summaries
- Remediation progress
- Security investment ROI

**Setup Requirements**:
- Power BI Pro or Premium license
- Azure Security Reader permissions
- Log Analytics workspace access
- Cost Management API permissions

## 🔍 KQL Query Libraries

### Performance Troubleshooting
**File**: `kql-queries/performance-troubleshooting.kql`

Comprehensive query collection for:
- High CPU and memory utilization detection
- Disk I/O performance analysis
- Network latency troubleshooting
- Application performance correlation
- Database performance monitoring

### Security Incident Investigation
**File**: `kql-queries/security-incident-investigation.kql`

Security-focused queries including:
- Brute force attack detection
- Impossible travel analysis
- Lateral movement tracking
- Data exfiltration indicators
- Privilege escalation monitoring

### Cost Optimization Queries
**File**: `kql-queries/cost-optimization-queries.kql`

Cost analysis and optimization:
- Underutilized resource identification
- Cost anomaly detection
- Rightsizing recommendations
- Reserved instance opportunities
- Budget variance analysis

**Usage Instructions**:
1. Copy queries to Azure Monitor Log Analytics
2. Adjust time ranges using `ago()` functions
3. Modify thresholds for your environment
4. Save frequently used queries as functions
5. Create alerts based on query results

## 🚨 Alert Templates

### Critical Infrastructure Alerts
**File**: `alert-templates/critical-infrastructure-alerts.json`

ARM template deploying essential alerts:
- High CPU utilization (>90%)
- Low memory availability (<1GB)
- Disk space warnings (>85% used)
- VM heartbeat failures
- Application error rate spikes
- Database connection failures
- Storage availability issues
- Backup failure notifications

### Security Incident Alerts
**File**: `alert-templates/security-incident-alerts.json`

Security-focused alerting system:
- Brute force attack detection
- Impossible travel patterns
- Privileged role changes
- Malicious IP communications
- Suspicious process execution
- Unauthorized Key Vault access
- Potential data exfiltration
- Lateral movement detection

**Deployment Instructions**:
```powershell
# Deploy infrastructure alerts
New-AzResourceGroupDeployment `
  -ResourceGroupName "monitoring-rg" `
  -TemplateFile "critical-infrastructure-alerts.json" `
  -emailAddress "admin@company.com" `
  -logAnalyticsWorkspaceId "/subscriptions/.../workspaces/..."

# Deploy security alerts
New-AzResourceGroupDeployment `
  -ResourceGroupName "security-rg" `
  -TemplateFile "security-incident-alerts.json" `
  -securityEmailAddress "security@company.com" `
  -logAnalyticsWorkspaceId "/subscriptions/.../workspaces/..."
```

## 📋 Custom Metrics

### Application Insights Definitions
**File**: `custom-metrics/application-insights-definitions.json`

Comprehensive telemetry definitions:
- **Business Metrics**: Transaction counts, revenue tracking, user engagement
- **Performance Metrics**: Database queries, API response times, cache hit ratios
- **Resource Utilization**: Memory usage, connection pools
- **Security Metrics**: Authentication failures, access violations
- **Error Tracking**: Recovery times, circuit breaker states

**Implementation Examples**:

```csharp
// Business transaction tracking
telemetryClient.TrackMetric("BusinessTransaction.Count", 1, 
    new Dictionary<string, string> {
        { "TransactionType", "Purchase" },
        { "BusinessUnit", "Retail" }
    });

// Performance monitoring
telemetryClient.TrackMetric("Database.QueryPerformance", queryTimeMs, 
    new Dictionary<string, string> {
        { "QueryType", "SELECT" },
        { "DatabaseName", "ProductDB" }
    });

// Security event tracking
telemetryClient.TrackEvent("Security.PolicyViolation", 
    new Dictionary<string, string> {
        { "PolicyName", "DataAccess" },
        { "ViolationType", "UnauthorizedRead" }
    });
```

## 🚀 Quick Start Guide

### 1. Prerequisites
- Azure subscription with appropriate permissions
- Log Analytics workspace configured
- Azure Monitor enabled on resources
- Application Insights for application monitoring

### 2. Basic Setup
```powershell
# Create monitoring resource group
New-AzResourceGroup -Name "monitoring-rg" -Location "East US"

# Deploy critical infrastructure alerts
New-AzResourceGroupDeployment `
  -ResourceGroupName "monitoring-rg" `
  -TemplateFile "alert-templates/critical-infrastructure-alerts.json" `
  -emailAddress "your-email@company.com"
```

### 3. Import Workbooks
1. Navigate to Azure Monitor → Workbooks
2. Create new workbook → Advanced Editor
3. Import JSON from `azure-monitor-workbooks/`
4. Configure parameters for your environment

### 4. Setup Grafana (Optional)
1. Deploy Grafana instance or use Azure Managed Grafana
2. Configure Azure Monitor data source
3. Import dashboard JSON files
4. Customize variables and thresholds

### 5. Power BI Configuration
1. Download .pbit templates
2. Open in Power BI Desktop
3. Configure Azure authentication
4. Set up data refresh schedules
5. Publish to Power BI Service

## 📚 Best Practices

### Alert Management
- **Severity Levels**: Use consistent severity mapping across all alerts
- **Action Groups**: Configure appropriate notification channels
- **Alert Fatigue**: Tune thresholds to avoid excessive notifications
- **Escalation**: Implement escalation paths for critical alerts

### Query Optimization
- **Time Ranges**: Use appropriate time windows for queries
- **Sampling**: Implement sampling for high-volume telemetry
- **Caching**: Cache frequently used query results
- **Indexing**: Ensure proper indexing for query performance

### Security Monitoring
- **Baseline**: Establish normal behavior baselines
- **Correlation**: Correlate events across multiple data sources
- **Response**: Define clear incident response procedures
- **Compliance**: Align monitoring with compliance requirements

### Cost Management
- **Regular Reviews**: Schedule regular cost optimization reviews
- **Automation**: Implement automated cost optimization actions
- **Tagging**: Maintain comprehensive resource tagging
- **Budgets**: Set up proactive budget alerts

## 🔧 Troubleshooting

### Common Issues

**Workbooks not loading data**:
- Verify Log Analytics workspace permissions
- Check resource scope configuration
- Validate KQL queries independently

**Grafana authentication failures**:
- Confirm Azure Monitor data source configuration
- Validate service principal permissions
- Check Azure AD app registration

**Power BI refresh failures**:
- Verify gateway configuration
- Check data source credentials
- Review connection timeouts

**Alert not firing**:
- Test KQL queries in Log Analytics
- Verify alert rule configuration
- Check action group settings

### Performance Optimization

**Large dataset queries**:
- Use summarize operations early in queries
- Implement proper time filtering
- Consider data sampling for trends

**High alert volume**:
- Review and tune alert thresholds
- Implement alert suppression rules
- Use dynamic thresholds where appropriate

## 📞 Support

For technical support and questions:

1. **Internal Documentation**: Check your organization's Azure governance docs
2. **Azure Support**: Use Azure Support Portal for platform issues
3. **Community**: Azure Monitor and Grafana community forums
4. **Training**: Microsoft Learn modules for Azure Monitor

## 🔄 Maintenance

### Regular Tasks
- **Monthly**: Review alert effectiveness and tune thresholds
- **Quarterly**: Update workbooks with new requirements
- **Annually**: Review data retention policies and costs

### Updates
- Monitor for new Azure Monitor features
- Update KQL queries with new data sources
- Refresh Power BI templates with business changes
- Test alert rules after Azure service updates

---

**Last Updated**: June 16, 2025  
**Version**: 1.0.0  
**Maintained by**: Azure Enterprise Toolkit Team