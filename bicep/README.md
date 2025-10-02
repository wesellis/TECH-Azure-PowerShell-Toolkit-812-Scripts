# Azure Bicep Templates

Enterprise-ready Azure Bicep templates with comprehensive security, monitoring, and best practices built-in.

## ✨ Features

- **🔒 Security by Default**: Private endpoints, RBAC, minimal permissions, TLS 1.2+
- **🌍 Environment Awareness**: Automatic configuration scaling for dev/test/prod
- **📊 Built-in Monitoring**: Diagnostics, alerting, and Log Analytics integration
- **🎯 Parameter Validation**: Comprehensive input validation and constraints
- **⚡ High Availability**: Availability zones, redundancy, and auto-scaling for production
- **💰 Cost Optimized**: Environment-appropriate SKUs and resource sizing
- **🏗️ Conditional Resources**: Optional features based on environment and requirements

## 📁 Template Structure

```
bicep/
├── applications/          # Complete application stacks
│   └── web-app-stack.bicep    # Full web app with SQL, Key Vault, App Gateway
├── compute/              # Virtual machines and compute resources
│   └── virtual-machine.bicep  # Enterprise VM with security features
├── storage/              # Storage and database resources
│   ├── storage-account.bicep  # Secure storage with compliance
│   └── sql-database.bicep     # SQL Server with advanced security
├── network/              # Networking components
│   └── virtual-network.bicep  # VNet with NSGs and service endpoints
├── security/             # Security and identity resources
│   └── key-vault.bicep        # Key Vault with RBAC and private endpoints
└── monitoring/           # Monitoring and observability
    └── log-analytics.bicep    # Complete monitoring stack
```

## 🚀 Quick Start

### 1. Basic Deployment
```bash
# Deploy a development virtual machine
az deployment group create \
  --resource-group rg-dev \
  --template-file compute/virtual-machine.bicep \
  --parameters vmName=dev-web environment=dev adminUsername=azureuser \
  --parameters adminPasswordOrKey='your-secure-password'
```

### 2. Using Parameter Files (Recommended)
```bash
# Create a parameter file
cat > vm-params.json << EOF
{
  "vmName": { "value": "web-server" },
  "environment": { "value": "prod" },
  "adminUsername": { "value": "azureuser" },
  "adminPasswordOrKey": { "value": "ssh-rsa AAAA..." },
  "authenticationType": { "value": "sshPublicKey" },
  "createPublicIP": { "value": false },
  "enableMonitoring": { "value": true }
}
EOF

# Deploy using parameter file
az deployment group create \
  --resource-group rg-prod \
  --template-file compute/virtual-machine.bicep \
  --parameters @vm-params.json
```

### 3. Complete Web Application Stack
```bash
az deployment group create \
  --resource-group rg-myapp-prod \
  --template-file applications/web-app-stack.bicep \
  --parameters appName=myapp environment=prod \
  --parameters administratorObjectId=$(az ad signed-in-user show --query id -o tsv) \
  --parameters dbAdminUsername=sqladmin dbAdminPassword='YourSecurePassword123!'
```

## 📚 Template Catalog

### 🖥️ Compute Resources
**`compute/virtual-machine.bicep`**
- Windows/Linux VMs with enterprise security
- SSH key or password authentication
- Environment-based sizing (B2s → D4s_v3)
- Optional public IP with DNS names
- Boot diagnostics and monitoring agents
- Backup configuration for production
- Custom script extensions

### 💾 Storage Resources
**`storage/storage-account.bicep`**
- Secure storage with compliance defaults
- Environment-based replication (LRS → GRS)
- Blob versioning and soft delete
- Lifecycle management policies
- Private endpoints for production
- Comprehensive diagnostic logging

**`storage/sql-database.bicep`**
- SQL Server with advanced threat protection
- Environment-based SKUs (Basic → GP_Gen5_4)
- Automated backups with LTR policies
- Auditing and vulnerability assessments
- Azure AD authentication support
- Private endpoints and network isolation

### 🌐 Network Resources
**`network/virtual-network.bicep`**
- Multi-environment subnet configurations
- Network Security Groups with environment-specific rules
- Service endpoints and delegations
- DDoS protection for production
- Flow logs and network monitoring
- Route tables for traffic control

### 🔐 Security Resources
**`security/key-vault.bicep`**
- RBAC-enabled Key Vault with proper permissions
- Soft delete and purge protection
- Premium SKU for production HSM support
- Private endpoints and network ACLs
- Certificate and key rotation policies
- Event Grid notifications

### 📊 Monitoring Resources
**`monitoring/log-analytics.bicep`**
- Log Analytics workspace with data retention policies
- Application Insights integration
- Environment-based quotas and retention
- Alert rules for common scenarios
- Action groups for notifications
- Solution gallery integrations

