# Terraform Configurations

Production-ready Terraform configurations for Azure infrastructure.

## Features

- **Input Validation**: Comprehensive variable validation
- **Environment Awareness**: Different configs for dev/test/prod
- **Security Defaults**: Restricted network access, managed identities
- **Conditional Resources**: Optional public IPs, environment-specific settings
- **Best Practices**: Proper tagging, naming conventions, zones

## Quick Start

```bash
# 1. Copy example variables
cd terraform/compute
cp terraform.tfvars.example terraform.tfvars

# 2. Edit variables
vim terraform.tfvars

# 3. Deploy
terraform init
terraform plan
terraform apply
```

## Available Configurations

### Infrastructure Components

#### Compute (`/compute/`)
- Linux VM with optional public IP
- Network security groups with environment-based rules
- Managed identity and boot diagnostics
- Availability zones for production

#### Storage (`/storage/`)
- Storage account with secure defaults
- Private containers and HTTPS enforcement
- Environment-appropriate replication

#### Network (`/network/`)
- Virtual network with configurable subnets
- Proper resource dependencies

### Terraform Modules (`/modules/`)

#### Networking Module (`/modules/networking`)
- Complete virtual network with configurable subnets
- Network security groups with purpose-based rules
- NAT Gateway for outbound connectivity
- Route tables and service endpoints

#### Compute Module (`/modules/compute`)
- Multi-instance VM deployment
- Support for both Linux and Windows
- Availability sets and zones
- Data disk management
- Custom initialization scripts

### Application Templates (`/applications/`)

#### Three-Tier Application (`/applications/three-tier-app.tf`)
- Complete multi-tier architecture
- Load balancers for web and app tiers
- SQL Database with security features
- Application Gateway for production
- Environment-specific configurations

## Variable Examples

```hcl
# Development environment
vm_name             = "dev-web"
environment         = "dev"
resource_group_name = "rg-dev"
vm_size            = "Standard_B2s"
create_public_ip   = true
network_access     = "open"

# Production environment
vm_name             = "prod-web"
environment         = "prod"
resource_group_name = "rg-prod"
vm_size            = "Standard_D4s_v3"
create_public_ip   = false
network_access     = "restricted"
```

## Validation

Variables include validation rules:

- VM names: 1-15 characters, alphanumeric + hyphens
- Environment: Must be dev/test/prod
- VM sizes: Only approved SKUs
- Passwords: Minimum 12 characters

## Outputs

All configurations provide useful outputs:

- Resource IDs and connection strings
- IP addresses and FQDNs
- SSH/RDP connection commands