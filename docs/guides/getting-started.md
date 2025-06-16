# Azure Enterprise Toolkit - Getting Started Guide

Welcome to the Azure Enterprise Toolkit! This comprehensive guide will help you get started with the most advanced Azure automation toolkit available, featuring 170+ PowerShell scripts, modern Infrastructure as Code templates, and cutting-edge enterprise capabilities.

## 📋 Prerequisites

### Required Software
- **PowerShell 7.0+** (Cross-platform support)
- **Azure PowerShell Module** (Latest version)
- **Azure CLI** (For modern services and Bicep)
- **Git** (For repository management)
- **Visual Studio Code** (Recommended IDE)

### Azure Requirements
- **Azure Subscription** with appropriate permissions
- **Resource Group Contributor** or higher role
- **Service Principal** (for automation scenarios)
- **Azure DevOps** or **GitHub** account (for CI/CD)

### Optional but Recommended
- **Docker Desktop** (for container development)
- **Terraform** (for multi-cloud scenarios)
- **Pester** (for testing PowerShell scripts)

## 🚀 Quick Installation

### 1. Clone the Repository
```bash
git clone https://github.com/wesellis/Azure-Enterprise-Toolkit.git
cd Azure-Enterprise-Toolkit
```

### 2. Install Required PowerShell Modules
```powershell
# Install Azure PowerShell modules
Install-Module Az -Force -AllowClobber -Scope CurrentUser

# Install Microsoft Graph module (for M365 integration)
Install-Module Microsoft.Graph -Force -AllowClobber -Scope CurrentUser

# Install Pester for testing
Install-Module Pester -Force -AllowClobber -Scope CurrentUser

# Verify installations
Get-Module Az -ListAvailable
Get-Module Microsoft.Graph -ListAvailable
```

### 3. Install Azure CLI and Extensions
```bash
# Windows (using winget)
winget install Microsoft.AzureCLI

# macOS (using Homebrew)
brew install azure-cli

# Linux (Ubuntu/Debian)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Bicep CLI
az bicep install

# Install helpful extensions
az extension add --name containerapp
az extension add --name spring-cloud
az extension add --name application-insights
```

### 4. Configure Azure Authentication
```powershell
# Interactive login
Connect-AzAccount

# Or using Service Principal
$securePassword = ConvertTo-SecureString "YourPassword" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("YourAppId", $securePassword)
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant "YourTenantId"

# Set default subscription
Set-AzContext -SubscriptionId "YourSubscriptionId"
```

## 🎯 Your First Automation

Let's start with a simple but powerful example - creating a modern web application infrastructure.

### Example 1: Deploy a Container App with Infrastructure
```powershell
# 1. Create a resource group
./automation-scripts/Identity-Governance/Azure-ResourceGroup-Creator.ps1 `
    -ResourceGroupName "my-first-app-rg" `
    -Location "East US" `
    -Tags @{Environment="Development"; Project="GettingStarted"}

# 2. Deploy Container Apps infrastructure using Bicep
az deployment group create `
    --resource-group "my-first-app-rg" `
    --template-file "./iac-templates/bicep/container-apps-enterprise.bicep" `
    --parameters namePrefix="myfirstapp" environment="dev" enableApplicationInsights=true

# 3. Deploy a sample application
./automation-scripts/App-Development/Azure-ContainerApps-Provisioning-Tool.ps1 `
    -ResourceGroupName "my-first-app-rg" `
    -ContainerAppName "my-web-app" `
    -ContainerImage "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" `
    -MinReplicas 1 `
    -MaxReplicas 5 `
    -EnableExternalIngress `
    -EnableApplicationInsights

# 4. Configure monitoring
./automation-scripts/Monitoring-Operations/Azure-LogAnalytics-Workspace-Creator.ps1 `
    -ResourceGroupName "my-first-app-rg" `
    -WorkspaceName "my-app-workspace" `
    -Location "East US"
```

### Example 2: Set Up AI Services
```powershell
# Deploy Azure OpenAI with enterprise security
az deployment group create `
    --resource-group "my-first-app-rg" `
    --template-file "./iac-templates/bicep/openai-enterprise.bicep" `
    --parameters namePrefix="myopenai" environment="dev" enablePrivateEndpoint=true

