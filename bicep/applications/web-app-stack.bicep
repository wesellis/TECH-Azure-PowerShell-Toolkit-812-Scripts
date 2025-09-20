@description('Application name prefix (used for resource naming)')
@minLength(2)
@maxLength(10)
param appName string

@description('Environment designation')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Administrator object ID for Key Vault access')
param administratorObjectId string

@description('Database administrator username')
@minLength(4)
param dbAdminUsername string

@description('Database administrator password')
@secure()
@minLength(12)
param dbAdminPassword string

@description('Application Insights workspace ID (optional)')
param logAnalyticsWorkspaceId string = ''

@description('Enable Application Gateway for production workloads')
param enableApplicationGateway bool = (environment == 'prod')

@description('Enable private endpoints for enhanced security')
param enablePrivateEndpoints bool = (environment == 'prod')

@description('Custom domain name for Application Gateway (optional)')
param customDomainName string = ''

@description('Resource tags')
param tags object = {
  Environment: environment
  Application: appName
  Deployment: 'Bicep'
  LastDeployed: utcNow('yyyy-MM-dd')
}

// Variables for consistent naming and configuration
var resourcePrefix = '${appName}-${environment}'
var isProd = environment == 'prod'
var isNonProd = environment != 'prod'

// Standardized SKU configurations
var appServicePlanSku = {
  dev: { name: 'B2', tier: 'Basic', capacity: 1 }
  test: { name: 'S1', tier: 'Standard', capacity: 1 }
  prod: { name: 'P2v3', tier: 'PremiumV3', capacity: 2 }
}

var sqlDatabaseSku = {
  dev: { name: 'Basic', tier: 'Basic', capacity: 5 }
  test: { name: 'S2', tier: 'Standard', capacity: 50 }
  prod: { name: 'GP_Gen5_4', tier: 'GeneralPurpose', family: 'Gen5', capacity: 4 }
}

var storageAccountSku = {
  dev: 'Standard_LRS'
  test: 'Standard_ZRS'
  prod: 'Standard_GRS'
}

// App Service Plan with environment-appropriate sizing
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${resourcePrefix}-asp'
  location: location
  tags: tags
  sku: appServicePlanSku[environment]
  properties: {
    reserved: false // Windows hosting
    zoneRedundant: isProd
  }
}

// Web App with comprehensive security configuration
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: '${resourcePrefix}-web'
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      netFrameworkVersion: 'v8.0'
      use32BitWorkerProcess: false
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      http20Enabled: true
      httpLoggingEnabled: true
      detailedErrorLoggingEnabled: isNonProd
      healthCheckPath: '/health'
      publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
      ipSecurityRestrictions: isNonProd ? [] : [
        {
          action: 'Allow'
          description: 'Allow Application Gateway'
          ipAddress: '${virtualNetwork.properties.subnets[2].properties.addressPrefix}'
          priority: 100
        }
        {
          action: 'Deny'
          description: 'Deny all other traffic'
          ipAddress: '0.0.0.0/0'
          priority: 200
        }
      ]
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment
        }
        {
          name: 'ASPNETCORE_FORWARDEDHEADERS_ENABLED'
          value: 'true'
        }
        {
          name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
          value: isProd ? '30' : '7'
        }
      ]
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=database-connection-string)'
          type: 'SQLAzure'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// VNet integration for App Service (production)
resource appServiceVnetIntegration 'Microsoft.Web/sites/networkConfig@2023-01-01' = if (isProd) {
  name: 'virtualNetwork'
  parent: webApp
  properties: {
    subnetResourceId: virtualNetwork.properties.subnets[0].id
    swiftSupported: true
  }
}

// Application Insights with proper workspace integration
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourcePrefix}-insights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: isProd ? 'Disabled' : 'Enabled'
    DisableIpMasking: isNonProd
  }
}

// Log Analytics Workspace (created if not provided)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (empty(logAnalyticsWorkspaceId)) {
  name: '${resourcePrefix}-law'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: isProd ? 90 : 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: isProd ? 10 : 1
    }
  }
}

// Key Vault with enhanced security
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${resourcePrefix}-kv-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: isProd ? 'premium' : 'standard'
    }
    tenantId: tenant().tenantId
    enabledForTemplateDeployment: false
    enabledForDiskEncryption: false
    enabledForDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: isProd ? 90 : 30
    enablePurgeProtection: isProd
    enableRbacAuthorization: true
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    networkAcls: {
      defaultAction: isProd ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
      virtualNetworkRules: isProd ? [
        {
          id: virtualNetwork.properties.subnets[1].id
          ignoreMissingVnetServiceEndpoint: false
        }
      ] : []
    }
  }
}

// SQL Server with enhanced security
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: '${resourcePrefix}-sql-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    administratorLogin: dbAdminUsername
    administratorLoginPassword: dbAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// SQL Database with environment-appropriate configuration
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: '${appName}db'
  parent: sqlServer
  location: location
  tags: tags
  sku: sqlDatabaseSku[environment]
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: isProd ? 1099511627776 : 268435456000 // 1TB for prod, 250GB for others
    zoneRedundant: isProd
    readScale: isProd ? 'Enabled' : 'Disabled'
    requestedBackupStorageRedundancy: isProd ? 'GeoZone' : 'Local'
    isLedgerOn: false
  }
}

