@description('Storage account name (must be globally unique)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location for resources')
param location string = resourceGroup().location

@description('Performance tier')
@allowed(['Standard', 'Premium'])
param performanceTier string = environment == 'prod' ? 'Standard' : 'Standard'

@description('Replication type')
@allowed(['LRS', 'GRS', 'RAGRS', 'ZRS', 'GZRS', 'RAGZRS'])
param replicationType string = environment == 'prod' ? 'GRS' : 'LRS'

@description('Access tier for blob storage')
@allowed(['Hot', 'Cool'])
param accessTier string = 'Hot'

@description('Enable hierarchical namespace (Data Lake)')
param enableHierarchicalNamespace bool = false

@description('Enable blob public access')
param allowBlobPublicAccess bool = false

@description('Enable shared key access')
param allowSharedKeyAccess bool = environment != 'prod'

@description('Network access')
@allowed(['Allow', 'Deny'])
param defaultNetworkAccess string = environment == 'prod' ? 'Deny' : 'Allow'

@description('Enable blob versioning')
param enableBlobVersioning bool = environment == 'prod'

@description('Enable blob change feed')
param enableChangeFeed bool = environment == 'prod'

@description('Enable blob soft delete')
param enableBlobSoftDelete bool = true

@description('Blob soft delete retention days')
@minValue(1)
@maxValue(365)
param blobSoftDeleteRetentionDays int = environment == 'prod' ? 30 : 7

@description('Enable container soft delete')
param enableContainerSoftDelete bool = true

@description('Container soft delete retention days')
@minValue(1)
@maxValue(365)
param containerSoftDeleteRetentionDays int = environment == 'prod' ? 30 : 7

@description('Enable point-in-time restore')
param enablePointInTimeRestore bool = environment == 'prod'

@description('Point-in-time restore retention days')
@minValue(1)
@maxValue(365)
param pointInTimeRestoreRetentionDays int = 7

@description('Containers to create')
param containers array = [
  {
    name: 'app-data'
    publicAccess: 'None'
  }
  {
    name: 'backups'
    publicAccess: 'None'
  }
  {
    name: 'logs'
    publicAccess: 'None'
  }
]

@description('File shares to create')
param fileShares array = [
  {
    name: 'app-files'
    quota: 1024
    accessTier: 'Hot'
  }
]

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Storage'
  DeployedBy: 'Bicep'
}

// Variables
var storageAccountSku = '${performanceTier}_${replicationType}'
var isProd = environment == 'prod'

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageAccountSku
  }
  kind: enableHierarchicalNamespace ? 'StorageV2' : 'StorageV2'
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowSharedKeyAccess: allowSharedKeyAccess
    allowCrossTenantReplication: false
    defaultToOAuthAuthentication: isProd
    isHnsEnabled: enableHierarchicalNamespace
    isSftpEnabled: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: defaultNetworkAccess == 'Allow' ? 'Enabled' : 'Disabled'
    networkAcls: {
      defaultAction: defaultNetworkAccess
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
    }
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: isProd
    }
    largeFileSharesState: 'Enabled'
  }
}

// Blob Service Configuration
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    deleteRetentionPolicy: {
      enabled: enableBlobSoftDelete
      days: blobSoftDeleteRetentionDays
    }
    containerDeleteRetentionPolicy: {
      enabled: enableContainerSoftDelete
      days: containerSoftDeleteRetentionDays
    }
    changeFeed: {
      enabled: enableChangeFeed
      retentionInDays: enableChangeFeed ? 30 : null
    }
    versioning: {
      enabled: enableBlobVersioning
    }
    restorePolicy: enablePointInTimeRestore ? {
      enabled: true
      days: pointInTimeRestoreRetentionDays
    } : {
      enabled: false
    }
    cors: {
      corsRules: []
    }
  }
}

// File Service Configuration
resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: isProd ? 30 : 7
    }
    cors: {
      corsRules: []
    }
  }
}

// Queue Service Configuration
resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: []
    }
  }
}

// Table Service Configuration
resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    cors: {
      corsRules: []
    }
  }
}

// Blob Containers
resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [for container in containers: {
  name: container.name
  parent: blobServices
  properties: {
    publicAccess: container.publicAccess
    metadata: {
      purpose: 'Application storage'
      environment: environment
    }
  }
}]

// File Shares
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = [for share in fileShares: {
  name: share.name
  parent: fileServices
  properties: {
    shareQuota: share.quota
    accessTier: share.accessTier
    enabledProtocols: 'SMB'
    metadata: {
      purpose: 'Application file storage'
      environment: environment
    }
  }
}]

// Management Policy for lifecycle management
resource managementPolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = if (isProd) {
  name: 'default'
  parent: storageAccount
  properties: {
    policy: {
      rules: [
        {
          name: 'MoveToIA'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: [
                'logs/'
              ]
            }
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 30
                }
                tierToArchive: {
                  daysAfterModificationGreaterThan: 90
                }
                delete: {
                  daysAfterModificationGreaterThan: 365
                }
              }
              version: {
                delete: {
                  daysAfterCreationGreaterThan: 30
                }
              }
            }
          }
        }
        {
          name: 'DeleteOldBackups'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [
                'blockBlob'
              ]
              prefixMatch: [
                'backups/'
              ]
            }
            actions: {
              baseBlob: {
                delete: {
                  daysAfterModificationGreaterThan: 90
                }
              }
            }
          }
        }
      ]
    }
  }
}

// Private Endpoint for production
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (isProd && defaultNetworkAccess == 'Deny') {
  name: '${storageAccountName}-blob-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: null // Should be provided as parameter in real deployment
    }
    privateLinkServiceConnections: [
      {
        name: 'blob-connection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-diagnostics'
  scope: storageAccount
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'Capacity'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
    ]
    workspaceId: null // Should be provided as parameter in real deployment
  }
}

// Blob Service Diagnostic Settings
resource blobDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-blob-diagnostics'
  scope: blobServices
  properties: {
    logs: [
      {
        category: 'StorageRead'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'StorageWrite'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'StorageDelete'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
    ]
    workspaceId: null // Should be provided as parameter in real deployment
  }
}

// Outputs
@description('Storage account resource ID')
output storageAccountId string = storageAccount.id

@description('Storage account name')
output storageAccountName string = storageAccount.name

@description('Primary endpoints')
output primaryEndpoints object = storageAccount.properties.primaryEndpoints

@description('Primary blob endpoint')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Primary file endpoint')
output primaryFileEndpoint string = storageAccount.properties.primaryEndpoints.file

@description('Primary queue endpoint')
output primaryQueueEndpoint string = storageAccount.properties.primaryEndpoints.queue

@description('Primary table endpoint')
output primaryTableEndpoint string = storageAccount.properties.primaryEndpoints.table

@description('Storage account keys (use with caution)')
output storageAccountKeys array = storageAccount.listKeys().keys

@description('Connection string template')
output connectionStringTemplate string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey={account_key};EndpointSuffix=${environment().suffixes.storage}'

@description('Container information')
output containers array = [for (container, i) in containers: {
  name: blobContainers[i].name
  url: '${storageAccount.properties.primaryEndpoints.blob}${container.name}'
}]

@description('File share information')
output fileShares array = [for (share, i) in fileShares: {
  name: fileShare[i].name
  url: '${storageAccount.properties.primaryEndpoints.file}${share.name}'
}]

@description('Private endpoint ID (if created)')
output privateEndpointId string = (isProd && defaultNetworkAccess == 'Deny') ? privateEndpoint.id : ''