# Configure OpenAI service
./automation-scripts/App-Development/Azure-OpenAI-Service-Manager.ps1 `
    -ResourceGroupName "my-first-app-rg" `
    -AccountName "myopenai-dev" `
    -ModelName "gpt-35-turbo" `
    -DeploymentName "chat-model" `
    -EnableMonitoring
```

## 🏗️ Infrastructure as Code Workflows

### Using Bicep Templates
The toolkit includes advanced Bicep templates for enterprise scenarios:

```bash
# Deploy Container Apps with Application Gateway
az deployment group create \
    --resource-group "production-rg" \
    --template-file "./iac-templates/bicep/container-apps-enterprise.bicep" \
    --parameters namePrefix="prod" \
                 environment="production" \
                 enableApplicationGateway=true \
                 enablePrivateNetworking=true \
                 enableApplicationInsights=true

# Deploy OpenAI with full security
az deployment group create \
    --resource-group "ai-rg" \
    --template-file "./iac-templates/bicep/openai-enterprise.bicep" \
    --parameters namePrefix="enterprise" \
                 environment="production" \
                 enablePrivateEndpoint=true \
                 enableCustomerManagedKeys=true \
                 enableContentSafety=true
```

### Using PowerShell Automation Scripts
```powershell
# Create a complete Virtual WAN setup
./automation-scripts/Network-Security/Azure-Virtual-WAN-Management-Tool.ps1 `
    -ResourceGroupName "network-rg" `
    -VirtualWANName "enterprise-wan" `
    -Location "East US" `
    -Action "Create" `
    -VWANType "Standard" `
    -EnableMonitoring

# Add a virtual hub
./automation-scripts/Network-Security/Azure-Virtual-WAN-Management-Tool.ps1 `
    -ResourceGroupName "network-rg" `
    -VirtualWANName "enterprise-wan" `
    -Action "AddHub" `
    -HubName "hub-east" `
    -HubLocation "East US" `
    -HubAddressPrefix "10.1.0.0/24" `
    -EnableVpnGateway `
    -EnableAzureFirewall
```

## 🔒 Security and Compliance

### Enable Security Baseline
```powershell
# Run security assessment
./security-toolkit/assessments/Azure-SecurityAssessment-Reporter.ps1 `
    -ResourceGroupName "my-first-app-rg" `
    -OutputPath "./security-reports"

# Enable Microsoft Defender for Cloud
./security-toolkit/Microsoft-Defender-for-Cloud-Automation.ps1 `
    -Action "EnableDefender" `
    -DefenderPlans @("VirtualMachines", "AppService", "StorageAccounts") `
    -EnableMonitoring

# Apply governance policies
./governance/scripts/deploy-governance-policies.ps1 `
    -ResourceGroupName "my-first-app-rg" `
    -PolicySetName "Enterprise-Baseline"
```

## 📊 Cost Management and Optimization

### AI-Powered Cost Analysis
```powershell
# Run comprehensive cost analysis
./cost-management/scripts/Azure-AI-Cost-Optimization-Tool.ps1 `
    -SubscriptionId "your-subscription-id" `
    -Action "Analyze" `
    -TimeFrame "LastMonth" `
    -EnableAIInsights `
    -EnablePredictiveAnalytics `
    -EnableAutomatedRecommendations `
    -OutputFormat "Excel" `
    -OutputPath "./cost-reports"

# Set up cost monitoring
./cost-management/scripts/Azure-AI-Cost-Optimization-Tool.ps1 `
    -Action "Monitor" `
    -CostThreshold 1000 `
    -EnableSlackNotifications `
    -SlackWebhookUrl "your-webhook-url"
