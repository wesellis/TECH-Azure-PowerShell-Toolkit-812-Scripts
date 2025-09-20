# Infrastructure as Code Templates

This directory contains modern Infrastructure as Code (IaC) templates for deploying Azure resources using various tools and frameworks.

##  Directory Structure

```
iac-templates/
├── bicep/          # Modern Azure Resource Manager templates
├── terraform/      # Multi-cloud infrastructure automation
├── pulumi/         # Developer-friendly infrastructure definitions  
└── arm/            # Classic ARM templates (legacy support)
```

##  Bicep Templates

Modern, declarative Azure resource definitions with enhanced developer experience.

### Available Templates

- **`webapp-with-sql.bicep`** - Complete web application with SQL Database
  - App Service with managed identity
  - SQL Server with Advanced Threat Protection
  - Key Vault for secrets management
  - Application Insights monitoring
  - Log Analytics workspace
  - Enterprise security and compliance features

### Usage Example

```bash
# Deploy web application stack
az deployment group create \
  --resource-group myResourceGroup \
  --template-file bicep/webapp-with-sql.bicep \
  --parameters webAppName=myapp \
               sqlServerName=myserver \
               sqlAdminUsername=sqladmin \
               sqlAdminPassword=YourSecurePassword123! \
               environment=Production
```

## 🏗️ Key Features

### Enterprise-Ready Templates
- **Security First** - HTTPS only, TLS 1.2, managed identities
- **Monitoring Built-in** - Application Insights and Log Analytics
- **Secrets Management** - Key Vault integration
- **Compliance Tags** - Enterprise governance standards
- **Threat Protection** - Advanced security features

### Modern DevOps Integration
- **Parameter Validation** - Type-safe parameter definitions
- **Modular Design** - Reusable components and modules
- **Output Optimization** - Structured deployment information
- **Documentation** - Inline comments and examples

##  Template Categories

### Web Applications
- Single-page applications (SPA)
- Multi-tier web applications
- API backends with databases
- Microservices architectures

### Data Platforms
- SQL Database clusters
- Cosmos DB implementations
- Data warehouse solutions
- Analytics workspaces

### Security & Identity
- Key Vault deployments
- Managed identity configurations
- Network security groups
- Private endpoint implementations

## ️ Development Guidelines

### Template Standards
- Use latest API versions
- Include comprehensive parameter validation
- Implement proper resource dependencies
- Add detailed output information
- Include enterprise tagging strategy

### Security Requirements
- Enable HTTPS-only communication
- Use managed identities where possible
- Implement network restrictions
- Enable audit logging
- Configure threat protection

##  Getting Started

1. **Choose Template** - Select appropriate template for your use case
2. **Review Parameters** - Understand required and optional parameters
3. **Customize Values** - Modify parameters for your environment
4. **Deploy Template** - Use Azure CLI, PowerShell, or portal
5. **Validate Deployment** - Verify resources and configurations

## 🔗 Related Resources

- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [ARM Template Best Practices](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/best-practices)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)

## 🤝 Contributing

We welcome contributions of new templates and improvements to existing ones. Please follow our [Contributing Guidelines](../../CONTRIBUTING.md) when submitting templates.

### Template Submission Checklist
- [ ] Follows naming conventions
- [ ] Includes parameter validation
- [ ] Has comprehensive documentation
- [ ] Implements security best practices
- [ ] Includes usage examples
- [ ] Tested in multiple environments