### 🏗️ Application Stacks
**`applications/web-app-stack.bicep`**
- Complete web application infrastructure
- App Service with VNet integration
- SQL Database with private connectivity
- Key Vault for secrets management
- Application Gateway with WAF
- Comprehensive monitoring and alerting
- RBAC assignments for managed identities

## 📋 Environment Configurations

| Resource | Dev | Test | Prod |
|----------|-----|------|------|
| **VM Size** | B2s | D2s_v3 | D4s_v3 |
| **Storage** | Standard_LRS | Standard_ZRS | Standard_GRS |
| **SQL SKU** | Basic | Standard S2 | GP_Gen5_4 |
| **Backup Retention** | 7 days | 14 days | 35 days |
| **Log Retention** | 7 days | 30 days | 90 days |
| **Private Endpoints** | No | No | Yes |
| **Zone Redundancy** | No | No | Yes |

## 🔧 Advanced Usage

### Custom Network Integration
```bash
# Deploy VM into existing VNet
az deployment group create \
  --resource-group rg-prod \
  --template-file compute/virtual-machine.bicep \
  --parameters vmName=app-server environment=prod \
  --parameters existingVnetId="/subscriptions/.../virtualNetworks/vnet-prod" \
  --parameters existingSubnetId="/subscriptions/.../subnets/vm-subnet"
```

### Multi-Region Deployment
```bash
# Deploy to multiple regions
for region in "eastus" "westus2" "centralus"; do
  az deployment group create \
    --resource-group "rg-myapp-${region}" \
    --template-file applications/web-app-stack.bicep \
    --parameters appName=myapp environment=prod \
    --parameters location="${region}" \
    --parameters @common-params.json
done
```

### Enable All Security Features
```bash
az deployment group create \
  --resource-group rg-secure-app \
  --template-file applications/web-app-stack.bicep \
  --parameters appName=secureapp environment=prod \
  --parameters enablePrivateEndpoints=true \
  --parameters enableApplicationGateway=true \
  --parameters enableBackup=true \
  --parameters enableMonitoring=true
```

## 🎛️ Parameter Reference

### Common Parameters
- **`environment`**: `dev` | `test` | `prod` - Controls resource sizing and features
- **`location`**: Azure region (defaults to resource group location)
- **`tags`**: Custom resource tags (merged with default tags)

### Security Parameters
- **`enablePrivateEndpoints`**: Enable private network connectivity
- **`networkAccess`**: `restricted` | `open` - Network security level
- **`enableRbacAuthorization`**: Use RBAC instead of access policies

### Monitoring Parameters
- **`enableMonitoring`**: Enable comprehensive monitoring and alerting
- **`logAnalyticsWorkspaceId`**: Existing workspace ID (creates new if empty)
- **`adminEmail`**: Email for alerts and notifications

## 🛠️ Development Workflow

### 1. Validate Templates
```bash
# Validate syntax and parameters
az deployment group validate \
  --resource-group rg-test \
  --template-file compute/virtual-machine.bicep \
  --parameters @test-params.json
```

### 2. Preview Changes
```bash
# See what resources will be created/modified
az deployment group what-if \
  --resource-group rg-test \
  --template-file compute/virtual-machine.bicep \
  --parameters @test-params.json
```

### 3. Deploy with Confirmation
```bash
# Deploy with explicit confirmation
az deployment group create \
  --resource-group rg-test \
  --template-file compute/virtual-machine.bicep \
  --parameters @test-params.json \
  --confirm-with-what-if
```

## 🔍 Troubleshooting

### Common Issues
1. **Deployment Failures**: Check Azure Activity Log for detailed error messages
2. **Permission Errors**: Ensure your account has Contributor role on the resource group
3. **Name Conflicts**: Resource names must be globally unique (storage accounts, Key Vaults)
4. **Quota Limits**: Verify subscription limits for VM cores, storage accounts, etc.

### Debugging Tips
```bash
# Get deployment details
az deployment group show \
  --resource-group rg-test \
  --name vm-deployment \
  --query properties.error

# List all deployments
az deployment group list \
  --resource-group rg-test \
  --query "[].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}"
```

## 📈 Best Practices

1. **Use Parameter Files**: Store environment-specific configurations in parameter files
2. **Validate First**: Always run `validate` and `what-if` before deploying
3. **Tag Resources**: Use consistent tagging for cost management and governance
4. **Start Small**: Begin with dev environment, then promote to production
5. **Monitor Deployments**: Set up alerts for deployment failures
6. **Version Control**: Store templates and parameters in source control
7. **Least Privilege**: Use managed identities and RBAC instead of passwords

## 🤝 Contributing

To add new templates or improve existing ones:
1. Follow the established parameter patterns
2. Include comprehensive validation and defaults
3. Add environment-specific configurations
4. Include monitoring and security features
5. Document all parameters and outputs
6. Test across all environments (dev/test/prod)

## 📄 License

These templates are provided as-is for educational and production use. Always review and test in non-production environments first.
