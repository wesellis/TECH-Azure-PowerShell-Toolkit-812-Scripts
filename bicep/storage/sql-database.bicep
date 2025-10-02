@description('SQL Server name (must be globally unique)')
@minLength(1)
@maxLength(63)
param sqlServerName string

@description('Database name')
@minLength(1)
@maxLength(128)
param databaseName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location for resources')
param location string = resourceGroup().location

@description('SQL Administrator username')
@minLength(1)
param administratorLogin string

@description('SQL Administrator password')
@secure()
@minLength(8)
@maxLength(128)
param administratorLoginPassword string

@description('Enable Azure AD authentication only')
param enableAzureADOnlyAuth bool = false

@description('Azure AD administrator object ID')
param azureADAdminObjectId string = ''

@description('Azure AD administrator principal name')
param azureADAdminPrincipalName string = ''

@description('Enable Advanced Threat Protection')
param enableAdvancedThreatProtection bool = (environment == 'prod')

@description('Enable auditing')
param enableAuditing bool = true

@description('Enable vulnerability assessment')
param enableVulnerabilityAssessment bool = (environment == 'prod')

@description('Enable private endpoint')
param enablePrivateEndpoint bool = (environment == 'prod')

@description('Log Analytics workspace ID for auditing')
param logAnalyticsWorkspaceId string = ''

@description('Storage account ID for auditing and vulnerability assessment')
param storageAccountId string = ''

@description('Email addresses for security alerts')
param securityAlertEmails array = []

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Database'
  DeployedBy: 'Bicep'
}

// Environment-specific configurations
var environmentConfig = {
  dev: {
    serviceTier: 'Basic'
    computeSize: 'Basic'
    maxSizeBytes: 2147483648 // 2GB
    backupRetentionDays: 7
    geoRedundantBackup: false
    zoneRedundant: false
    readScale: 'Disabled'
    minCapacity: json('null')
    autoPauseDelay: json('null')
  }
  test: {
    serviceTier: 'Standard'
    computeSize: 'S2'
    maxSizeBytes: 268435456000 // 250GB
    backupRetentionDays: 14
    geoRedundantBackup: false
    zoneRedundant: false
    readScale: 'Disabled'
    minCapacity: json('null')
    autoPauseDelay: json('null')
  }
  prod: {
    serviceTier: 'GeneralPurpose'
    computeSize: 'GP_Gen5_4'
    maxSizeBytes: 1099511627776 // 1TB
    backupRetentionDays: 35
    geoRedundantBackup: true
    zoneRedundant: true
    readScale: 'Enabled'
    minCapacity: json('0.5')
    autoPauseDelay: json('null')
  }
}

var config = environmentConfig[environment]
var isProd = environment == 'prod'

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: enableAzureADOnlyAuth ? null : administratorLogin
    administratorLoginPassword: enableAzureADOnlyAuth ? null : administratorLoginPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: enablePrivateEndpoint ? 'Disabled' : 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
    administrators: !empty(azureADAdminObjectId) ? {
      administratorType: 'ActiveDirectory'
      principalType: 'User'
      login: azureADAdminPrincipalName
      sid: azureADAdminObjectId
      tenantId: tenant().tenantId
      azureADOnlyAuthentication: enableAzureADOnlyAuth
    } : null
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Firewall rules (only for non-production without private endpoints)
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = if (!enablePrivateEndpoint) {
  name: 'AllowAllWindowsAzureIps'
  parent: sqlServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: databaseName
  parent: sqlServer
  location: location
  tags: tags
  sku: {
    name: config.computeSize
    tier: config.serviceTier
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: config.maxSizeBytes
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: config.zoneRedundant
    readScale: config.readScale
    requestedBackupStorageRedundancy: config.geoRedundantBackup ? 'GeoZone' : 'Local'
    isLedgerOn: false
    maintenanceConfigurationId: isProd ? subscriptionResourceId('Microsoft.Maintenance/publicMaintenanceConfigurations', 'SQL_Default') : null
    minCapacity: config.minCapacity
    autoPauseDelay: config.autoPauseDelay
  }
}

// Long-term retention policy
resource longTermRetentionPolicy 'Microsoft.Sql/servers/databases/longTermRetentionPolicies@2023-05-01-preview' = {
  name: 'default'
  parent: sqlDatabase
  properties: {
    weeklyRetention: isProd ? 'P12W' : 'PT0S'
    monthlyRetention: isProd ? 'P12M' : 'PT0S'
    yearlyRetention: isProd ? 'P5Y' : 'PT0S'
    weekOfYear: 1
  }
}

// Short-term retention policy
resource shortTermRetentionPolicy 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2023-05-01-preview' = {
  name: 'default'
  parent: sqlDatabase
  properties: {
    retentionDays: config.backupRetentionDays
  }
}

// Transparent Data Encryption
resource transparentDataEncryption 'Microsoft.Sql/servers/databases/transparentDataEncryption@2023-05-01-preview' = {
  name: 'current'
  parent: sqlDatabase
  properties: {
    state: 'Enabled'
  }
}

// Auditing
resource auditing 'Microsoft.Sql/servers/auditingSettings@2023-05-01-preview' = if (enableAuditing) {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    storageEndpoint: !empty(storageAccountId) ? reference(storageAccountId, '2023-01-01').primaryEndpoints.blob : null
    storageAccountAccessKey: !empty(storageAccountId) ? listKeys(storageAccountId, '2023-01-01').keys[0].value : null
    retentionDays: isProd ? 90 : 30
    isAzureMonitorTargetEnabled: !empty(logAnalyticsWorkspaceId)
    isDevopsAuditEnabled: true
    queueDelayMs: 4000
  }
}

