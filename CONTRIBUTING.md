# Contributing to Azure Enterprise Toolkit

We welcome contributions from the Azure community! This guide will help you get started.

## 🤝 Ways to Contribute

- **🐛 Bug Reports** - Help us improve reliability
- **💡 Feature Requests** - Suggest new automation scenarios  
- **📖 Documentation** - Help other administrators get started
- **🧪 Testing** - Validate scripts in different environments
- **🚀 New Scripts** - Add automation for additional scenarios
- **🔧 Improvements** - Enhance existing functionality

## 📋 Contribution Process

### 1. Fork & Clone
```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/Azure-Enterprise-Toolkit.git
cd Azure-Enterprise-Toolkit
```

### 2. Create a Branch
```bash
git checkout -b feature/amazing-automation
```

### 3. Make Your Changes
- Follow our coding standards (see below)
- Test your changes thoroughly
- Update documentation as needed

### 4. Commit & Push
```bash
git add .
git commit -m "Add amazing Azure automation feature"
git push origin feature/amazing-automation
```

### 5. Create Pull Request
- Go to GitHub and create a Pull Request
- Fill out the PR template completely
- Wait for review and address feedback

## 🛠️ Development Guidelines

### PowerShell Script Standards

```powershell
# ✅ Good Example
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US"
)

# Professional header
Write-Host "=== Azure Resource Creation Tool ===" -ForegroundColor Green
Write-Host "Creating resources in: $ResourceGroupName" -ForegroundColor Cyan

try {
    # Your automation logic here
    Write-Host "✅ Operation completed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

### Required Elements

1. **Parameter Validation**
   - Use `[Parameter()]` attributes
   - Validate inputs properly
   - Provide meaningful defaults

2. **Error Handling**
   - Wrap operations in try-catch blocks
   - Provide clear error messages
   - Use appropriate exit codes

3. **Professional Output**
   - Colored console output
   - Progress indicators where appropriate
   - Clear success/failure messages

4. **Documentation**
   - Comment complex logic
   - Include usage examples
   - Document parameters

### File Organization

```
automation-scripts/
├── Category-Name/
│   ├── Azure-Service-Action-Tool.ps1    # Descriptive naming
│   └── Azure-Service-Manager.ps1        # Consistent patterns
```

## 🧪 Testing

### Manual Testing
```powershell
# Test in a development environment first
.\your-script.ps1 -WhatIf  # If supported
```

### Automated Testing
```powershell
# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path .\your-script.ps1

# Run any Pester tests
Invoke-Pester .\tests\your-script.Tests.ps1
```

## 📝 Documentation Standards

### README Updates
- Update component READMEs when adding new scripts
- Include usage examples
- Document any new prerequisites

### Code Comments
```powershell
# This function creates an Azure resource group with enterprise tags
function New-EnterpriseResourceGroup {
    param(
        [string]$Name,      # Resource group name
        [string]$Location   # Azure region
    )
    
    # Implementation here...
}
```

## 🚀 Script Categories

When adding new scripts, place them in the appropriate category:

- **App-Development** - Application services, functions, logic apps
- **Compute-Management** - VMs, containers, AKS clusters  
- **Data-Storage** - Databases, storage accounts, data services
- **General-Utilities** - Cross-service tools and helpers
- **Identity-Governance** - RBAC, policies, compliance
- **Monitoring-Operations** - Monitoring, alerts, diagnostics
- **Network-Security** - Networking, security, key management

## 🎯 Pull Request Template

When creating a PR, include:

- **What**: Brief description of changes
- **Why**: Reason for the change/improvement
- **Testing**: How you validated the changes
- **Documentation**: Any docs updates needed
- **Breaking Changes**: Note any breaking changes

## 📞 Getting Help

- **Questions**: Open a Discussion on GitHub
- **Issues**: Create an Issue with details
- **Direct Contact**: Email wes@wesellis.com for complex topics

## ⚡ Quick Start for Contributors

### Adding a New Automation Script

1. **Choose the right category** (see above)
2. **Use consistent naming**: `Azure-ServiceName-Action-Tool.ps1`
3. **Follow the template**:

```powershell
# Azure [Service] [Action] Tool
# Professional Azure automation script
# Author: Your Name <your@email.com>

param(
    [Parameter(Mandatory=$true)]
    [string]$RequiredParameter,
    
    [Parameter(Mandatory=$false)]
    [string]$OptionalParameter = "DefaultValue"
)

# Professional banner
Write-Host "=== Azure [Service] [Action] Tool ===" -ForegroundColor Green
Write-Host "Processing: $RequiredParameter" -ForegroundColor Cyan

try {
    # Connect to Azure if needed
    if (-not (Get-AzContext)) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    
    # Your automation logic here
    
    Write-Host "✅ Operation completed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

4. **Test thoroughly** in a development environment
5. **Update documentation** and examples
6. **Submit PR** with detailed description

Thank you for contributing to the Azure Enterprise Toolkit! 🚀