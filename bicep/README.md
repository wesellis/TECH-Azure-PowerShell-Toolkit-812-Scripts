# Bicep Templates

Production-ready Azure Bicep templates with enterprise features.

## Features

- **Parameter Validation**: Length limits, allowed values, regex patterns
- **Environment Awareness**: Different configurations per environment
- **Security First**: Restricted network access, secure authentication
- **Conditional Resources**: Optional public IPs, monitoring features
- **Best Practices**: Proper naming, tagging, zones for production

## Quick Start

```bash
# 1. Use parameter file (recommended)
az deployment group create \
  --resource-group myResourceGroup \
  --template-file compute/virtual-machine.bicep \
  --parameters @compute/parameters.json

# 2. Or specify parameters inline
az deployment group create \
  --resource-group myResourceGroup \
  --template-file compute/virtual-machine.bicep \
  --parameters vmName=web-server environment=dev
```

## Templates

### Compute (`virtual-machine.bicep`)
- Windows/Linux VM with comprehensive configuration
- SSH key or password authentication
- Optional public IP with DNS name
- Network security groups with environment-based rules
- Availability zones for production environments
- Managed identity and monitoring support

### Storage (`storage-account.bicep`)
- Storage account with security defaults
- HTTPS enforcement and TLS 1.2 minimum
- Private blob access by default

### Network (`virtual-network.bicep`)
- Virtual network with configurable subnets
- NSG association support

## Parameter Files

Use parameter files for consistent deployments:

```json
{
  "vmName": { "value": "web-server" },
  "environment": { "value": "dev" },
  "adminUsername": { "value": "azureuser" },
  "osType": { "value": "Ubuntu" },
  "networkAccess": { "value": "restricted" }
}
```

## Examples

```bash
# Development VM with public IP
az deployment group create \
  --resource-group rg-dev \
  --template-file compute/virtual-machine.bicep \
  --parameters vmName=dev-web environment=dev createPublicIP=true

# Production VM without public IP
az deployment group create \
  --resource-group rg-prod \
  --template-file compute/virtual-machine.bicep \
  --parameters vmName=prod-web environment=prod createPublicIP=false

# Use SSH key authentication
az deployment group create \
  --resource-group rg-prod \
  --template-file compute/virtual-machine.bicep \
  --parameters authenticationType=sshPublicKey adminPasswordOrKey="ssh-rsa AAAA..."
```

## Available Templates

### Infrastructure Templates
- **`compute/virtual-machine.bicep`** - Enterprise VM with security features
- **`storage/storage-account.bicep`** - Secure storage with compliance defaults
- **`storage/sql-database.bicep`** - SQL Server with advanced security
- **`network/virtual-network.bicep`** - VNet with configurable subnets
- **`monitoring/log-analytics.bicep`** - Complete monitoring stack
- **`security/key-vault.bicep`** - Key Vault with RBAC and private endpoints

### Application Templates
- **`applications/web-app-stack.bicep`** - Complete web application stack with App Service, SQL, Key Vault, and Application Gateway

## Template Features

- **Environment Awareness**: Different configurations for dev/test/prod
- **Security by Default**: Private endpoints, RBAC, minimal permissions
- **Monitoring Integration**: Built-in diagnostics and alerting
- **High Availability**: Availability zones and redundancy for production
- **Cost Optimization**: Environment-appropriate SKUs and features

## Validation

Templates include comprehensive validation:
- VM names: 1-15 characters
- Environment: dev/test/prod only
- Authentication types: password or SSH key
- Network access: restricted or open