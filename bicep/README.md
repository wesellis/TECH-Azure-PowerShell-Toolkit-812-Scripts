# Bicep Templates

Azure Bicep templates for common infrastructure patterns.

## Usage

```bash
# Deploy a template
az deployment group create \
  --resource-group myResourceGroup \
  --template-file compute/virtual-machine.bicep \
  --parameters vmName=myVM adminUsername=azureuser adminPassword=SecurePassword123!
```

## Templates

### Compute
- `virtual-machine.bicep` - Windows/Linux VM with networking

### Storage
- `storage-account.bicep` - Standard storage account with container

### Network
- `virtual-network.bicep` - VNet with configurable subnets

## Parameters

Each template includes parameter descriptions and allowed values. Use `--parameters` to override defaults.

## Examples

```bash
# Create Linux VM
az deployment group create \
  --resource-group rg-dev \
  --template-file compute/virtual-machine.bicep \
  --parameters vmName=web-server osType=Linux adminUsername=admin

# Create storage account
az deployment group create \
  --resource-group rg-storage \
  --template-file storage/storage-account.bicep \
  --parameters storageAccountName=mystorageacct storageAccountType=Standard_GRS
```