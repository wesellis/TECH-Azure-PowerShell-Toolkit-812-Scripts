// Azure PowerShell Toolkit - Main Bicep Template
// Creates comprehensive Azure environment for toolkit demonstration

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Unique suffix for resource naming')
param uniqueSuffix string = uniqueString(resourceGroup().id)

@description('Administrator username for VMs')
param adminUsername string = 'azureadmin'

@description('Administrator password for VMs')
@secure()
param adminPassword string

@description('VM size for compute resources')
param vmSize string = 'Standard_B2s'

@description('Deploy advanced features (AKS, App Service, etc.)')
param deployAdvanced bool = false

// Variables
var resourcePrefix = 'toolkit-${environment}-${uniqueSuffix}'
var tags = {
  Environment: environment
  Project: 'Azure-PowerShell-Toolkit'
  ManagedBy: 'Bicep-Template'
  CreatedDate: utcNow('yyyy-MM-dd')
}

// Network resources
module network 'modules/network.bicep' = {
  name: 'network-deployment'
  params: {
    resourcePrefix: resourcePrefix
    location: location
    tags: tags
    environment: environment
  }
}

// Storage resources
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    resourcePrefix: resourcePrefix
    location: location
    tags: tags
    environment: environment
  }
}

// Key Vault resources
module keyVault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    resourcePrefix: resourcePrefix
    location: location
    tags: tags
    environment: environment
  }
}

// Compute resources
module compute 'modules/compute.bicep' = {
  name: 'compute-deployment'
  params: {
    resourcePrefix: resourcePrefix
    location: location
    tags: tags
    environment: environment
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    subnetId: network.outputs.subnetId
  }
  dependsOn: [
    network
  ]
}

// Advanced resources (conditional)
module advanced 'modules/advanced.bicep' = if (deployAdvanced) {
  name: 'advanced-deployment'
  params: {
    resourcePrefix: resourcePrefix
    location: location
    tags: tags
    environment: environment
    subnetId: network.outputs.subnetId
  }
  dependsOn: [
    network
  ]
}

// Monitoring resources
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    resourcePrefix: resourcePrefix
    location: location
    tags: tags
    environment: environment
  }
}

// Outputs
output resourceGroupName string = resourceGroup().name
output vnetId string = network.outputs.vnetId
output storageAccountName string = storage.outputs.storageAccountName
output keyVaultName string = keyVault.outputs.keyVaultName
output vmName string = compute.outputs.vmName
output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId