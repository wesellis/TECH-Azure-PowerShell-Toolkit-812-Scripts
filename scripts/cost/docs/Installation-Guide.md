# Installation Guide

This guide will walk you through setting up the Azure Cost Management Dashboard from scratch.

## Prerequisites

### Azure Requirements

- **Azure Subscription** with active resources
- **Cost Management Reader** role or higher
- **Resource Reader** role for resource analysis
- **Service Principal** for automated data collection (optional but recommended)

### Software Requirements

- **PowerShell 5.1+** (PowerShell 7+ recommended)
- **Azure PowerShell Module** (Az module)
- **Power BI Desktop** (for dashboard customization)
- **Excel 2016+** or **Excel Online** (for Excel templates)
- **Web Browser** (Chrome, Firefox, Edge, Safari)

### Development Requirements (Optional)

- **Visual Studio Code** with PowerShell extension
- **Git** for version control
- **Node.js** (if extending web dashboard)

## Step 1: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/wesellis/Azure-Cost-Management-Dashboard.git

# Navigate to the project directory
cd Azure-Cost-Management-Dashboard
```

## Step 2: Install PowerShell Dependencies

### Automatic Installation

```powershell
# Run the automated prerequisite installer
.\scripts\setup\Install-Prerequisites.ps1
```

### Manual Installation

```powershell
# Install Azure PowerShell module
Install-Module -Name Az -Repository PSGallery -Force -AllowClobber

# Install Excel module for report generation
Install-Module -Name ImportExcel -Repository PSGallery -Force

# Install HTML report module
Install-Module -Name PSWriteHTML -Repository PSGallery -Force

# Verify installations
Get-Module -Name Az -ListAvailable
Get-Module -Name ImportExcel -ListAvailable
```

## Step 3: Azure Authentication Setup

### Option A: Interactive Authentication (Quick Start)

```powershell
# Connect to Azure interactively
Connect-AzAccount

# Select subscription if you have multiple
Set-AzContext -SubscriptionId "your-subscription-id"

# Verify connection
Get-AzContext
```

### Option B: Service Principal Authentication (Recommended for Automation)

```powershell
# Run the authentication setup script
.\scripts\setup\Setup-Authentication.ps1

# Or create manually:
# 1. Create service principal
$sp = New-AzADServicePrincipal -DisplayName "Azure-Cost-Dashboard"

# 2. Assign required roles
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Cost Management Reader" -Scope "/subscriptions/your-subscription-id"
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Reader" -Scope "/subscriptions/your-subscription-id"

# 3. Create configuration file
@{
    TenantId = "your-tenant-id"
    ClientId = $sp.ApplicationId
    ClientSecret = "your-client-secret"
    SubscriptionId = "your-subscription-id"
} | ConvertTo-Json | Out-File -FilePath "config\auth.json"
```

## Step 4: Configuration

### Create Configuration File

```powershell
# Copy sample configuration
Copy-Item "config\sample-config.json" "config\config.json"

