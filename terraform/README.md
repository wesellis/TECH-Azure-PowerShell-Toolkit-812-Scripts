# Terraform Configurations

Terraform configurations for Azure infrastructure deployment.

## Usage

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="vm_name=myvm" -var="resource_group_name=myrg"

# Apply configuration
terraform apply -var="vm_name=myvm" -var="resource_group_name=myrg"
```

## Configurations

### Compute
- VM with public IP and NSG

### Storage
- Storage account with container

### Network
- VNet with multiple subnets

## Variables

Each configuration uses variables for customization. Create `terraform.tfvars`:

```hcl
vm_name             = "web-server"
resource_group_name = "rg-production"
location           = "East US"
vm_size            = "Standard_D2s_v3"
```

## Examples

```bash
# Deploy VM
cd terraform/compute
terraform init
terraform plan -var-file="../../terraform.tfvars"
terraform apply

# Deploy storage
cd ../storage
terraform init
terraform apply -var="storage_account_name=prodstorageacct"
```