@description('SQL Server name')
param sqlServerName string

@description('Database name')
param databaseName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location for resources')
param location string = resourceGroup().location

@description('SQL Administrator username')
param administratorLogin string

@description('SQL Administrator password')
@secure()
param administratorLoginPassword string

@description('Database service tier')
@allowed(['Basic', 'Standard', 'Premium', 'GP_Gen5', 'BC_Gen5'])
param serviceTier string = environment == 'prod' ? 'GP_Gen5' : 'Standard'

@description('Database compute size')
param computeSize string = environment == 'prod' ? 'GP_Gen5_2' : 'S1'

@description('Maximum database size in bytes')
param maxSizeBytes int = environment == 'prod' ? 1099511627776 : 268435456000 // 1TB for prod, 250GB for others

@description('Enable Advanced Threat Protection')
param enableAdvancedThreatProtection bool = environment == 'prod'

@description('Enable auditing')
param enableAuditing bool = true

@description('Backup retention days')
@minValue(1)
@maxValue(35)
param backupRetentionDays int = environment == 'prod' ? 35 : 7

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Database'
}

// Variables
var firewallRules = [
  {
    name: 'AllowAllWindowsAzureIps'
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
]

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: environment == 'prod' ? 'Disabled' : 'Enabled'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Firewall rules
resource firewallRule 'Microsoft.Sql/servers/firewallRules@2023-05-01-preview' = [for rule in firewallRules: {
  name: rule.name
  parent: sqlServer
  properties: {
    startIpAddress: rule.startIpAddress
    endIpAddress: rule.endIpAddress
  }
}]

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: databaseName
  parent: sqlServer
  location: location
  tags: tags
  sku: {
    name: computeSize
    tier: serviceTier
  }
  properties: {
    maxSizeBytes: maxSizeBytes
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: environment == 'prod'
    readScale: environment == 'prod' ? 'Enabled' : 'Disabled'
    requestedBackupStorageRedundancy: environment == 'prod' ? 'GeoZone' : 'Local'
  }
}

// Long-term retention policy
resource longTermRetentionPolicy 'Microsoft.Sql/servers/databases/longTermRetentionPolicies@2023-05-01-preview' = {
  name: 'default'
  parent: sqlDatabase
  properties: {
    weeklyRetention: environment == 'prod' ? 'P12W' : 'PT0S'
    monthlyRetention: environment == 'prod' ? 'P12M' : 'PT0S'
    yearlyRetention: environment == 'prod' ? 'P5Y' : 'PT0S'
    weekOfYear: 1
  }
}

// Short-term retention policy
resource shortTermRetentionPolicy 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2023-05-01-preview' = {
  name: 'default'
  parent: sqlDatabase
  properties: {
    retentionDays: backupRetentionDays
  }
}

// Auditing
resource auditing 'Microsoft.Sql/servers/auditingSettings@2023-05-01-preview' = if (enableAuditing) {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    retentionDays: environment == 'prod' ? 90 : 30
    isAzureMonitorTargetEnabled: true
    isDevopsAuditEnabled: true
  }
}

// Advanced Threat Protection
resource threatProtection 'Microsoft.Sql/servers/securityAlertPolicies@2023-05-01-preview' = if (enableAdvancedThreatProtection) {
  name: 'default'
  parent: sqlServer
  properties: {
    state: 'Enabled'
    emailAccountAdmins: true
    retentionDays: 30
  }
}

// Vulnerability Assessment
resource vulnerabilityAssessment 'Microsoft.Sql/servers/vulnerabilityAssessments@2023-05-01-preview' = if (enableAdvancedThreatProtection) {
  name: 'default'
  parent: sqlServer
  properties: {
    recurringScans: {
      isEnabled: true
      emailSubscriptionAdmins: true
    }
  }
  dependsOn: [
    threatProtection
  ]
}

// Private endpoint (for production)
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (environment == 'prod') {
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

// Diagnostic settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${databaseName}-diagnostics'
  scope: sqlDatabase
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
  }
}

// Outputs
@description('SQL Server resource ID')
output sqlServerId string = sqlServer.id

@description('SQL Server FQDN')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('Database resource ID')
output databaseId string = sqlDatabase.id

@description('Connection string template')
output connectionStringTemplate string = 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};Persist Security Info=False;User ID=${administratorLogin};Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

@description('Private endpoint ID (if created)')
output privateEndpointId string = environment == 'prod' ? privateEndpoint.id : ''