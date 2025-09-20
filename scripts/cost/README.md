# Azure Cost Management Scripts

Comprehensive Azure cost monitoring and management solution with automated reporting and optimization tools.

## Overview

This collection provides scripts for monitoring, analyzing, and optimizing Azure cloud spending. The toolkit includes automated cost reporting, budget monitoring, and actionable insights to help organizations control their cloud expenditure.

## Key Features

- **Interactive Power BI Dashboards** - Real-time cost visualization
- **Automated Cost Reports** - Scheduled email reports and alerts
- **Cost Optimization Recommendations** - AI-powered suggestions
- **Budget Monitoring** - Proactive budget tracking and alerting
- **Trend Analysis** - Historical cost patterns and forecasting
- **Tag-based Cost Allocation** - Departmental and project cost tracking
- **Resource Right-sizing** - Automated recommendations for optimal sizing
- **Security & Compliance** - Role-based access to cost data

## Quick Start

### Prerequisites

- Azure subscription with Cost Management API access
- Power BI Pro license (for dashboard sharing)
- PowerShell 5.1+ with Azure PowerShell modules
- Azure service principal with Cost Management Reader role

### Installation

```powershell
# Install required PowerShell modules
Install-Module -Name Az -Force
Install-Module -Name ImportExcel -Force

# Connect to Azure
Connect-AzAccount
```

## Repository Structure

```
cost/
├── dashboards/
│   ├── PowerBI/               # Power BI dashboard files
│   ├── Excel/                 # Excel analysis templates
│   └── Web/                   # Web-based dashboard
├── scripts/
│   ├── data-collection/       # Cost data extraction scripts
│   ├── automation/            # Automated reporting and alerts
│   ├── setup/                 # Installation and configuration
│   └── utilities/             # Report generation and tools
├── data/
│   ├── templates/             # Data templates
│   ├── samples/               # Sample datasets
│   └── exports/               # Generated reports
└── docs/                      # Documentation
```

## Dashboard Features

### Power BI Dashboards

#### Main Cost Dashboard

- Real-time cost overview across all subscriptions
- Service-level cost breakdown
- Monthly spending trends and forecasts
- Top spending resources and resource groups
- Geographic cost distribution

#### Executive Summary

- High-level KPIs and cost metrics
- Budget vs. actual spending comparison
- Cost optimization opportunities
- Month-over-month variance analysis
- ROI and cost efficiency metrics

#### Departmental Breakdown

- Cost allocation by department/project
- Tag-based cost categorization
- Chargeback and showback reporting
- Budget utilization by business unit
- Cost center performance analysis

### Web Dashboard

- Browser-based cost monitoring
- Mobile-responsive design
- Real-time cost alerts
- Interactive charts and graphs
- Export capabilities

## Automation Features

### Scheduled Reports

```powershell
# Daily cost summary email
.\scripts\automation\Schedule-CostReports.ps1 -Type "Daily" -Recipients "finance@company.com"

# Weekly department breakdown
.\scripts\automation\Schedule-CostReports.ps1 -Type "Weekly" -Recipients "managers@company.com" -Department "All"

# Monthly executive summary
.\scripts\automation\Schedule-CostReports.ps1 -Type "Monthly" -Recipients "executives@company.com" -Format "Executive"
```

### Budget Alerts

```powershell
# Setup budget alerts for all subscriptions
.\scripts\automation\Setup-BudgetAlerts.ps1 -BudgetAmount 10000 -AlertThreshold @(50, 80, 95)

# Department-specific budget monitoring
.\scripts\automation\Setup-BudgetAlerts.ps1 -Department "IT" -BudgetAmount 5000 -Recipients "it-managers@company.com"
```

### Cost Optimization

```powershell
# Automated resource right-sizing recommendations
.\scripts\automation\Optimize-Resources.ps1 -SubscriptionId "your-subscription-id" -RecommendationLevel "Conservative"

# Identify unused resources
.\scripts\automation\Optimize-Resources.ps1 -Action "FindUnused" -Age 30 -ExportPath "unused-resources.csv"
```

## Sample Reports

### Monthly Cost Summary

| Metric | Current Month | Previous Month | Variance |
|--------|---------------|----------------|----------|
| Total Spend | $12,450 | $11,200 | +11.2% |
| Compute | $6,800 | $6,200 | +9.7% |
| Storage | $2,100 | $2,000 | +5.0% |
| Networking | $1,550 | $1,500 | +3.3% |
| Other | $2,000 | $1,500 | +33.3% |

### Top 10 Spending Resources

1. Production SQL Database - $1,200/month
2. Web App Service Plan - $890/month
3. Virtual Machine (D4s_v3) - $650/month
4. Storage Account (premium) - $420/month
5. Load Balancer - $380/month

## Configuration

### Authentication Setup

```powershell
# Create service principal for automated access
$sp = New-AzADServicePrincipal -DisplayName "Azure-Cost-Dashboard"

# Assign Cost Management Reader role
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Cost Management Reader" -Scope "/subscriptions/your-subscription-id"

# Configure authentication file
@{
    TenantId = "your-tenant-id"
    ClientId = $sp.ApplicationId
    ClientSecret = "your-client-secret"
    SubscriptionId = "your-subscription-id"
} | ConvertTo-Json | Out-File -FilePath "config\auth.json"
```

### Dashboard Configuration

```json
{
    "refreshSchedule": "Daily",
    "costThresholds": {
        "warning": 80,
        "critical": 95
    },
    "emailNotifications": {
        "enabled": true,
        "recipients": ["finance@company.com"],
        "schedule": "Weekly"
    },
    "dataRetention": {
        "months": 24
    }
}
```

## Use Cases

### Enterprise Cost Management

- Multi-subscription cost monitoring
- Departmental chargeback and showback
- Budget planning and forecasting
- Cost optimization initiatives

### DevOps Cost Optimization

- Development vs. production cost comparison
- CI/CD pipeline cost tracking
- Environment-specific cost analysis
- Resource lifecycle cost management

### Financial Reporting

- Monthly financial close processes
- Executive dashboard reporting
- Variance analysis and explanations
- ROI and cost efficiency metrics

### IT Operations

- Resource utilization monitoring
- Right-sizing recommendations
- Unused resource identification
- Cost anomaly detection

## Getting Started Examples

### Basic Cost Data Extraction

```powershell
# Get last 30 days of cost data
.\scripts\data-collection\Get-AzureCostData.ps1 -Days 30 -ExportPath "monthly-costs.csv"

# Get cost data by resource group
.\scripts\data-collection\Get-AzureCostData.ps1 -ResourceGroup "Production-RG" -Days 7
```

### Generate Weekly Report

```powershell
# Create comprehensive weekly cost report
.\scripts\utilities\Export-CostReports.ps1 -Type "Weekly" -Format "Excel" -OutputPath "reports\"
```

### Setup Budget Monitoring

```powershell
# Monitor $10k monthly budget with 80% alert threshold
.\scripts\automation\Setup-BudgetAlerts.ps1 -BudgetName "Monthly-Budget" -Amount 10000 -Threshold 80
```

## Documentation

- [Installation Guide](docs/Installation-Guide.md) - Detailed setup instructions
- [Configuration Guide](docs/Configuration-Guide.md) - Configuration documentation
- [User Guide](docs/User-Guide.md) - End-user documentation
- [API Reference](docs/API-Reference.md) - API documentation
- [Troubleshooting](docs/Troubleshooting.md) - Common issues and solutions

## Support

For questions or issues:

- Check the documentation in the `/docs/` directory
- Review the troubleshooting guide
- Contact: wes@wesellis.com 