```

## 🤖 DevOps and CI/CD

### GitHub Actions Setup
1. Copy the workflow templates:
```bash
mkdir -p .github/workflows
cp ./devops-templates/github-actions/*.yml .github/workflows/
```

2. Configure secrets in your GitHub repository:
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_CONTAINER_REGISTRY`

3. Set up self-hosted runners:
```powershell
./devops-templates/GitHub-Actions-SelfHosted-Runner-Manager.ps1 `
    -ResourceGroupName "github-runners-rg" `
    -RunnerGroupName "enterprise-runners" `
    -Location "East US" `
    -Action "Deploy" `
    -GitHubOrganization "your-org" `
    -GitHubToken $gitHubToken `
    -RunnerCount 3 `
    -EnableAutoScaling
```

## 🧪 Testing and Validation

### Run the Comprehensive Test Suite
```powershell
# Run all tests
./tests/Azure-Toolkit-Test-Framework.ps1 `
    -TestScope "All" `
    -ResourceGroupName "test-rg" `
    -Location "East US" `
    -OutputFormat "JUnit" `
    -OutputPath "./test-results"

# Run only security tests
./tests/Azure-Toolkit-Test-Framework.ps1 `
    -TestScope "Security" `
    -ResourceGroupName "my-first-app-rg" `
    -OutputFormat "Console"

# Run performance tests
./tests/Azure-Toolkit-Test-Framework.ps1 `
    -TestScope "Performance" `
    -ResourceGroupName "production-rg" `
    -OutputFormat "JUnit"
```

## 🌐 Advanced Scenarios

### Hybrid and Multi-Cloud
```powershell
# Onboard on-premises servers to Azure Arc
./automation-scripts/Hybrid-MultiCloud/Azure-Arc-Server-Onboarding-Tool.ps1 `
    -ResourceGroupName "hybrid-rg" `
    -Location "East US" `
    -ServerName "on-prem-server-01" `
    -EnableMonitoring `
    -ConfigureCompliance
```

### IoT and Digital Twins
```powershell
# Create Digital Twins instance
./automation-scripts/IoT-Analytics/Azure-DigitalTwins-Management-Tool.ps1 `
    -ResourceGroupName "iot-rg" `
    -InstanceName "factory-dt" `
    -Location "East US" `
    -Action "Create" `
    -EnableEventRouting `
    -EnableTimeSeriesInsights
```

### Enterprise Java Applications
```powershell
# Deploy Spring Apps
./automation-scripts/App-Development/Azure-SpringApps-Management-Tool.ps1 `
    -ResourceGroupName "java-apps-rg" `
    -SpringAppsName "enterprise-spring" `
    -Location "East US" `
    -Action "Create" `
    -Tier "Enterprise" `
    -EnableApplicationInsights `
    -EnableConfigServer
```

## 📚 Next Steps

### 1. Explore Component-Specific Guides
- [Security Toolkit Guide](../security-toolkit/README.md)
- [Cost Management Guide](../cost-management/README.md)
- [DevOps Templates Guide](../devops-templates/README.md)
- [IaC Templates Guide](../iac-templates/README.md)

### 2. Learn Best Practices
- [Security Best Practices](../best-practices/security.md)
- [Performance Optimization](../best-practices/performance.md)
- [Cost Optimization Strategies](../best-practices/cost-optimization.md)

### 3. Join the Community
- **GitHub Discussions**: Share experiences and get help
- **GitHub Issues**: Report bugs and request features
- **Slack Community**: Real-time chat and support

### 4. Contribute Back
- Submit bug fixes and improvements
- Add new automation scripts
- Enhance documentation
- Share your use cases

## 🆘 Troubleshooting

### Common Issues and Solutions

#### Authentication Problems
```powershell
# Clear cached credentials
Disconnect-AzAccount
Clear-AzContext -Force

# Re-authenticate
Connect-AzAccount
```

#### Module Import Issues
```powershell
# Update PowerShell modules
Update-Module Az -Force
Update-Module Microsoft.Graph -Force

# Import with explicit version
Import-Module Az -RequiredVersion "10.0.0" -Force
```

#### Resource Deployment Failures
```powershell
# Check deployment status
Get-AzResourceGroupDeployment -ResourceGroupName "your-rg" | Select-Object DeploymentName, ProvisioningState, Timestamp

# Get detailed error information
Get-AzResourceGroupDeploymentOperation -ResourceGroupName "your-rg" -DeploymentName "deployment-name"
```

### Getting Help
- **Documentation**: Check the `/docs` directory for detailed guides
- **GitHub Issues**: Search existing issues or create a new one
- **Email Support**: wes@wesellis.com for enterprise customers
- **Community**: Join our discussions for peer support

## 🎉 Congratulations!

You're now ready to leverage the full power of the Azure Enterprise Toolkit. Start with simple scenarios and gradually explore the advanced capabilities as you become more comfortable with the toolkit.

Remember:
- Start small and iterate
- Use the testing framework to validate changes
- Follow security best practices
- Monitor costs and performance
- Contribute back to the community

Happy automating! 🚀