// SQL Server Advanced Threat Protection
resource sqlServerSecurityAlert 'Microsoft.Sql/servers/securityAlertPolicies@2023-05-01-preview' = {
  name: 'Default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    emailAddresses: []
    emailAccountAdmins: true
    retentionDays: isProd ? 90 : 30
  }
}

// SQL Database Auditing
resource sqlDatabaseAuditing 'Microsoft.Sql/servers/auditingSettings@2023-05-01-preview' = {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    storageEndpoint: storageAccount.properties.primaryEndpoints.blob
    storageAccountAccessKey: storageAccount.listKeys().keys[0].value
    retentionDays: isProd ? 90 : 30
    isAzureMonitorTargetEnabled: true
  }
}

// SQL Firewall rule (only for non-production with private endpoints disabled)
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = if (!enablePrivateEndpoints) {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Storage Account with enhanced security
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${replace(resourcePrefix, '-', '')}stor${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: storageAccountSku[environment]
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: !isProd
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    defaultToOAuthAuthentication: isProd
    publicNetworkAccess: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    networkAcls: {
      defaultAction: isProd ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
      virtualNetworkRules: isProd ? [
        {
          id: virtualNetwork.properties.subnets[1].id
          action: 'Allow'
        }
      ] : []
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
      }
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: isProd
    }
  }
}

// Blob container for application data
resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storageAccount.name}/default/app-data'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Application data storage'
    }
  }
}

// Virtual Network (enhanced for production)
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = if (isProd) {
  name: '${resourcePrefix}-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'app-service-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.KeyVault'
            }
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.Sql'
            }
          ]
          delegations: [
            {
              name: 'app-service-delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'private-endpoint-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'application-gateway-subnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

// Network Security Group for App Service subnet
resource appServiceNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = if (isProd) {
  name: '${resourcePrefix}-app-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPSInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '10.0.3.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Private Endpoints (production only)
resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoints) {
  name: '${resourcePrefix}-kv-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: 'keyVaultConnection'
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

resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoints) {
  name: '${resourcePrefix}-sql-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: 'sqlConnection'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoints) {
  name: '${resourcePrefix}-stor-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: 'storageConnection'
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

// Application Gateway with WAF (production only)
resource applicationGatewayPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableApplicationGateway) {
  name: '${resourcePrefix}-agw-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: !empty(customDomainName) ? customDomainName : '${resourcePrefix}-app'
    }
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-05-01' = if (enableApplicationGateway) {
  name: '${resourcePrefix}-agw'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 10
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'application-gateway-subnet')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: applicationGatewayPublicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appServiceBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: webApp.properties.defaultHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appServiceBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', '${resourcePrefix}-agw', 'appServiceHealthProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', '${resourcePrefix}-agw', 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', '${resourcePrefix}-agw', 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          priority: 1
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', '${resourcePrefix}-agw', 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', '${resourcePrefix}-agw', 'appServiceBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', '${resourcePrefix}-agw', 'appServiceBackendHttpSettings')
          }
        }
      }
    ]
    probes: [
      {
        name: 'appServiceHealthProbe'
        properties: {
          protocol: 'Https'
          path: '/health'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
      disabledRuleGroups: []
      exclusions: []
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
  }
}

// Key Vault secrets with proper security
resource databaseConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'database-connection-string'
  parent: keyVault
  properties: {
    value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    attributes: {
      enabled: true
      exp: dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1Y')) // Expire in 1 year
    }
    contentType: 'Connection String'
  }
}

resource storageConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'storage-connection-string'
  parent: keyVault
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    attributes: {
      enabled: true
      exp: dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1Y'))
    }
    contentType: 'Connection String'
  }
}

// RBAC assignments for managed identities
resource webAppKeyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, webApp.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource webAppStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, webApp.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Diagnostic settings for monitoring
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'webapp-diagnostics'
  scope: webApp
  properties: {
    workspaceId: !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 30 : 7
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 30 : 7
        }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 30 : 7
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 30 : 7
        }
      }
    ]
  }
}

resource sqlDatabaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'sqldb-diagnostics'
  scope: sqlDatabase
  properties: {
    workspaceId: !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : logAnalyticsWorkspace.id
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
    ]
  }
}

// Outputs with comprehensive information
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output webAppPrincipalId string = webApp.identity.principalId

output applicationGatewayUrl string = enableApplicationGateway ? 'https://${applicationGatewayPublicIP.properties.dnsSettings.fqdn}' : 'Not deployed'
output applicationGatewayPublicIP string = enableApplicationGateway ? applicationGatewayPublicIP.properties.ipAddress : 'Not deployed'

output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output sqlServerName string = sqlServer.name

output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name

output storageAccountName string = storageAccount.name
output storageAccountPrimaryEndpoint string = storageAccount.properties.primaryEndpoints.blob

output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString

output logAnalyticsWorkspaceId string = !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : logAnalyticsWorkspace.id

output virtualNetworkId string = isProd ? virtualNetwork.id : 'Not deployed'
output privateEndpointsEnabled bool = enablePrivateEndpoints
