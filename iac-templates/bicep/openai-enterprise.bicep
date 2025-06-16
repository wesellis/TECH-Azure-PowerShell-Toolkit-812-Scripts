// Azure OpenAI Service Enterprise Template
// Deploys Azure OpenAI with enterprise security, monitoring, and governance

@description('Name prefix for all resources')
param namePrefix string = 'openai'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment type')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'prod'

@description('Azure OpenAI account name')
param openAiAccountName string = '${namePrefix}-${environment}-${uniqueString(resourceGroup().id)}'

@description('SKU for Azure OpenAI service')
@allowed(['S0'])
param openAiSku string = 'S0'

@description('OpenAI models to deploy')
param modelsTodeploy array = [
  {
    name: 'gpt-35-turbo'
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0613'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'gpt-4'
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
    sku: {
      name: 'Standard'
      capacity: 5
    }
  }
  {
    name: 'text-embedding-ada-002'
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]

@description('Enable private endpoint for secure access')
param enablePrivateEndpoint bool = true

@description('Enable Content Safety filters')
param enableContentSafety bool = true

@description('Enable Customer Managed Keys')
param enableCustomerManagedKeys bool = true

@description('Enable monitoring and diagnostics')
param enableMonitoring bool = true

@description('Enable network restrictions')
param restrictNetworkAccess bool = true

@description('Allowed IP addresses for network access')
param allowedIpAddresses array = []

@description('Virtual Network name for private endpoint')
param vnetName string = '${namePrefix}-vnet-${environment}'

@description('Subnet name for private endpoint')
param subnetName string = 'openai-subnet'

// Variables
var keyVaultName = '${namePrefix}-kv-${uniqueString(resourceGroup().id)}'
var applicationInsightsName = '${namePrefix}-ai-${environment}'
var logAnalyticsName = '${namePrefix}-law-${environment}'
var storageAccountName = '${namePrefix}st${uniqueString(resourceGroup().id)}'
var privateDnsZoneName = 'privatelink.openai.azure.com'
var privateEndpointName = '${openAiAccountName}-pe'

// Common tags
var commonTags = {
  Environment: environment
  Application: 'OpenAI'
  ManagedBy: 'Bicep'
  CreatedDate: utcNow('yyyy-MM-dd')
  CostCenter: 'AI-Innovation'
  DataClassification: 'Confidential'
}

// Virtual Network for private networking
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = if (enablePrivateEndpoint) {
  name: vnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableMonitoring) {
  name: logAnalyticsName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 10
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableMonitoring) {
  name: applicationInsightsName
  location: location
  tags: commonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: enableMonitoring ? logAnalytics.id : null
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Storage Account for audit logs and data
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    supportsHttpsTrafficOnly: true
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
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [for ip in allowedIpAddresses: {
        value: ip
        action: 'Allow'
      }]
    }
  }
}

// Key Vault for secrets and keys management
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: commonTags
  properties: {
    sku: {
      family: 'A'
      name: 'premium'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: false
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    createMode: 'default'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: [for ip in allowedIpAddresses: {
        value: ip
      }]
    }
  }
}

// Customer Managed Key for OpenAI encryption
resource customerManagedKey 'Microsoft.KeyVault/vaults/keys@2023-02-01' = if (enableCustomerManagedKeys) {
  parent: keyVault
  name: 'openai-cmk'
  properties: {
    kty: 'RSA'
    keySize: 2048
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

// Managed Identity for OpenAI service
resource openAiManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${openAiAccountName}-identity'
  location: location
  tags: commonTags
}

// Key Vault access for managed identity
resource keyVaultCryptoAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableCustomerManagedKeys) {
  name: guid(keyVault.id, openAiManagedIdentity.id, 'Key Vault Crypto Service Encryption User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
    principalId: openAiManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Azure OpenAI Service
resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiAccountName
  location: location
  tags: commonTags
  sku: {
    name: openAiSku
  }
  kind: 'OpenAI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${openAiManagedIdentity.id}': {}
    }
  }
  properties: {
    customSubDomainName: openAiAccountName
    publicNetworkAccess: restrictNetworkAccess ? 'Disabled' : 'Enabled'
    networkAcls: restrictNetworkAccess ? {
      defaultAction: 'Deny'
      ipRules: [for ip in allowedIpAddresses: {
        value: ip
      }]
      virtualNetworkRules: enablePrivateEndpoint ? [
        {
          id: vnet.properties.subnets[0].id
          ignoreMissingVnetServiceEndpoint: false
        }
      ] : []
    } : null
    encryption: enableCustomerManagedKeys ? {
      keyVaultProperties: {
        keyName: customerManagedKey.name
        keyVaultUri: keyVault.properties.vaultUri
        identityClientId: openAiManagedIdentity.properties.clientId
      }
      keySource: 'Microsoft.KeyVault'
    } : null
    userOwnedStorage: [
      {
        resourceId: storageAccount.id
        identityClientId: openAiManagedIdentity.properties.clientId
      }
    ]
  }
  dependsOn: [
    keyVaultCryptoAccess
  ]
}

// Deploy OpenAI models
resource openAiDeployments 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for model in modelsToDeploy: {
  parent: openAiAccount
  name: model.name
  properties: {
    model: model.model
    raiPolicyName: enableContentSafety ? 'Microsoft.Default' : null
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  sku: model.sku
}]

// Private DNS Zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: privateDnsZoneName
  location: 'global'
  tags: commonTags
}

// Private DNS Zone VNet Link
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoint) {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = if (enablePrivateEndpoint) {
  name: privateEndpointName
  location: location
  tags: commonTags
  properties: {
    subnet: {
      id: vnet.properties.subnets[0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'openai-connection'
        properties: {
          privateLinkServiceId: openAiAccount.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = if (enablePrivateEndpoint) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'openai-config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

// Storage role assignment for OpenAI
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, openAiManagedIdentity.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: openAiManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Diagnostic Settings
resource openAiDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
  name: 'openai-diagnostics'
  scope: openAiAccount
  properties: {
    workspaceId: logAnalytics.id
    storageAccountId: storageAccount.id
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 365
        }
      }
      {
        category: 'RequestResponse'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'Trace'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Content Safety Configuration (requires additional template for content filtering policies)
resource contentSafetyConfig 'Microsoft.CognitiveServices/accounts/raiPolicies@2023-05-01' = if (enableContentSafety) {
  parent: openAiAccount
  name: 'enterprise-content-policy'
  properties: {
    mode: 'Blocking'
    contentFilters: [
      {
        name: 'hate'
        allowedContentLevel: 'Low'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'hate'
        allowedContentLevel: 'Low'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'sexual'
        allowedContentLevel: 'Low'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'sexual'
        allowedContentLevel: 'Low'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'violence'
        allowedContentLevel: 'Low'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'violence'
        allowedContentLevel: 'Low'
        blocking: true
        enabled: true
        source: 'Completion'
      }
      {
        name: 'selfharm'
        allowedContentLevel: 'Low'
        blocking: true
        enabled: true
        source: 'Prompt'
      }
      {
        name: 'selfharm'
        allowedContentLevel: 'Low'
        blocking: true
        enabled: true
        source: 'Completion'
      }
    ]
  }
}

// Monitor alerts for cost and usage
resource costAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableMonitoring) {
  name: '${openAiAccountName}-cost-alert'
  location: 'global'
  tags: commonTags
  properties: {
    description: 'Alert when OpenAI usage exceeds threshold'
    severity: 2
    enabled: true
    scopes: [
      openAiAccount.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'TokenUsage'
          metricName: 'TokenTransaction'
          operator: 'GreaterThan'
          threshold: 100000
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

// Outputs
output openAiAccountName string = openAiAccount.name
output openAiEndpoint string = openAiAccount.properties.endpoint
output openAiAccountId string = openAiAccount.id
output deployedModels array = [for (model, i) in modelsToDeploy: {
  name: openAiDeployments[i].name
  endpoint: '${openAiAccount.properties.endpoint}openai/deployments/${model.name}'
  model: model.model.name
  version: model.model.version
}]
output privateEndpointFqdn string = enablePrivateEndpoint ? '${openAiAccountName}.privatelink.openai.azure.com' : ''
output keyVaultUri string = keyVault.properties.vaultUri
output storageAccountName string = storageAccount.name
output managedIdentityClientId string = openAiManagedIdentity.properties.clientId
output applicationInsightsConnectionString string = enableMonitoring ? applicationInsights.properties.ConnectionString : ''
output logAnalyticsWorkspaceId string = enableMonitoring ? logAnalytics.properties.customerId : ''
