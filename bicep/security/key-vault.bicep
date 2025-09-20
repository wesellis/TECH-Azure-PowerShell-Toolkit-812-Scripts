@description('Key Vault name')
@minLength(3)
@maxLength(24)
param keyVaultName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location for resources')
param location string = resourceGroup().location

@description('Azure AD tenant ID')
param tenantId string = tenant().tenantId

@description('Object ID of user/group to grant access')
param administratorObjectId string

@description('Enable soft delete')
param enableSoftDelete bool = true

@description('Soft delete retention days')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = environment == 'prod' ? 90 : 30

@description('Enable purge protection')
param enablePurgeProtection bool = environment == 'prod'

@description('Enable RBAC authorization')
param enableRbacAuthorization bool = true

@description('Network access rules')
@allowed(['Allow', 'Deny'])
param networkAcls string = environment == 'prod' ? 'Deny' : 'Allow'

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Security'
}

// Variables
var keyVaultSku = environment == 'prod' ? 'premium' : 'standard'

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: keyVaultSku
    }
    tenantId: tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    networkAcls: {
      defaultAction: networkAcls
      bypass: 'AzureServices'
    }
    accessPolicies: !enableRbacAuthorization ? [
      {
        tenantId: tenantId
        objectId: administratorObjectId
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
        }
      }
    ] : []
  }
}

// Diagnostic settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${keyVaultName}-diagnostics'
  scope: keyVault
  properties: {
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: environment == 'prod' ? 90 : 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: environment == 'prod' ? 90 : 30
        }
      }
    ]
    workspaceId: null // Will be populated if Log Analytics workspace is provided
  }
}

// Private endpoint (for production)
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (environment == 'prod') {
  name: '${keyVaultName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: null // Should be provided as parameter in real deployment
    }
    privateLinkServiceConnections: [
      {
        name: '${keyVaultName}-plsc'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Sample secrets (for demo purposes)
resource sampleSecret1 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'database-connection-string'
  parent: keyVault
  properties: {
    value: 'Server=tcp:myserver.database.windows.net,1433;Database=mydb;'
    attributes: {
      enabled: true
    }
    contentType: 'connection-string'
  }
}

resource sampleSecret2 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'api-key'
  parent: keyVault
  properties: {
    value: 'sample-api-key-value'
    attributes: {
      enabled: true
      exp: dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1Y'))
    }
    contentType: 'api-key'
  }
}

// Key for encryption
resource encryptionKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  name: 'disk-encryption-key'
  parent: keyVault
  properties: {
    keySize: 2048
    kty: 'RSA'
    attributes: {
      enabled: true
    }
    keyOps: [
      'encrypt'
      'decrypt'
      'sign'
      'verify'
      'wrapKey'
      'unwrapKey'
    ]
  }
}

// Outputs
@description('Key Vault resource ID')
output keyVaultId string = keyVault.id

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Private endpoint ID (if created)')
output privateEndpointId string = environment == 'prod' ? privateEndpoint.id : ''

@description('Encryption key URI')
output encryptionKeyUri string = encryptionKey.properties.keyUri