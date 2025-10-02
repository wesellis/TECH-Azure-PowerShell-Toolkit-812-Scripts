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

@description('Application Insights workspace ID (optional - will create if empty)')
param logAnalyticsWorkspaceId string = ''

@description('Enable Application Gateway for production workloads')
param enableApplicationGateway bool = (environment == 'prod')

@description('Enable private endpoints for enhanced security')
param enablePrivateEndpoints bool = (environment == 'prod')

@description('Enable backup for production workloads')
param enableBackup bool = (environment == 'prod')

@description('Custom domain name for Application Gateway (optional)')
param customDomainName string = ''

@description('Admin email for alerts and notifications')
param adminEmail string = 'admin@company.com'

@description('Enable monitoring and alerting')
param enableMonitoring bool = true

@description('Resource tags')
param tags object = {
  Environment: environment
  Application: appName
  DeployedBy: 'Bicep'
  LastDeployed: utcNow('yyyy-MM-dd')
}

// Environment-specific configurations
var environmentConfig = {
  dev: {
    appServicePlan: { name: 'B2', tier: 'Basic', capacity: 1 }
    sqlDatabase: { tier: 'Basic', compute: 'Basic', maxSizeBytes: 2147483648 }
    storageAccount: { sku: 'Standard_LRS' }
    retentionDays: 7
    dailyQuotaGb: 1
    backupRetentionDays: 7
    enableZoneRedundancy: false
    enableReadScale: false
  }
  test: {
    appServicePlan: { name: 'S1', tier: 'Standard', capacity: 1 }
    sqlDatabase: { tier: 'Standard', compute: 'S2', maxSizeBytes: 268435456000 }
    storageAccount: { sku: 'Standard_ZRS' }
    retentionDays: 30
    dailyQuotaGb: 5
    backupRetentionDays: 14
    enableZoneRedundancy: false
    enableReadScale: false
  }
  prod: {
    appServicePlan: { name: 'P2v3', tier: 'PremiumV3', capacity: 2 }
    sqlDatabase: { tier: 'GeneralPurpose', compute: 'GP_Gen5_4', maxSizeBytes: 1099511627776 }
    storageAccount: { sku: 'Standard_GRS' }
    retentionDays: 90
    dailyQuotaGb: 20
    backupRetentionDays: 35
    enableZoneRedundancy: true
    enableReadScale: true
  }
}

var config = environmentConfig[environment]
var resourcePrefix = '${appName}-${environment}'
var isProd = environment == 'prod'
var isNonProd = environment != 'prod'

// Virtual Network (for production with private endpoints)
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = if (enablePrivateEndpoints) {
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
            { service: 'Microsoft.KeyVault' }
            { service: 'Microsoft.Storage' }
            { service: 'Microsoft.Sql' }
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

// Log Analytics Workspace (created if not provided)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (empty(logAnalyticsWorkspaceId)) {
  name: '${resourcePrefix}-law'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: config.retentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: config.dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
  }
}

var workspaceId = !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : logAnalyticsWorkspace.id

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${resourcePrefix}-insights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: enablePrivateEndpoints ? 'Disabled' : 'Enabled'
    DisableIpMasking: isNonProd
  }
}

// Key Vault
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
      defaultAction: enablePrivateEndpoints ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
      virtualNetworkRules: enablePrivateEndpoints ? [
        {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'app-service-subnet')
          ignoreMissingVnetServiceEndpoint: false
        }
      ] : []
    }
  }
}

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${replace(resourcePrefix, '-', '')}stor${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: config.storageAccount.sku
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
      defaultAction: enablePrivateEndpoints ? 'Deny' : 'Allow'
      bypass: 'AzureServices'
      virtualNetworkRules: enablePrivateEndpoints ? [
        {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'app-service-subnet')
          action: 'Allow'
        }
      ] : []
    }
    encryption: {
      services: {
        blob: { enabled: true, keyType: 'Account' }
        file: { enabled: true, keyType: 'Account' }
      }
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: isProd
    }
  }
}

