# Azure Cost Management Dashboard Configuration Guide

## Prerequisites

- Azure PowerShell module (Az.Accounts, Az.CostManagement, Az.Resources)
- PowerShell 7.0 or later
- Azure subscription with appropriate permissions
- Cost Management Reader role minimum

## Quick Start

1. Clone or download the dashboard files
2. Run the initial setup script: `.\Setup-CostDashboard.ps1`
3. Configure authentication using one of the methods below
4. Test the configuration: `.\Test-Configuration.ps1`
5. Generate your first report: `.\Get-CostReport.ps1`

## Authentication Configuration

### Method 1: Azure CLI (Recommended for Development)

```powershell
# Login with your Azure account
Connect-AzAccount

# Set default subscription
Set-AzContext -SubscriptionId "your-subscription-id"
```

### Method 2: Service Principal (Recommended for Production)

Create a service principal with minimal required permissions:

```powershell
# Create service principal
$sp = New-AzADServicePrincipal -DisplayName "CostDashboard-ServicePrincipal"

# Assign Cost Management Reader role
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName "Cost Management Reader" -Scope "/subscriptions/your-subscription-id"

# Store credentials in secure configuration
$authConfig = @{
    TenantId = "your-tenant-id"
    ClientId = $sp.ApplicationId
    SubscriptionId = "your-subscription-id"
}

# Save to secure configuration file
$authConfig | ConvertTo-Json | Set-Content "config\authentication.json"
```

Store the client secret separately using Azure Key Vault or environment variables:

```powershell
# Using environment variable (recommended)
$env:AZURE_CLIENT_SECRET = "your-client-secret"

# Or using Azure Key Vault
Set-AzKeyVaultSecret -VaultName "your-keyvault" -Name "cost-dashboard-secret" -SecretValue (ConvertTo-SecureString "your-client-secret" -AsPlainText -Force)
```

## Primary Configuration File

Create `config\settings.json`:

```json
{
  "azure": {
    "subscriptionId": "your-subscription-id",
    "defaultScope": "subscription",
    "includedResourceGroups": [],
    "excludedResourceGroups": [],
    "excludedServices": [
      "Microsoft.Insights/components",
      "Microsoft.Advisor"
    ]
  },
  "reporting": {
    "defaultCurrency": "USD",
    "defaultDateRange": 30,
    "timeZone": "UTC",
    "dataRetentionDays": 90
  },
  "output": {
    "exportFormats": ["Excel", "CSV"],
    "outputDirectory": "reports",
    "includeCharts": true,
    "compressExports": false
  },
  "performance": {
    "maxRecordsPerQuery": 50000,
    "queryTimeoutSeconds": 300,
    "enableCaching": true,
    "cacheExpirationHours": 4
  }
}
```

## Email Notifications (Optional)

Create `config\notifications.json` for email alerts:

```json
{
  "enabled": false,
  "smtp": {
    "server": "smtp.office365.com",
    "port": 587,
    "useSSL": true,
    "fromAddress": "costmanagement@yourcompany.com"
  },
  "recipients": [
    "finance@yourcompany.com",
    "manager@yourcompany.com"
  ],
  "alerts": {
    "budgetThresholds": [80, 90, 95],
    "anomalyDetection": true,
    "weeklyReports": true,
    "monthlyReports": true
  }
}
```

Store SMTP credentials securely:

```powershell
# Store SMTP credentials as environment variables
$env:SMTP_USERNAME = "your-email@yourcompany.com"
$env:SMTP_PASSWORD = "your-app-password"
```

## Advanced Configuration Options

### Custom Cost Allocation

For organizations needing department or project-based cost allocation:

```json
{
  "costAllocation": {
    "enabled": true,
    "tagBasedAllocation": {
      "departmentTag": "Department",
      "projectTag": "Project",
      "costCenterTag": "CostCenter"
    },
    "sharedCostDistribution": {
      "method": "proportional",
      "sharedServices": ["networking", "security"]
    }
  }
}
```

