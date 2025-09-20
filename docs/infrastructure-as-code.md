# Infrastructure as Code Integration

This document provides comprehensive guidance for using Infrastructure as Code (IaC) tools with the Azure PowerShell Toolkit.

## Overview

The Azure PowerShell Toolkit now includes full Infrastructure as Code support through:

- **Bicep templates** for Azure-native IaC
- **Terraform configurations** for multi-cloud scenarios
- **Hybrid automation workflows** combining IaC with PowerShell scripts
- **CI/CD integration** for automated deployments

## Directory Structure

```
iac/
├── bicep/
│   ├── main.bicep              # Main Bicep template
│   ├── deploy.ps1              # Bicep deployment script
│   └── modules/
│       ├── network.bicep       # Virtual network resources
│       ├── storage.bicep       # Storage account resources
│       ├── keyvault.bicep      # Key Vault resources
│       ├── compute.bicep       # Virtual machine resources
│       ├── advanced.bicep      # Advanced resources (AKS, SQL, etc.)
│       └── monitoring.bicep    # Monitoring and logging
├── terraform/
│   ├── main.tf                 # Main Terraform configuration
│   ├── variables.tf            # Variable definitions
│   ├── outputs.tf              # Output definitions
│   ├── deploy.ps1              # Terraform deployment script
│   └── modules/
│       ├── network/            # Network module
│       ├── storage/            # Storage module
│       ├── key_vault/          # Key Vault module
│       ├── compute/            # Compute module
│       ├── advanced/           # Advanced resources module
│       └── monitoring/         # Monitoring module
└── scripts/
    └── integration/
        └── Deploy-WithIaC.ps1  # Integrated deployment script
```

## Getting Started

### Prerequisites

#### For Bicep
- Azure PowerShell modules
- Bicep CLI

```powershell
# Install Bicep CLI
az bicep install

# Verify installation
bicep --version
```

#### For Terraform
- Terraform CLI
- Azure CLI or Azure PowerShell

```powershell
# Install Terraform (Windows)
choco install terraform

# Verify installation
terraform version
```

### Basic Deployment

#### Using Bicep

```powershell
# Navigate to Bicep directory
cd iac/bicep

# Deploy to development environment
.\deploy.ps1 -Environment dev -Location "East US" -ResourceGroupName "toolkit-dev-rg"

# Deploy with advanced resources
.\deploy.ps1 -Environment prod -Location "East US" -ResourceGroupName "toolkit-prod-rg" -DeployAdvanced
```

#### Using Terraform

```powershell
# Navigate to Terraform directory
cd iac/terraform

# Deploy to development environment
.\deploy.ps1 -Environment dev -Location "East US" -AdminPassword "ComplexPassword123!"

# Plan deployment without applying
.\deploy.ps1 -Environment staging -Plan
```

### Integrated Deployment

Use the integrated deployment script to combine IaC with PowerShell automation:

```powershell
# Deploy with Bicep and run post-deployment configuration
.\scripts\integration\Deploy-WithIaC.ps1 -IaCTool Bicep -Environment dev -ConfigurePostDeployment -ValidateDeployment

# Deploy with Terraform
.\scripts\integration\Deploy-WithIaC.ps1 -IaCTool Terraform -Environment prod -ConfigurePostDeployment
```

## Resource Templates

### Bicep Templates

#### Basic Infrastructure
- Virtual Network with multiple subnets
- Network Security Groups with baseline rules
- Storage Account with security configurations
- Key Vault with access policies
- Virtual Machine with extensions

#### Advanced Resources (Optional)
- Azure Kubernetes Service (AKS)
- App Service Plan and Web App
- SQL Server and Database
- Application Insights
- Log Analytics Workspace

### Terraform Modules

#### Network Module
```hcl
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  resource_prefix    = local.resource_prefix
  tags              = local.common_tags
  environment       = local.environment
}
```

#### Storage Module
```hcl
module "storage" {
  source = "./modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  resource_prefix    = local.resource_prefix
  tags              = local.common_tags
  environment       = local.environment
}
```

## Environment Configuration

### Development Environment
- Basic resources for testing and development
- Cost-optimized configurations
- Standard storage and compute sizes

### Staging Environment
- Production-like configuration
- Enhanced monitoring and logging
- Security configurations enabled

### Production Environment
- High availability configurations
- Premium storage and compute
- Comprehensive monitoring and alerting
- Advanced security features

## CI/CD Integration

### GitHub Actions Workflow

The toolkit includes a comprehensive GitHub Actions workflow for hybrid automation:

```yaml
# Trigger workflow
name: Hybrid IaC and PowerShell Automation

# Environment-specific deployments
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [dev, staging, prod]
      iac_tool:
        type: choice
        options: [bicep, terraform]
```

### Workflow Features
- Environment validation
- Infrastructure deployment (Bicep or Terraform)
- PowerShell automation execution
- Compliance and security testing
- Artifact generation and reporting

## Best Practices

### Resource Naming
- Use consistent naming conventions
- Include environment and purpose in names
- Follow Azure naming recommendations

### Security Configuration
- Enable HTTPS-only traffic for storage accounts
- Configure Key Vault access policies properly
- Use Network Security Groups with least privilege
- Enable monitoring and logging

### Cost Optimization
- Use appropriate VM sizes for each environment
- Configure storage tiers based on access patterns
- Enable auto-shutdown for development resources
- Monitor and alert on cost thresholds

### Version Control
- Store IaC templates in version control
- Use branching strategies for environment promotion
- Tag releases for rollback capabilities
- Document changes and deployment procedures

## Troubleshooting

### Common Issues

#### Bicep Deployment Failures
```powershell
# Validate template syntax
bicep build main.bicep

# Check deployment details
Get-AzResourceGroupDeployment -ResourceGroupName "your-rg" | Select-Object -Last 1
```

#### Terraform State Issues
```powershell
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan
```

### Error Resolution

#### Resource Name Conflicts
- Ensure globally unique names for storage accounts
- Use random suffixes or timestamps
- Check existing resources before deployment

#### Permission Issues
- Verify Azure authentication
- Check role assignments and permissions
- Ensure service principal has required access

## Integration with PowerShell Scripts

### Post-Deployment Automation

After infrastructure deployment, use PowerShell scripts for:

- Resource configuration and validation
- Security compliance checking
- Monitoring setup and alerting
- Application deployment and configuration

### Example Integration

```powershell
# Deploy infrastructure
.\iac\bicep\deploy.ps1 -Environment prod

# Configure resources
.\scripts\monitoring\Azure-Resource-Health-Checker.ps1 -ResourceGroupName "toolkit-prod-rg"
.\scripts\network\Azure-KeyVault-Security-Monitor.ps1 -ResourceGroupName "toolkit-prod-rg"
.\scripts\compute\Azure-VM-List-All.ps1 -ResourceGroupName "toolkit-prod-rg"
```

## Advanced Scenarios

### Multi-Region Deployment
- Modify templates for multiple Azure regions
- Configure cross-region replication
- Implement disaster recovery procedures

### Hybrid Cloud Integration
- Extend Terraform configurations for multi-cloud
- Use Azure Arc for hybrid management
- Implement consistent policies across environments

### Custom Extensions
- Create additional Bicep modules for specific needs
- Develop custom Terraform providers
- Integrate with external systems and APIs

This comprehensive IaC integration provides a solid foundation for enterprise-grade Azure deployments while maintaining the flexibility and power of PowerShell automation.