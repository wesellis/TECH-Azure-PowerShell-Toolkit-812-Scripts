# Azure Cost Management Dashboard 💰

<div align="center">

![Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=power-bi&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)

**Comprehensive Azure cost monitoring and management solution with interactive dashboards, automated reporting, and cost optimization recommendations.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/wesellis/Azure-Cost-Management-Dashboard.svg)](https://github.com/wesellis/Azure-Cost-Management-Dashboard/releases/)
[![GitHub issues](https://img.shields.io/github/issues/wesellis/Azure-Cost-Management-Dashboard.svg)](https://github.com/wesellis/Azure-Cost-Management-Dashboard/issues)

</div>

---

## 🎯 **Overview**

The **Azure Cost Management Dashboard** is a comprehensive solution for monitoring, analyzing, and optimizing Azure cloud spending. This toolkit provides interactive dashboards, automated cost reporting, and actionable insights to help organizations control their cloud expenditure.

### **Key Features**
- 📊 **Interactive Power BI Dashboards** - Real-time cost visualization
- 🤖 **Automated Cost Reports** - Scheduled email reports and alerts
- 💡 **Cost Optimization Recommendations** - AI-powered suggestions
- 🎯 **Budget Monitoring** - Proactive budget tracking and alerting
- 📈 **Trend Analysis** - Historical cost patterns and forecasting
- 🏷️ **Tag-based Cost Allocation** - Departmental and project cost tracking
- ⚡ **Resource Right-sizing** - Automated recommendations for optimal sizing
- 🔒 **Security & Compliance** - Role-based access to cost data

---

## 🚀 **Quick Start**

### **Prerequisites**
- Azure subscription with Cost Management API access
- Power BI Pro license (for dashboard sharing)
- PowerShell 5.1+ with Azure PowerShell modules
- Azure service principal with Cost Management Reader role

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/wesellis/Azure-Cost-Management-Dashboard.git
   cd Azure-Cost-Management-Dashboard
   ```

2. **Install dependencies**
   ```powershell
   # Install required PowerShell modules
   .\scripts\Install-Prerequisites.ps1
   
   # Or manually install
   Install-Module Az -Force
   Install-Module ImportExcel -Force
   ```

3. **Configure authentication**
   ```powershell
   # Setup service principal authentication
   .\scripts\Setup-Authentication.ps1
   ```

4. **Deploy the dashboard**
   ```powershell
   # Deploy Power BI dashboard and configure data refresh
   .\scripts\Deploy-Dashboard.ps1
   ```

---

## 📁 **Repository Structure**

```
Azure-Cost-Management-Dashboard/
├── 📊 dashboards/
│   ├── PowerBI/
│   │   ├── Azure-Cost-Dashboard.pbix          # Main Power BI dashboard
│   │   ├── Executive-Summary.pbix             # Executive-level overview
│   │   └── Department-Breakdown.pbix          # Departmental cost analysis
│   ├── Excel/
│   │   ├── Cost-Analysis-Template.xlsx        # Excel analysis template
│   │   └── Budget-Tracking-Template.xlsx      # Budget monitoring template
│   └── Web/
│       ├── index.html                         # Web-based dashboard
│       ├── css/                               # Stylesheets
│       └── js/                                # JavaScript components
├── 🤖 scripts/
│   ├── data-collection/
│   │   ├── Get-AzureCostData.ps1             # Cost data extraction
│   │   ├── Get-ResourceUsage.ps1             # Resource utilization data
│   │   └── Export-CostAnalysis.ps1           # Cost analysis export
│   ├── automation/
│   │   ├── Schedule-CostReports.ps1          # Automated reporting
│   │   ├── Setup-BudgetAlerts.ps1            # Budget alert configuration
│   │   └── Optimize-Resources.ps1            # Resource optimization
│   ├── setup/
│   │   ├── Install-Prerequisites.ps1         # Dependency installation
│   │   ├── Setup-Authentication.ps1          # Authentication setup
│   │   └── Deploy-Dashboard.ps1              # Dashboard deployment
│   └── utilities/
│       ├── Export-CostReports.ps1            # Report generation
│       ├── Calculate-Savings.ps1             # Savings calculation
│       └── Update-Tags.ps1                   # Tag management
├── 📁 data/
│   ├── templates/                            # Data templates
│   ├── samples/                              # Sample datasets
│   └── exports/                              # Generated reports
├── 📚 docs/
│   ├── Installation-Guide.md                 # Detailed setup instructions
│   ├── Configuration-Guide.md               # Configuration documentation
│   ├── User-Guide.md                        # End-user documentation
│   ├── API-Reference.md                     # API documentation
│   └── Troubleshooting.md                   # Common issues and solutions
├── 🧪 tests/
│   ├── unit/                                # Unit tests
│   ├── integration/                         # Integration tests
│   └── TestData/                            # Test datasets
├── 📄 .gitignore                            # Git ignore rules
├── 📄 CHANGELOG.md                          # Version history
├── 📄 CONTRIBUTING.md                       # Contribution guidelines
├── 📄 LICENSE                               # MIT License
└── 📄 README.md                             # This file
```

---

## 📊 **Dashboard Features**

### **Power BI Dashboards**

#### **📈 Main Cost Dashboard**
- Real-time cost overview across all subscriptions
- Service-level cost breakdown
- Monthly spending trends and forecasts
- Top spending resources and resource groups
- Geographic cost distribution

#### **👥 Executive Summary**
- High-level KPIs and cost metrics
- Budget vs. actual spending comparison
- Cost optimization opportunities
- Month-over-month variance analysis
- ROI and cost efficiency metrics

#### **🏢 Departmental Breakdown**
- Cost allocation by department/project
- Tag-based cost categorization
- Chargeback and showback reporting
- Budget utilization by business unit
- Cost center performance analysis

### **Web Dashboard**
- Browser-based cost monitoring
- Mobile-responsive design
- Real-time cost alerts
- Interactive charts and graphs
- Export capabilities

---

## 🤖 **Automation Features**

### **Scheduled Reports**
```powershell
# Daily cost summary email
.\scripts\automation\Schedule-CostReports.ps1 -Type "Daily" -Recipients "finance@company.com"

# Weekly department breakdown
.\scripts\automation\Schedule-CostReports.ps1 -Type "Weekly" -Recipients "managers@company.com" -Department "All"

# Monthly executive summary
.\scripts\automation\Schedule-CostReports.ps1 -Type "Monthly" -Recipients "executives@company.com" -Format "Executive"
```

### **Budget Alerts**
```powershell
# Setup budget alerts for all subscriptions
.\scripts\automation\Setup-BudgetAlerts.ps1 -BudgetAmount 10000 -AlertThreshold @(50, 80, 95)

# Department-specific budget monitoring
.\scripts\automation\Setup-BudgetAlerts.ps1 -Department "IT" -BudgetAmount 5000 -Recipients "it-managers@company.com"
```

### **Cost Optimization**
```powershell
# Automated resource right-sizing recommendations
.\scripts\automation\Optimize-Resources.ps1 -SubscriptionId "your-subscription-id" -RecommendationLevel "Conservative"

# Identify unused resources
.\scripts\automation\Optimize-Resources.ps1 -Action "FindUnused" -Age 30 -ExportPath "unused-resources.csv"
```

---

## 📈 **Sample Reports**

### **Monthly Cost Summary**
| Metric | Current Month | Previous Month | Variance |
|--------|---------------|----------------|----------|
| Total Spend | $12,450 | $11,200 | +11.2% |
| Compute | $6,800 | $6,200 | +9.7% |
| Storage | $2,100 | $2,000 | +5.0% |
| Networking | $1,550 | $1,500 | +3.3% |
| Other | $2,000 | $1,500 | +33.3% |

### **Top 10 Spending Resources**
1. Production SQL Database - $1,200/month
2. Web App Service Plan - $890/month
3. Virtual Machine (D4s_v3) - $650/month
4. Storage Account (Premium) - $420/month
5. Load Balancer - $380/month

---

## 🛠️ **Configuration**

### **Authentication Setup**
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

### **Dashboard Configuration**
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

---

## 🎯 **Use Cases**

### **💼 Enterprise Cost Management**
- Multi-subscription cost monitoring
- Departmental chargeback and showback
- Budget planning and forecasting
- Cost optimization initiatives

### **💻 DevOps Cost Optimization**
- Development vs. production cost comparison
- CI/CD pipeline cost tracking
- Environment-specific cost analysis
- Resource lifecycle cost management

### **📊 Financial Reporting**
- Monthly financial close processes
- Executive dashboard reporting
- Variance analysis and explanations
- ROI and cost efficiency metrics

### **🔧 IT Operations**
- Resource utilization monitoring
- Right-sizing recommendations
- Unused resource identification
- Cost anomaly detection

---

## 🎓 **Getting Started Examples**

### **Basic Cost Data Extraction**
```powershell
# Get last 30 days of cost data
.\scripts\data-collection\Get-AzureCostData.ps1 -Days 30 -ExportPath "monthly-costs.csv"

# Get cost data by resource group
.\scripts\data-collection\Get-AzureCostData.ps1 -ResourceGroup "Production-RG" -Days 7
```

### **Generate Weekly Report**
```powershell
# Create comprehensive weekly cost report
.\scripts\utilities\Export-CostReports.ps1 -Type "Weekly" -Format "Excel" -OutputPath "reports\"
```

### **Setup Budget Monitoring**
```powershell
# Monitor $10k monthly budget with 80% alert threshold
.\scripts\automation\Setup-BudgetAlerts.ps1 -BudgetName "Monthly-Budget" -Amount 10000 -Threshold 80
```

---

## 🤝 **Contributing**

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### **Development Setup**
1. Fork the repository
2. Create a feature branch
3. Install development dependencies
4. Make your changes
5. Run tests
6. Submit a pull request

---

## 📞 **Support & Contact**

**Wesley Ellis**  
📧 Email: wes@wesellis.com  
🌐 Website: wesellis.com

### **Getting Help**
- 📚 Check the [Documentation](docs/)
- 🐛 Report issues on [GitHub Issues](https://github.com/wesellis/Azure-Cost-Management-Dashboard/issues)
- 💬 Join our [Discussions](https://github.com/wesellis/Azure-Cost-Management-Dashboard/discussions)

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 **Acknowledgments**

- Microsoft Azure Cost Management APIs
- Power BI community templates
- Azure PowerShell module contributors
- Open source cost management tools

---

<div align="center">

### 💡 *"Turning cloud costs from chaos to clarity"*

![GitHub stars](https://img.shields.io/github/stars/wesellis/Azure-Cost-Management-Dashboard?style=social)
![GitHub forks](https://img.shields.io/github/forks/wesellis/Azure-Cost-Management-Dashboard?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/wesellis/Azure-Cost-Management-Dashboard?style=social)

</div>