### Regional Configuration

For multi-region deployments:

```json
{
  "regions": {
    "primary": "East US",
    "includedRegions": ["East US", "West US", "Central US"],
    "excludedRegions": ["West Europe", "Southeast Asia"]
  }
}
```

## Environment-Specific Configurations

### Development Environment

Create `config\development.json`:

```json
{
  "azure": {
    "subscriptionId": "dev-subscription-id",
    "defaultScope": "resourceGroup",
    "includedResourceGroups": ["dev-rg", "test-rg"]
  },
  "reporting": {
    "defaultDateRange": 7,
    "dataRetentionDays": 30
  },
  "notifications": {
    "enabled": false
  }
}
```

### Production Environment

Create `config\production.json`:

```json
{
  "azure": {
    "subscriptionId": "prod-subscription-id",
    "defaultScope": "subscription"
  },
  "reporting": {
    "defaultDateRange": 30,
    "dataRetentionDays": 365
  },
  "notifications": {
    "enabled": true
  },
  "security": {
    "auditLogging": true,
    "encryptExports": true
  }
}
```

## Configuration Management Scripts

### Setup Script (`Setup-CostDashboard.ps1`)

```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SubscriptionId,
    
    [Parameter()]
    [string]$Environment = "development",
    
    [Parameter()]
    [string]$ConfigPath = "config"
)

# Create configuration directory
if (-not (Test-Path $ConfigPath)) {
    New-Item -ItemType Directory -Path $ConfigPath -Force
}

# Generate base configuration
$baseConfig = @{
    azure = @{
        subscriptionId = $SubscriptionId
        defaultScope = "subscription"
    }
    reporting = @{
        defaultCurrency = "USD"
        defaultDateRange = 30
        timeZone = [System.TimeZoneInfo]::Local.Id
    }
}

$configFile = Join-Path $ConfigPath "settings.json"
$baseConfig | ConvertTo-Json -Depth 3 | Set-Content $configFile

Write-Host "Configuration created at: $configFile" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure authentication" -ForegroundColor White
Write-Host "2. Run Test-Configuration.ps1" -ForegroundColor White
Write-Host "3. Generate your first report" -ForegroundColor White
```

### Validation Script (`Test-Configuration.ps1`)

```powershell
[CmdletBinding()]
param(
    [Parameter()]
    [string]$ConfigPath = "config\settings.json"
)

function Test-Configuration {
    param($ConfigPath)
    
    $errors = @()
    
    # Test configuration file exists
    if (-not (Test-Path $ConfigPath)) {
        $errors += "Configuration file not found: $ConfigPath"
        return $errors
    }
    
    # Test JSON validity
    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
    }
    catch {
        $errors += "Invalid JSON in configuration file: $($_.Exception.Message)"
        return $errors
    }
    
    # Test Azure connectivity
    try {
        $context = Get-AzContext
        if (-not $context) {
            $errors += "Not authenticated to Azure. Run Connect-AzAccount."
        }
        elseif ($context.Subscription.Id -ne $config.azure.subscriptionId) {
            $errors += "Azure context subscription mismatch. Expected: $($config.azure.subscriptionId), Current: $($context.Subscription.Id)"
        }
    }
    catch {
        $errors += "Azure PowerShell module error: $($_.Exception.Message)"
    }
    
    # Test Cost Management API access
    try {
        $scope = "/subscriptions/$($config.azure.subscriptionId)"
        $costData = Get-AzCostManagementUsageByScope -Scope $scope -TimePeriod (Get-Date).AddDays(-1) -Granularity "Daily" -ErrorAction Stop
        Write-Host "Cost Management API access: OK" -ForegroundColor Green
    }
    catch {
        $errors += "Cost Management API access failed: $($_.Exception.Message)"
    }
    
    return $errors
}

$errors = Test-Configuration -ConfigPath $ConfigPath

if ($errors.Count -eq 0) {
    Write-Host "Configuration validation passed!" -ForegroundColor Green
}
else {
    Write-Host "Configuration validation failed:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
```