// Blob containers
resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: isProd ? 30 : 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: isProd ? 30 : 7
    }
  }
}

resource appDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'app-data'
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}

resource backupsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'backups'
  parent: blobServices
  properties: {
    publicAccess: 'None'
  }
}

// SQL Server
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

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: '${appName}db'
  parent: sqlServer
  location: location
  tags: tags
  sku: {
    name: config.sqlDatabase.compute
    tier: config.sqlDatabase.tier
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: config.sqlDatabase.maxSizeBytes
    zoneRedundant: config.enableZoneRedundancy
    readScale: config.enableReadScale ? 'Enabled' : 'Disabled'
    requestedBackupStorageRedundancy: isProd ? 'GeoZone' : 'Local'
    isLedgerOn: false
  }
}

// SQL Server configurations
resource sqlFirewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = if (!enablePrivateEndpoints) {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlAuditing 'Microsoft.Sql/servers/auditingSettings@2023-05-01-preview' = {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    storageEndpoint: storageAccount.properties.primaryEndpoints.blob
    storageAccountAccessKey: storageAccount.listKeys().keys[0].value
    retentionDays: config.retentionDays
    isAzureMonitorTargetEnabled: true
  }
}

resource sqlThreatProtection 'Microsoft.Sql/servers/securityAlertPolicies@2023-05-01-preview' = if (isProd) {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    emailAddresses: [adminEmail]
    emailAccountAdmins: true
    retentionDays: 30
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${resourcePrefix}-asp'
  location: location
  tags: tags
  sku: config.appServicePlan
  properties: {
    reserved: false
    zoneRedundant: config.enableZoneRedundancy
  }
}

// Web App
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
      ipSecurityRestrictions: enablePrivateEndpoints ? [
        {
          action: 'Allow'
          description: 'Allow Application Gateway'
          ipAddress: '10.0.3.0/24'
          priority: 100
        }
        {
          action: 'Deny'
          description: 'Deny all other traffic'
          ipAddress: '0.0.0.0/0'
          priority: 200
        }
      ] : []
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
          value: string(config.retentionDays)
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

// VNet Integration for App Service
resource appServiceVnetIntegration 'Microsoft.Web/sites/networkConfig@2023-01-01' = if (enablePrivateEndpoints) {
  name: 'virtualNetwork'
  parent: webApp
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'app-service-subnet')
    swiftSupported: true
  }
}

// Private Endpoints
resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoints) {
  name: '${resourcePrefix}-kv-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'private-endpoint-subnet')
    }
    privateLinkServiceConnections: [
      {
        name: 'keyVaultConnection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: ['vault']
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
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'private-endpoint-subnet')
    }
    privateLinkServiceConnections: [
      {
        name: 'sqlConnection'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: ['sqlServer']
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
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'private-endpoint-subnet')
    }
    privateLinkServiceConnections: [
      {
        name: 'storageConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: ['blob']
        }
      }
    ]
  }
}

// Application Gateway
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
      { name: 'port_80', properties: { port: 80 } }
      { name: 'port_443', properties: { port: 443 } }
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
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
  }
}

