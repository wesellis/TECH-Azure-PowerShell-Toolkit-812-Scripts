@description('Key Vault name (must be globally unique)')
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

@description('Object ID of user/group to grant access (required if RBAC is disabled)')
param administratorObjectId string = ''

@description('Enable RBAC authorization (recommended)')
param enableRbacAuthorization bool = true

@description('Enable soft delete')
param enableSoftDelete bool = true

@description('Soft delete retention days')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = (environment == 'prod') ? 90 : 30

@description('Enable purge protection (cannot be disabled once enabled)')
param enablePurgeProtection bool = (environment == 'prod')

@description('Enable vault for disk encryption')
param enabledForDiskEncryption bool = true

@description('Enable vault for template deployment')
param enabledForTemplateDeployment bool = true

@description('Enable vault for VM deployment')
param enabledForDeployment bool = false

@description('Network access default action')
@allowed(['Allow', 'Deny'])
param networkDefaultAction string = (environment == 'prod') ? 'Deny' : 'Allow'

@description('IP rules for Key Vault access')
param ipRules array = []

@description('Virtual network rules for Key Vault access')
param virtualNetworkRules array = []

@description('Enable private endpoint')
param enablePrivateEndpoint bool = (environment == 'prod')

@description('Subnet ID for private endpoint')
param privateEndpointSubnetId string = ''

@description('Log Analytics workspace ID for diagnostics')
param logAnalyticsWorkspaceId string = ''

@description('Enable Key Vault notifications')
param enableNotifications bool = (environment == 'prod')

@description('Event Grid topic endpoint for notifications')
param eventGridTopicEndpoint string = ''

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Security'
  DeployedBy: 'Bicep'
}

// Variables
var keyVaultSku = (environment == 'prod') ? 'premium' : 'standard'
var isProd = environment == 'prod'

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
    enabledForDeployment: enabledForDeployment
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: (networkDefaultAction == 'Allow') ? 'Enabled' : 'Disabled'
    networkAcls: {
      defaultAction: networkDefaultAction
      bypass: 'AzureServices'
      ipRules: [for rule in ipRules: {
        value: rule
      }]
      virtualNetworkRules: [for rule in virtualNetworkRules: {
        id: rule
        ignoreMissingVnetServiceEndpoint: false
      }]
    }
    accessPolicies: !enableRbacAuthorization && !empty(administratorObjectId) ? [
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

// Private endpoint (for production)
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoint && !empty(privateEndpointSubnetId)) {
  name: '${keyVaultName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
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

// Private DNS Zone for private endpoint
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint && !empty(privateEndpointSubnetId)) {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (enablePrivateEndpoint && !empty(privateEndpointSubnetId)) {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-vaultcore-azure-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// Diagnostic settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${keyVaultName}-diagnostics'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
    ]
  }
}

// Event Grid System Topic for notifications
resource eventGridSystemTopic 'Microsoft.EventGrid/systemTopics@2023-12-15-preview' = if (enableNotifications && !empty(eventGridTopicEndpoint)) {
  name: '${keyVaultName}-events'
  location: location
  tags: tags
  properties: {
    source: keyVault.id
    topicType: 'Microsoft.KeyVault.vaults'
  }
}

// Sample secrets (for demonstration - should be managed through secure processes)
resource sampleSecrets 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for secret in [
  {
    name: 'database-connection-string'
    value: 'Server=tcp:myserver.database.windows.net,1433;Database=mydb;Encrypt=True;'
    contentType: 'connection-string'
    expiresOn: dateTimeAdd(utcNow(), 'P1Y')
  }
  {
    name: 'api-key'
    value: 'sample-api-key-value-${uniqueString(resourceGroup().id)}'
    contentType: 'api-key'
    expiresOn: dateTimeAdd(utcNow(), 'P6M')
  }
  {
    name: 'storage-account-key'
    value: 'sample-storage-key-${uniqueString(resourceGroup().id)}'
    contentType: 'storage-key'
    expiresOn: dateTimeAdd(utcNow(), 'P3M')
  }
]: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
    attributes: {
      enabled: true
      exp: dateTimeToEpoch(secret.expiresOn)
    }
    contentType: secret.contentType
  }
}]

