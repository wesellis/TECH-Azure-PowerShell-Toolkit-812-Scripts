# Tutorial: Toolkit Setup and Configuration

**Difficulty**: Beginner  
**Estimated Time**: 15-20 minutes  
**Prerequisites**: Basic PowerShell knowledge, Azure subscription

## Learning Objectives

By the end of this tutorial, you will:

- Install and configure the Azure Enterprise PowerShell Toolkit
- Set up your Azure connection and authentication
- Verify the toolkit installation and basic functionality
- Understand the toolkit's folder structure and key components

## Prerequisites

Before starting this tutorial, ensure you have:

- [ ] Windows PowerShell 5.1 or PowerShell 7+ installed
- [ ] Azure subscription with appropriate permissions
- [ ] Git installed on your system
- [ ] Text editor (VS Code recommended)

## Step 1: Download the Toolkit

### Option A: Clone from GitHub (Recommended)

```powershell
# Clone the repository
git clone https://github.com/your-org/azure-powershell-toolkit.git
cd azure-powershell-toolkit

# Verify the download
Get-ChildItem | Format-Table Name, Length, LastWriteTime
```

### Option B: Download ZIP File

1. Visit the [GitHub repository](https://github.com/your-org/azure-powershell-toolkit)
2. Click **Code** → **Download ZIP**
3. Extract to your preferred location
4. Navigate to the extracted folder in PowerShell

## Step 2: Install Required Modules

The toolkit requires several PowerShell modules. Run the installation script:

```powershell
# Run the setup script (as Administrator)
.\scripts\Install-Prerequisites.ps1

# Alternatively, install modules manually
Install-Module Az -Force -AllowClobber
Install-Module PSScriptAnalyzer -Force
Install-Module Pester -Force
```

> **Note**: You may need to run PowerShell as Administrator for module installation.

## Step 3: Configure Azure Authentication

### Option A: Interactive Login (Recommended for Development)

```powershell
# Import the toolkit
Import-Module .\modules\AzureToolkit

# Connect to Azure interactively
Connect-AzureToolkit
```

### Option B: Service Principal (Recommended for Production)

```powershell
# Set up service principal authentication
$servicePrincipal = @{
    ApplicationId = "your-app-id"
    TenantId = "your-tenant-id"
    CertificateThumbprint = "your-cert-thumbprint"
}

Connect-AzureToolkit -ServicePrincipal $servicePrincipal
```

### Option C: Managed Identity (For Azure VMs)

```powershell
# Use managed identity authentication
Connect-AzureToolkit -UseManagedIdentity
```

## Step 4: Configure Toolkit Settings

Create your configuration file:

```powershell
# Copy the example configuration
Copy-Item .\config\config.example.json .\config\config.json

# Edit the configuration
notepad .\config\config.json
```

Example configuration:

```json
{
    "defaultSubscription": "your-subscription-id",
    "defaultResourceGroup": "rg-toolkit-demo",
    "defaultLocation": "East US",
    "logging": {
        "level": "Information",
        "path": "./logs"
    },
    "features": {
        "enableCostAnalysis": true,
        "enableMonitoring": true,
        "enableAutomation": true
    }
}
```

## Step 5: Verify Installation

Run the verification script to ensure everything is working:

```powershell
# Run the verification script
.\scripts\Test-Installation.ps1

# Expected output:
# PowerShell version: OK
# Required modules: OK
# Azure connection: OK
# Configuration file: OK
# Toolkit modules: OK
```

### Manual Verification

You can also verify manually:

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Verify Azure modules
Get-Module Az -ListAvailable | Select-Object Name, Version

# Test Azure connection
Get-AzContext

# Test toolkit modules
Get-Module AzureToolkit
```

## Step 6: Explore the Toolkit Structure

Familiarize yourself with the toolkit organization:

```powershell
# View the main folders
Get-ChildItem | Where-Object PSIsContainer | Format-Table Name, @{Name="Purpose";Expression={
    switch ($_.Name) {
        "bicep" { "Infrastructure as Code templates" }
        "docs" { "Documentation and guides" }
        "modules" { "PowerShell modules" }
        "scripts" { "Automation scripts" }
        "tests" { "Unit and integration tests" }
        "config" { "Configuration files" }
        "tools" { "Utility tools" }
        default { "See docs/reference/folder-organization.md" }
    }
}}
```

## Step 7: Run Your First Command

Test the toolkit with a simple command:

```powershell
# Get subscription information
Get-AzureSubscriptionInfo

# List resource groups
Get-AzureResourceGroups | Format-Table Name, Location, @{Name="Resources";Expression={$_.Resources.Count}}

# Get cost summary (if cost analysis is enabled)
Get-AzureCostSummary -Days 30
```

## Verification Checklist

Confirm you've completed all steps:

- [ ] Toolkit downloaded and extracted
- [ ] Required PowerShell modules installed
- [ ] Azure authentication configured
- [ ] Configuration file created and customized
- [ ] Installation verified successfully
- [ ] Folder structure explored
- [ ] First commands executed successfully

## Troubleshooting

### Common Issues and Solutions

**Issue**: Module import fails
```powershell
# Solution: Check execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Issue**: Azure connection fails
```powershell
# Solution: Clear and reconnect
Disconnect-AzAccount
Clear-AzContext -Force
Connect-AzAccount
```

**Issue**: Configuration file errors
```powershell
# Solution: Validate JSON syntax
Get-Content .\config\config.json | ConvertFrom-Json
```

**Issue**: Permission errors
```powershell
# Solution: Check Azure RBAC permissions
Get-AzRoleAssignment | Where-Object {$_.SignInName -eq (Get-AzContext).Account.Id}
```

## Next Steps

Now that you have the toolkit set up, continue with:

1. **[Basic Azure Connection](02-azure-connection.md)** - Learn advanced connection scenarios
2. **[First Automation Script](03-first-automation.md)** - Create your first automation
3. **[API Documentation](../api/scripts-overview.md)** - Explore available functions

## Tips for Success

- **Start Small**: Begin with simple scripts and gradually increase complexity
- **Use Version Control**: Keep your customizations in Git
- **Read Documentation**: The toolkit includes extensive documentation
- **Join the Community**: Participate in discussions and contribute improvements
- **Practice Regularly**: Regular use will help you master the toolkit

## Keeping Updated

To update the toolkit:

```powershell
# Update from Git
git pull origin main

# Update PowerShell modules
Update-Module Az

# Re-run verification
.\scripts\Test-Installation.ps1
```

---

**Congratulations!** You've successfully set up the Azure Enterprise PowerShell Toolkit. You're ready to start automating your Azure environment!

**Next Tutorial**: [Basic Azure Connection](02-azure-connection.md)