## Security Best Practices

### Credential Management

1. **Never store secrets in configuration files**
2. **Use environment variables for sensitive data**
3. **Implement Azure Key Vault for production**
4. **Rotate service principal secrets regularly**

### File Permissions

```powershell
# Secure configuration directory (Windows)
$configPath = "config"
$acl = Get-Acl $configPath
$acl.SetAccessRuleProtection($true, $false)
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$userRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($adminRule)
$acl.SetAccessRule($userRule)
Set-Acl -Path $configPath -AclObject $acl
```

### Audit Logging

Enable audit logging in production:

```json
{
  "security": {
    "auditLogging": true,
    "logPath": "logs\\audit.log",
    "logLevel": "Information",
    "retentionDays": 90
  }
}
```

## Troubleshooting

### Common Issues

**Authentication Failures**
- Verify service principal hasn't expired
- Check role assignments
- Confirm subscription access

**Permission Errors**
- Ensure Cost Management Reader role
- Verify subscription scope
- Check resource group permissions

**API Rate Limiting**
- Reduce query frequency
- Implement exponential backoff
- Cache results appropriately

**Performance Issues**
- Reduce date range for large subscriptions
- Exclude unnecessary resource groups
- Enable caching

### Diagnostic Commands

```powershell
# Check Azure PowerShell modules
Get-Module Az.* -ListAvailable

# Verify authentication
Get-AzContext

# Test Cost Management API
Get-AzCostManagementUsageByScope -Scope "/subscriptions/your-sub-id" -TimePeriod (Get-Date).AddDays(-1)

# Check permissions
Get-AzRoleAssignment -Scope "/subscriptions/your-sub-id" | Where-Object { $_.DisplayName -eq "your-service-principal" }
```

## Configuration Reference

### Complete Settings Schema

```json
{
  "azure": {
    "subscriptionId": "string (required)",
    "tenantId": "string (optional)",
    "defaultScope": "subscription|resourceGroup|managementGroup",
    "includedResourceGroups": ["array of strings"],
    "excludedResourceGroups": ["array of strings"],
    "excludedServices": ["array of strings"],
    "regions": {
      "included": ["array of strings"],
      "excluded": ["array of strings"]
    }
  },
  "reporting": {
    "defaultCurrency": "USD|EUR|GBP|...",
    "defaultDateRange": "number (days)",
    "timeZone": "string (timezone ID)",
    "dataRetentionDays": "number",
    "granularity": "Daily|Monthly"
  },
  "output": {
    "exportFormats": ["Excel", "CSV", "JSON"],
    "outputDirectory": "string (path)",
    "includeCharts": "boolean",
    "compressExports": "boolean",
    "fileNamePattern": "string (pattern)"
  },
  "notifications": {
    "enabled": "boolean",
    "smtp": {
      "server": "string",
      "port": "number",
      "useSSL": "boolean",
      "fromAddress": "string"
    },
    "recipients": ["array of email addresses"],
    "alerts": {
      "budgetThresholds": ["array of percentages"],
      "anomalyDetection": "boolean",
      "schedules": {
        "daily": "boolean",
        "weekly": "boolean",
        "monthly": "boolean"
      }
    }
  },
  "performance": {
    "maxRecordsPerQuery": "number",
    "queryTimeoutSeconds": "number",
    "enableCaching": "boolean",
    "cacheExpirationHours": "number",
    "parallelQueries": "boolean",
    "maxParallelism": "number"
  },
  "security": {
    "auditLogging": "boolean",
    "logPath": "string",
    "encryptExports": "boolean",
    "allowedUsers": ["array of user identities"]
  }
}
```

---

**Next Steps**: After configuration, run `Test-Configuration.ps1` to validate your setup, then execute `Get-CostReport.ps1` to generate your first cost analysis report.