// Encryption keys
resource encryptionKeys 'Microsoft.KeyVault/vaults/keys@2023-07-01' = [for key in [
  {
    name: 'disk-encryption-key'
    keySize: 2048
    keyOps: ['encrypt', 'decrypt', 'sign', 'verify', 'wrapKey', 'unwrapKey']
  }
  {
    name: 'data-encryption-key'
    keySize: 4096
    keyOps: ['encrypt', 'decrypt', 'wrapKey', 'unwrapKey']
  }
]: {
  name: key.name
  parent: keyVault
  properties: {
    keySize: key.keySize
    kty: 'RSA'
    attributes: {
      enabled: true
      exportable: false
    }
    keyOps: key.keyOps
    rotationPolicy: isProd ? {
      attributes: {
        expiryTime: 'P2Y'
      }
      lifetimeActions: [
        {
          trigger: {
            timeBeforeExpiry: 'P30D'
          }
          action: {
            type: 'Rotate'
          }
        }
        {
          trigger: {
            timeAfterCreate: 'P90D'
          }
          action: {
            type: 'Notify'
          }
        }
      ]
    } : null
  }
}]

// Certificates (self-signed for demonstration)
resource certificates 'Microsoft.KeyVault/vaults/certificates@2023-07-01' = [for cert in [
  {
    name: 'ssl-certificate'
    subject: 'CN=example.com'
    sans: ['example.com', 'www.example.com']
    validityMonths: 12
  }
]: {
  name: cert.name
  parent: keyVault
  properties: {
    certificatePolicy: {
      keyProperties: {
        exportable: true
        keySize: 2048
        keyType: 'RSA'
        reuseKey: false
      }
      secretProperties: {
        contentType: 'application/x-pkcs12'
      }
      x509CertificateProperties: {
        subject: cert.subject
        subjectAlternativeNames: {
          dnsNames: cert.sans
        }
        keyUsage: [
          'cRLSign'
          'dataEncipherment'
          'digitalSignature'
          'keyEncipherment'
          'keyAgreement'
          'keyCertSign'
        ]
        ekus: [
          '1.3.6.1.5.5.7.3.1'
          '1.3.6.1.5.5.7.3.2'
        ]
        validityInMonths: cert.validityMonths
      }
      issuerParameters: {
        name: 'Self'
        certificateType: 'Self-signed'
      }
      attributes: {
        enabled: true
      }
    }
  }
}]

// Key Vault Access Policy for deployment service principal (if RBAC is disabled)
resource deploymentAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = if (!enableRbacAuthorization && !empty(administratorObjectId)) {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: administratorObjectId
        permissions: {
          keys: [
            'get'
            'list'
            'create'
            'update'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
          certificates: [
            'get'
            'list'
            'create'
            'update'
            'delete'
            'managecontacts'
            'manageissuers'
            'getissuers'
            'listissuers'
            'setissuers'
            'deleteissuers'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
        }
      }
    ]
  }
}

// Outputs
@description('Key Vault resource ID')
output keyVaultId string = keyVault.id

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault tenant ID')
output tenantId string = keyVault.properties.tenantId

@description('Private endpoint ID (if created)')
output privateEndpointId string = (enablePrivateEndpoint && !empty(privateEndpointSubnetId)) ? privateEndpoint.id : ''

@description('Private DNS zone ID (if created)')
output privateDnsZoneId string = (enablePrivateEndpoint && !empty(privateEndpointSubnetId)) ? privateDnsZone.id : ''

@description('Sample secret references')
output secretReferences object = {
  databaseConnectionString: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=database-connection-string)'
  apiKey: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=api-key)'
  storageAccountKey: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=storage-account-key)'
}

@description('Encryption key URIs')
output encryptionKeyUris object = {
  diskEncryptionKey: encryptionKeys[0].properties.keyUri
  dataEncryptionKey: encryptionKeys[1].properties.keyUri
}

@description('Certificate information')
output certificates array = [for (cert, i) in certificates: {
  name: cert.name
  thumbprint: cert.properties.thumbprint
  secretId: cert.properties.secretId
}]

@description('Key Vault configuration summary')
output configurationSummary object = {
  sku: keyVaultSku
  softDeleteEnabled: enableSoftDelete
  purgeProtectionEnabled: enablePurgeProtection
  rbacEnabled: enableRbacAuthorization
  privateEndpointEnabled: enablePrivateEndpoint
  networkDefaultAction: networkDefaultAction
  diagnosticsEnabled: !empty(logAnalyticsWorkspaceId)
  notificationsEnabled: enableNotifications
}
