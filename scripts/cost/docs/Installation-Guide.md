# Azure Cost Management Dashboard Installation Guide

## Prerequisites

### Azure Requirements
- Active Azure subscription with cost data
- **Cost Management Reader** role (minimum required)
- **Reader** role for resource metadata access
- Administrative access to create service principals (for automation)

### Software Requirements
- **PowerShell 7.0+** ([Download here](https://github.com/PowerShell/PowerShell/releases))
- **Azure PowerShell Module** (Az)
- **Git** for repository management
- **Modern web browser** (Chrome, Firefox, Edge, Safari)

### Optional Components
- **Power BI Desktop** (for advanced visualizations)
- **Excel 2016+** (for Excel-based reports)
- **Visual Studio Code** (for customization)

## Installation Steps

### Step 1: Download the Dashboard

#### Option A: Git Clone (Recommended)
```powershell
# Clone the repository
git clone https://github.com/wesellis/Azure-Cost-Management-Dashboard.git
cd Azure-Cost-Management-Dashboard
```

#### Option B: Direct Download
Download and extract the ZIP file from the repository to your desired location.

### Step 2: Install PowerShell Dependencies

Run the automated installer:

```powershell
# Navigate to the dashboard directory
cd Azure-Cost-Management-Dashboard

# Execute the setup script
.\Install-Prerequisites.ps1
```

If you prefer manual installation:

```powershell
# Install Azure PowerShell module
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Repository PSGallery -Force -AllowClobber -Scope CurrentUser
}

# Install Excel module for report generation
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Repository PSGallery -Force -Scope CurrentUser
}

# Verify installations
Get-Module -Name Az, ImportExcel -ListAvailable
```

### Step 3: Azure Authentication

#### Quick Start (Interactive Login)
```powershell
# Connect to Azure
Connect-AzAccount

# Select your subscription (if you have multiple)
Set-AzContext -SubscriptionId "your-subscription-id"

# Verify connection
Get-AzContext
```

#### Production Setup (Service Principal)
For automated scenarios, create a service principal:

```powershell
# Run the authentication setup wizard
.\Setup-Authentication.ps1

# Or create manually:
$servicePrincipal = New-AzADServicePrincipal -DisplayName "CostDashboard-SP"

# Assign minimum required permissions
$subscriptionScope = "/subscriptions/$(Get-AzContext | Select-Object -ExpandProperty Subscription | Select-Object -ExpandProperty Id)"
New-AzRoleAssignment -ObjectId $servicePrincipal.Id -RoleDefinitionName "Cost Management Reader" -Scope $subscriptionScope
New-AzRoleAssignment -ObjectId $servicePrincipal.Id -RoleDefinitionName "Reader" -Scope $subscriptionScope

Write-Host "Service Principal Created:" -ForegroundColor Green
Write-Host "Application ID: $($servicePrincipal.ApplicationId)" -ForegroundColor Yellow
Write-Host "Store the secret securely!" -ForegroundColor Red
```

### Step 4: Configuration

Create your configuration file:

```powershell
# Copy the template configuration
Copy-Item "config\template.json" "config\settings.json"

# Edit the configuration
notepad config\settings.json
```

Minimal configuration example:

```json
{
  "azure": {
    "subscriptionId": "your-subscription-id",
    "scope": "subscription"
  },
  "reporting": {
    "defaultCurrency": "USD",
    "defaultDateRange": 30,
    "outputDirectory": "reports"
  },
  "performance": {
    "maxRecordsPerQuery": 50000,
    "enableCaching": true
  }
}
```

### Step 5: Validation

Test your installation:

```powershell
# Run the validation script
.\Test-Installation.ps1
```

The validation script checks:
- PowerShell version compatibility
- Required modules installation
- Azure authentication status
- Cost Management API access
- Configuration file validity

Expected output:
```
✓ PowerShell 7.3.4 - Compatible
✓ Az module 10.4.1 - Installed
✓ ImportExcel module 7.8.4 - Installed
✓ Azure authentication - Active
✓ Subscription access - Verified
✓ Cost Management API - Accessible
✓ Configuration file - Valid
Installation validation completed successfully!
```

### Step 6: Generate Your First Report

Test the dashboard with a simple cost report:

```powershell
# Generate a 7-day cost summary
.\Get-CostReport.ps1 -Days 7 -Format Console

# Generate an Excel report
.\Get-CostReport.ps1 -Days 30 -Format Excel -OutputPath "reports\first-report.xlsx"
```

## Dashboard Components

### PowerShell Reports
The core reporting engine with multiple output formats:

```powershell
# Daily cost summary
.\Get-DailyCosts.ps1

# Resource group breakdown
.\Get-ResourceGroupCosts.ps1

# Service-wise analysis
.\Get-ServiceCosts.ps1

# Budget tracking
.\Get-BudgetStatus.ps1
```

### Power BI Dashboard (Optional)
If you have Power BI Desktop installed:

1. Open `dashboards\PowerBI\AzureCostDashboard.pbix`
2. Update data source parameters with your subscription details
3. Refresh the data to populate with your cost information
4. Publish to Power BI Service if needed

### Excel Templates (Optional)
Pre-built Excel templates with charts and pivot tables:

1. Open `dashboards\Excel\CostAnalysisTemplate.xlsx`
2. Enable content and macros if prompted
3. Use the "Refresh Data" button to load your cost information

## Automation Setup (Optional)

### Schedule Regular Reports

Create a scheduled task for daily cost reports:

```powershell
# Create daily report task
.\Setup-Automation.ps1 -Schedule Daily -Recipients "finance@company.com"
```

Manual task creation:

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$(Get-Location)\Get-DailyCosts.ps1`""
$trigger = New-ScheduledTaskTrigger -Daily -At "8:00 AM"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries

Register-ScheduledTask -TaskName "Azure Cost Daily Report" -Action $action -Trigger $trigger -Settings $settings
```

### Budget Alerts

Set up automated budget monitoring:

```powershell
# Configure budget alerts
.\Setup-BudgetAlerts.ps1 -BudgetAmount 5000 -AlertThresholds @(80, 90, 95)
```

## Security Configuration

### Credential Storage

Store service principal credentials securely:

```powershell
# Option 1: Environment variables
$env:AZURE_CLIENT_ID = "your-client-id"
$env:AZURE_CLIENT_SECRET = "your-client-secret"
$env:AZURE_TENANT_ID = "your-tenant-id"

# Option 2: Windows Credential Manager
cmdkey /add:AzureCostDashboard /user:your-client-id /pass:your-client-secret

# Option 3: Azure Key Vault (recommended for production)
Set-AzKeyVaultSecret -VaultName "your-keyvault" -Name "cost-dashboard-secret" -SecretValue (ConvertTo-SecureString "your-client-secret" -AsPlainText -Force)
```

### Access Control

Implement role-based access for teams:

```json
{
  "security": {
    "allowedUsers": [
      "finance@company.com",
      "manager@company.com"
    ],
    "auditLogging": true,
    "encryptExports": false
  }
}
```

## Troubleshooting

### Common Installation Issues

#### PowerShell Module Conflicts
```powershell
# Remove old AzureRM modules
Uninstall-Module AzureRM -AllVersions -Force

# Clean module cache
Remove-Module Az* -Force
Import-Module Az -Force
```

#### Authentication Problems
```powershell
# Clear cached credentials
Clear-AzContext -Force
Disconnect-AzAccount

# Reconnect
Connect-AzAccount
```

#### Permission Errors
```powershell
# Check current role assignments
Get-AzRoleAssignment -SignInName (Get-AzContext).Account.Id

# Verify Cost Management access
try {
    Get-AzConsumptionUsageDetail -Top 1
    Write-Host "Cost Management access: OK" -ForegroundColor Green
}
catch {
    Write-Host "Cost Management access: Failed - $($_.Exception.Message)" -ForegroundColor Red
}
```

### Performance Issues

For large subscriptions, optimize queries:

```json
{
  "performance": {
    "maxRecordsPerQuery": 10000,
    "enableCaching": true,
    "cacheExpirationHours": 4,
    "excludedResourceGroups": ["logs-rg", "monitoring-rg"]
  }
}
```

### Data Availability

Cost data characteristics:
- **Current day**: Usually not available until next day
- **Previous day**: Available by 8-24 hours
- **Historical data**: Typically available up to 13 months
- **New subscriptions**: May have 24-48 hour delay for first data

## Advanced Configuration

### Multi-Subscription Setup

For organizations with multiple subscriptions:

```json
{
  "azure": {
    "subscriptions": [
      {
        "id": "prod-subscription-id",
        "name": "Production",
        "scope": "subscription"
      },
      {
        "id": "dev-subscription-id", 
        "name": "Development",
        "scope": "resourceGroup",
        "resourceGroups": ["dev-rg", "test-rg"]
      }
    ]
  }
}
```

### Custom Cost Allocation

Implement department-based cost allocation:

```json
{
  "costAllocation": {
    "enabled": true,
    "rules": [
      {
        "name": "Department Allocation",
        "tagKey": "Department",
        "method": "tagBased",
        "fallback": "resourceGroup"
      }
    ]
  }
}
```

### Integration with External Systems

Export data to external systems:

```powershell
# Export to CSV for external analysis
.\Export-CostData.ps1 -Format CSV -OutputPath "exports\cost-data.csv"

# Push to database
.\Export-CostData.ps1 -Format Database -ConnectionString "your-connection-string"

# Send to REST API
.\Export-CostData.ps1 -Format API -Endpoint "https://your-api.com/costs"
```

## Maintenance

### Regular Updates

Keep the dashboard updated:

```powershell
# Update PowerShell modules
Update-Module Az, ImportExcel

# Update dashboard code (if using Git)
git pull origin main

# Verify after updates
.\Test-Installation.ps1
```

### Monitoring

Monitor dashboard health:

```powershell
# Check dashboard status
.\Get-DashboardStatus.ps1

# Review logs
Get-Content "logs\dashboard.log" -Tail 50

# Test API connectivity
.\Test-AzureConnectivity.ps1
```

## Support and Documentation

### Additional Resources
- **Configuration Guide**: Detailed configuration options
- **User Guide**: How to use dashboards and reports
- **API Reference**: PowerShell cmdlet documentation
- **FAQ**: Common questions and solutions

### Getting Help
1. Check the troubleshooting section above
2. Review logs in the `logs\` directory
3. Run diagnostic script: `.\Diagnose-Installation.ps1`
4. Check GitHub Issues for known problems
5. Contact support: wes@wesellis.com

---

**Installation Complete!** Your Azure Cost Management Dashboard is ready. Start by generating your first report and exploring the available dashboards. Consider setting up automation for regular cost monitoring and alerts.