// Key Vault Secrets
resource databaseConnectionString 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'database-connection-string'
  parent: keyVault
  properties: {
    value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabase.name};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    attributes: {
      enabled: true
      exp: dateTimeToEpoch(dateTimeAdd(utcNow(), 'P1Y'))
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

// RBAC assignments
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

// Action Group for alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (enableMonitoring) {
  name: '${resourcePrefix}-alerts'
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'alerts'
    enabled: true
    emailReceivers: [
      {
        name: 'admin'
        emailAddress: adminEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// High Response Time Alert
resource highResponseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableMonitoring) {
  name: '${resourcePrefix}-high-response-time'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when average response time exceeds 5 seconds'
    severity: 2
    enabled: true
    scopes: [
      webApp.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighResponseTime'
          metricName: 'AverageResponseTime'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// High CPU Alert
resource highCpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableMonitoring) {
  name: '${resourcePrefix}-high-cpu'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when CPU percentage exceeds 80%'
    severity: 2
    enabled: true
    scopes: [
      webApp.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          metricName: 'CpuPercentage'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Database High DTU Alert
resource databaseHighDtuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (enableMonitoring && config.sqlDatabase.tier != 'GeneralPurpose') {
  name: '${resourcePrefix}-db-high-dtu'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when database DTU percentage exceeds 80%'
    severity: 2
    enabled: true
    scopes: [
      sqlDatabase.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighDTU'
          metricName: 'dtu_consumption_percent'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Diagnostic Settings
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'webapp-diagnostics'
  scope: webApp
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: { enabled: true, days: config.retentionDays }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: { enabled: true, days: config.retentionDays }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: { enabled: true, days: config.retentionDays }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: { enabled: true, days: config.retentionDays }
      }
    ]
  }
}

resource sqlDatabaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'sqldb-diagnostics'
  scope: sqlDatabase
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
        retentionPolicy: { enabled: true, days: config.retentionDays }
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
        retentionPolicy: { enabled: true, days: config.retentionDays }
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
        retentionPolicy: { enabled: true, days: config.retentionDays }
      }
    ]
  }
}

// Outputs
@description('Web App URL')
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'

@description('Web App name')
output webAppName string = webApp.name

@description('Web App principal ID')
output webAppPrincipalId string = webApp.identity.principalId

@description('Application Gateway URL (if deployed)')
output applicationGatewayUrl string = enableApplicationGateway ? 'https://${applicationGatewayPublicIP.properties.dnsSettings.fqdn}' : 'Not deployed'

@description('Application Gateway public IP (if deployed)')
output applicationGatewayPublicIP string = enableApplicationGateway ? applicationGatewayPublicIP.properties.ipAddress : 'Not deployed'

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('SQL Database name')
output sqlDatabaseName string = sqlDatabase.name

@description('SQL Server name')
output sqlServerName string = sqlServer.name

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault name')
output keyVaultName string = keyVault.name

@description('Storage Account name')
output storageAccountName string = storageAccount.name

@description('Storage Account primary blob endpoint')
output storageAccountPrimaryEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Application Insights instrumentation key')
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('Application Insights connection string')
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString

@description('Log Analytics workspace ID')
output logAnalyticsWorkspaceId string = workspaceId

@description('Virtual Network ID (if deployed)')
output virtualNetworkId string = enablePrivateEndpoints ? virtualNetwork.id : 'Not deployed'

@description('Private endpoints enabled')
output privateEndpointsEnabled bool = enablePrivateEndpoints

@description('Application Gateway enabled')
output applicationGatewayEnabled bool = enableApplicationGateway

@description('Monitoring enabled')
output monitoringEnabled bool = enableMonitoring

@description('Deployment summary')
output deploymentSummary object = {
  environment: environment
  appName: appName
  webAppUrl: 'https://${webApp.properties.defaultHostName}'
  applicationGatewayUrl: enableApplicationGateway ? 'https://${applicationGatewayPublicIP.properties.dnsSettings.fqdn}' : 'Not deployed'
  keyVaultName: keyVault.name
  sqlServerName: sqlServer.name
  sqlDatabaseName: sqlDatabase.name
  storageAccountName: storageAccount.name
  privateEndpointsEnabled: enablePrivateEndpoints
  applicationGatewayEnabled: enableApplicationGateway
  monitoringEnabled: enableMonitoring
  resourcesDeployed: {
    webApp: webApp.name
    appServicePlan: appServicePlan.name
    sqlServer: sqlServer.name
    sqlDatabase: sqlDatabase.name
    keyVault: keyVault.name
    storageAccount: storageAccount.name
    applicationInsights: applicationInsights.name
    logAnalyticsWorkspace: empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspace.name : 'Using existing'
    virtualNetwork: enablePrivateEndpoints ? virtualNetwork.name : 'Not deployed'
    applicationGateway: enableApplicationGateway ? applicationGateway.name : 'Not deployed'
  }
}