# Edit configuration with your details
notepad config\config.json
```

### Sample Configuration

```json
{
    "azure": {
        "subscriptionId": "your-subscription-id",
        "tenantId": "your-tenant-id",
        "resourceGroups": ["Production-RG", "Development-RG"],
        "excludedServices": ["Microsoft.Insights"]
    },
    "dashboard": {
        "refreshSchedule": "Daily",
        "dataRetentionDays": 90,
        "currencyCode": "USD"
    },
    "notifications": {
        "enabled": true,
        "emailRecipients": ["finance@company.com"],
        "budgetThresholds": [50, 80, 95]
    },
    "exports": {
        "autoExport": true,
        "formats": ["Excel", "CSV"],
        "exportPath": "data\\exports"
    }
}
```

## Step 5: Test Installation

### Run Basic Cost Data Test

```powershell
# Test cost data retrieval
.\scripts\data-collection\Get-AzureCostData.ps1 -Days 7 -OutputFormat "Console"
```

### Verify Module Installation

```powershell
# Run system check
.\scripts\setup\Test-Prerequisites.ps1
```

Expected output:

```
✓ PowerShell version: 7.3.4
✓ Az module installed: 10.0.0
✓ ImportExcel module installed: 7.8.4
✓ Azure connection: Connected
✓ Subscription access: Verified
✓ Cost Management permissions: Verified
```

## Step 6: Deploy Dashboards

### Power BI Dashboard

1. **Open Power BI Desktop**
2. **Open** `dashboards\PowerBI\Azure-Cost-Dashboard.pbix`
3. **Update data source** with your Azure credentials
4. **Refresh data** to populate with your cost information
5. **Publish** to Power BI Service (optional)

### Excel Dashboard

1. **Open** `dashboards\Excel\Cost-Analysis-Template.xlsx`
2. **Enable macros** if prompted
3. **Update data connections** in Data tab
4. **Refresh all** to load your cost data

### Web Dashboard

1. **Open** `dashboards\Web\index.html` in a web browser
2. **Configure API endpoints** (if using real-time data)
3. **Host on web server** (optional)

## Step 7: Setup Automation (Optional)

### Schedule Automated Reports

```powershell
# Setup daily cost reports
.\scripts\automation\Schedule-CostReports.ps1 -Type "Daily" -Recipients "finance@company.com"

# Setup budget alerts
.\scripts\automation\Setup-BudgetAlerts.ps1 -BudgetAmount 10000 -AlertThreshold @(80, 95)
```

### Windows Task Scheduler

```powershell
# Create scheduled task for daily reports
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"C:\Azure-Cost-Dashboard\scripts\automation\Daily-Report.ps1`""
$trigger = New-ScheduledTaskTrigger -Daily -At "08:00AM"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName "Azure Cost Daily Report" -Action $action -Trigger $trigger -Settings $settings
```

## Step 8: Verification

### Verify Installation

```powershell
# Run comprehensive test
.\scripts\setup\Verify-Installation.ps1
```

### Generate Test Report

```powershell
# Generate sample report to verify everything works
.\scripts\utilities\Export-CostReports.ps1 -Type "Weekly" -Format "Excel" -OutputPath "test-report.xlsx"
```

## Troubleshooting

### Common Issues

#### Authentication Errors

```powershell
# Clear cached credentials
Disconnect-AzAccount
Clear-AzContext -Force

# Reconnect
Connect-AzAccount
```

#### Permission Issues

- Verify you have **Cost Management Reader** role
- Check subscription access with `Get-AzSubscription`
- Ensure service principal has correct permissions

#### Module Installation Issues

```powershell
# Update PowerShellGet
Install-Module PowerShellGet -Force -AllowClobber

# Install modules with admin privileges
Install-Module Az -Force -AllowClobber -Scope AllUsers
```

#### Data Collection Issues

- Verify subscription has cost data (some new subscriptions may have delays)
- Check date ranges (cost data may not be available for current day)
- Ensure resources exist in the subscription

### Getting Help

1. **Check logs** in `logs\` directory
2. **Run diagnostics** with `.\scripts\setup\Diagnose-Issues.ps1`
3. **Review documentation** in `docs\` folder
4. **Check GitHub Issues** for known problems
5. **Contact support** at wes@wesellis.com

## Next Steps

1. **Customize dashboards** to match your organization's needs
2. **Setup automated reporting** for stakeholders
3. **Configure budget alerts** for proactive monitoring
4. **Explore optimization recommendations** to reduce costs
5. **Setup role-based access** for different user groups

## Security Considerations

- **Store credentials securely** using Azure Key Vault or Windows Credential Manager
- **Use managed identities** when running on Azure VMs
- **Limit service principal permissions** to minimum required
- **Regularly rotate secrets** and access keys
- **Enable audit logging** for compliance

## Performance Optimization

- **Use specific date ranges** to reduce data volume
- **Filter by resource groups** when possible
- **Cache frequently accessed data** to reduce API calls
- **Schedule reports during off-peak hours** - **Use incremental data refresh** for large datasets

---

**Installation Complete!** Your Azure Cost Management Dashboard is now ready to use. Start by generating your first cost report and exploring the interactive dashboards.

For additional configuration options, see the [Configuration Guide](Configuration-Guide.md).