// Database auditing settings
resource databaseAuditing 'Microsoft.Sql/servers/databases/auditingSettings@2023-05-01-preview' = if (enableAuditing) {
  name: 'default'
  parent: sqlDatabase
  properties: {
    state: 'Enabled'
    storageEndpoint: !empty(storageAccountId) ? reference(storageAccountId, '2023-01-01').primaryEndpoints.blob : null
    storageAccountAccessKey: !empty(storageAccountId) ? listKeys(storageAccountId, '2023-01-01').keys[0].value : null
    retentionDays: isProd ? 90 : 30
    isAzureMonitorTargetEnabled: !empty(logAnalyticsWorkspaceId)
  }
}

// Advanced Threat Protection
resource threatProtection 'Microsoft.Sql/servers/securityAlertPolicies@2023-05-01-preview' = if (enableAdvancedThreatProtection) {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    emailAddresses: securityAlertEmails
    emailAccountAdmins: true
    retentionDays: 30
    storageEndpoint: !empty(storageAccountId) ? reference(storageAccountId, '2023-01-01').primaryEndpoints.blob : null
    storageAccountAccessKey: !empty(storageAccountId) ? listKeys(storageAccountId, '2023-01-01').keys[0].value : null
  }
}

// Vulnerability Assessment
resource vulnerabilityAssessment 'Microsoft.Sql/servers/vulnerabilityAssessments@2023-05-01-preview' = if (enableVulnerabilityAssessment && !empty(storageAccountId)) {
  name: 'default'
  parent: sqlServer
  properties: {
    storageContainerPath: '${reference(storageAccountId, '2023-01-01').primaryEndpoints.blob}vulnerability-assessment'
    storageAccountAccessKey: listKeys(storageAccountId, '2023-01-01').keys[0].value
    recurringScans: {
      isEnabled: true
      emailSubscriptionAdmins: true
      emails: securityAlertEmails
    }
  }
  dependsOn: [
    threatProtection
  ]
}

// Database vulnerability assessment settings
resource databaseVulnerabilityAssessment 'Microsoft.Sql/servers/databases/vulnerabilityAssessments@2023-05-01-preview' = if (enableVulnerabilityAssessment && !empty(storageAccountId)) {
  name: 'default'
  parent: sqlDatabase
  properties: {
    storageContainerPath: '${reference(storageAccountId, '2023-01-01').primaryEndpoints.blob}vulnerability-assessment'
    storageAccountAccessKey: listKeys(storageAccountId, '2023-01-01').keys[0].value
    recurringScans: {
      isEnabled: true
      emailSubscriptionAdmins: true
      emails: securityAlertEmails
    }
  }
  dependsOn: [
    vulnerabilityAssessment
  ]
}

// Private endpoint (for production)
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (enablePrivateEndpoint) {
  name: '${sqlServerName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: null // Should be provided as parameter in real deployment
    }
    privateLinkServiceConnections: [
      {
        name: '${sqlServerName}-plsc'
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

// Diagnostic settings for SQL Server
resource sqlServerDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${sqlServerName}-diagnostics'
  scope: sqlServer
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
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

// Diagnostic settings for SQL Database
resource sqlDatabaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: '${databaseName}-diagnostics'
  scope: sqlDatabase
  properties: {
    workspaceId: logAnalyticsWorkspaceId
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
        category: 'AutomaticTuning'
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
      {
        category: 'QueryStoreWaitStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'Errors'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'DatabaseWaitStatistics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'Timeouts'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'Blocks'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'Deadlocks'
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
      {
        category: 'InstanceAndAppAdvanced'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
      {
        category: 'WorkloadManagement'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: isProd ? 90 : 30
        }
      }
    ]
  }
}

// Outputs
@description('SQL Server resource ID')
output sqlServerId string = sqlServer.id

@description('SQL Server name')
output sqlServerName string = sqlServer.name

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('SQL Server principal ID')
output sqlServerPrincipalId string = sqlServer.identity.principalId

@description('Database resource ID')
output databaseId string = sqlDatabase.id

@description('Database name')
output databaseName string = sqlDatabase.name

@description('Connection string template (with placeholder)')
output connectionStringTemplate string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Persist Security Info=False;User ID=${administratorLogin};Password={password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

@description('ADO.NET connection string template')
output adoNetConnectionString string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Authentication=Active Directory Default;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

@description('JDBC connection string template')
output jdbcConnectionString string = 'jdbc:sqlserver://${sqlServer.properties.fullyQualifiedDomainName}:1433;database=${databaseName};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;'

@description('ODBC connection string template')
output odbcConnectionString string = 'Driver={ODBC Driver 18 for SQL Server};Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Database=${databaseName};Uid=${administratorLogin};Pwd={password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;'

@description('Private endpoint ID (if created)')
output privateEndpointId string = enablePrivateEndpoint ? privateEndpoint.id : ''

@description('Database configuration summary')
output configurationSummary object = {
  serviceTier: config.serviceTier
  computeSize: config.computeSize
  maxSizeGB: config.maxSizeBytes / 1024 / 1024 / 1024
  backupRetentionDays: config.backupRetentionDays
  zoneRedundant: config.zoneRedundant
  readScale: config.readScale
  privateEndpointEnabled: enablePrivateEndpoint
  auditingEnabled: enableAuditing
  threatProtectionEnabled: enableAdvancedThreatProtection
  vulnerabilityAssessmentEnabled: enableVulnerabilityAssessment
}
