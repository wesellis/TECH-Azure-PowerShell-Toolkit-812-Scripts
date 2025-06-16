// Azure Web App with SQL Database - Enterprise Template
// Modern Bicep template for web application deployment
// Author: Wesley Ellis | wes@wesellis.com
// Version: 2.0 | Production-ready with security and monitoring

// Parameters
@description('The name of the web application')
param webAppName string

@description('The name of the App Service Plan')
param appServicePlanName string = '${webAppName}-asp'

@description('The name of the SQL Server')
param sqlServerName string

@description('The name of the SQL Database')
param sqlDatabaseName string = '${webAppName}-db'

@description('The location for all resources')
param location string = resourceGroup().location

@description('The SKU for the App Service Plan')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1V2'
  'P2V2'
  'P3V2'
])
param appServicePlanSku string = 'B1'

@description('The SKU for the SQL Database')
@allowed([
  'Basic'
  'Standard'
  'Premium'
  'GeneralPurpose'
  'BusinessCritical'
])
param sqlDatabaseSku string = 'Basic'

@description('Administrator username for SQL Server')
@secure()
param sqlAdminUsername string

@description('Administrator password for SQL Server')
@secure()
param sqlAdminPassword string

@description('Enable Application Insights monitoring')
param enableApplicationInsights bool = true

@description('Enable SQL Database Advanced Threat Protection')
param enableSqlThreatProtection bool = true

@description('Environment name for tagging')
@allowed([
  'Development'
  'Testing'
  'Staging'
  'Production'
])
param environment string = 'Production'

@description('Key Vault name for secrets storage')
param keyVaultName string = '${webAppName}-kv'

// Variables
var appInsightsName = '${webAppName}-ai'
var logAnalyticsWorkspaceName = '${webAppName}-law'

// Enterprise tags
var commonTags = {
  Environment: environment
  ManagedBy: 'Bicep-Template'
  CreatedDate: utcNow('yyyy-MM-dd')
  Application: webAppName
  CostCenter: 'IT-Operations'
  Compliance: 'Enterprise-Standard'
}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: appInsightsName
  location: location
  tags: commonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Key Vault for secrets management
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: commonTags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    accessPolicies: []
  }
}

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: commonTags
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  tags: commonTags
  sku: {
    name: sqlDatabaseSku
    tier: sqlDatabaseSku
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648 // 2GB
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: false
    readScale: 'Disabled'
    requestedBackupStorageRedundancy: 'Local'
    isLedgerOn: false
  }
}

// SQL Server Firewall Rule for Azure Services
resource sqlServerFirewallRule 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// SQL Database Advanced Threat Protection
resource sqlDatabaseThreatProtection 'Microsoft.Sql/servers/databases/securityAlertPolicies@2022-05-01-preview' = if (enableSqlThreatProtection) {
  parent: sqlDatabase
  name: 'default'
  properties: {
    state: 'Enabled'
    disabledAlerts: []
    emailAddresses: []
    emailAccountAdmins: true
    retentionDays: 30
  }
}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: commonTags
  sku: {
    name: appServicePlanSku
  }
  kind: 'app'
  properties: {
    reserved: false
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: commonTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      use32BitWorkerProcess: false
      alwaysOn: true
      netFrameworkVersion: 'v6.0'
      appSettings: concat([
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment
        }
      ], enableApplicationInsights ? [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
      ] : [])
      connectionStrings: [
        {
          name: 'DefaultConnection'
          connectionString: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
          type: 'SQLAzure'
        }
      ]
    }
  }
}

// Grant Web App access to Key Vault
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-02-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
      }
    ]
  }
}

// Store SQL connection string in Key Vault
resource sqlConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'SqlConnectionString'
  properties: {
    value: 'Server=tcp:${sqlServer.properties.fullyQualifiedDomainName},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminUsername};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
    contentType: 'SQL Connection String'
  }
}

// Diagnostic Settings for Web App
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: webApp
  name: '${webAppName}-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// Outputs
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
output sqlDatabaseName string = sqlDatabase.name
output keyVaultName string = keyVault.name
output applicationInsightsKey string = enableApplicationInsights ? applicationInsights.properties.InstrumentationKey : ''
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output resourceGroupLocation string = location

// Output connection information
output deploymentSummary object = {
  webApplication: {
    name: webApp.name
    url: 'https://${webApp.properties.defaultHostName}'
    environment: environment
  }
  database: {
    serverName: sqlServer.name
    databaseName: sqlDatabase.name
    fqdn: sqlServer.properties.fullyQualifiedDomainName
  }
  monitoring: {
    applicationInsights: enableApplicationInsights ? applicationInsights.name : 'Not configured'
    logAnalytics: logAnalyticsWorkspace.name
  }
  security: {
    keyVault: keyVault.name
    httpsOnly: webApp.properties.httpsOnly
    minTlsVersion: webApp.properties.siteConfig.minTlsVersion
    sqlThreatProtection: enableSqlThreatProtection
  }
}
