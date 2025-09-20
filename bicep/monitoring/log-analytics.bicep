@description('Log Analytics workspace name')
param workspaceName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location for resources')
param location string = resourceGroup().location

@description('Admin email for alerts')
param adminEmail string = 'admin@company.com'

@description('Enable Application Insights')
param enableAppInsights bool = true

@description('Enable alerting')
param enableAlerting bool = true

@description('Solutions to enable')
@allowed(['Security', 'Updates', 'ChangeTracking', 'VMInsights'])
param enableSolutions array = ['Security', 'Updates']

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Monitoring'
  DeployedBy: 'Bicep'
}

// Environment-specific configurations
var environmentConfig = {
  dev: {
    retentionInDays: 30
    dailyQuotaGb: 5
    sku: 'PerGB2018'
  }
  test: {
    retentionInDays: 90
    dailyQuotaGb: 10
    sku: 'PerGB2018'
  }
  prod: {
    retentionInDays: 180
    dailyQuotaGb: 50
    sku: 'PerGB2018'
  }
}

// Solution gallery mapping
var solutionMap = {
  Security: {
    name: 'Security'
    publisher: 'Microsoft'
    product: 'OMSGallery/Security'
  }
  Updates: {
    name: 'Updates'
    publisher: 'Microsoft'
    product: 'OMSGallery/Updates'
  }
  ChangeTracking: {
    name: 'ChangeTracking'
    publisher: 'Microsoft'
    product: 'OMSGallery/ChangeTracking'
  }
  VMInsights: {
    name: 'VMInsights'
    publisher: 'Microsoft'
    product: 'OMSGallery/VMInsights'
  }
}

var config = environmentConfig[environment]

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: config.sku
    }
    retentionInDays: config.retentionInDays
    workspaceCapping: {
      dailyQuotaGb: config.dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Log Analytics Solutions
resource solutions 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for solution in enableSolutions: {
  name: '${solutionMap[solution].name}(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  plan: {
    name: '${solutionMap[solution].name}(${logAnalyticsWorkspace.name})'
    publisher: solutionMap[solution].publisher
    product: solutionMap[solution].product
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}]

// Application Insights (conditional)
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableAppInsights) {
  name: '${workspaceName}-insights'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Action Group (conditional)
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = if (enableAlerting) {
  name: '${workspaceName}-alerts'
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

// High CPU Alert Rule (conditional)
resource highCpuAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlerting) {
  name: '${workspaceName}-high-cpu-alert'
  location: location
  tags: tags
  properties: {
    displayName: 'High CPU Usage Alert'
    description: 'Alert when CPU usage exceeds 80% for 15 minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspace.id
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: '''
            Perf 
            | where ObjectName == "Processor" 
              and CounterName == "% Processor Time" 
              and InstanceName == "_Total" 
            | summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer 
            | where avg_CounterValue > 80
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: enableAlerting ? [
        actionGroup.id
      ] : []
    }
  }
}

// High Memory Alert Rule (conditional)
resource highMemoryAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = if (enableAlerting) {
  name: '${workspaceName}-high-memory-alert'
  location: location
  tags: tags
  properties: {
    displayName: 'High Memory Usage Alert'
    description: 'Alert when memory usage exceeds 85% for 15 minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      logAnalyticsWorkspace.id
    ]
    windowSize: 'PT15M'
    criteria: {
      allOf: [
        {
          query: '''
            Perf 
            | where ObjectName == "Memory" 
              and CounterName == "% Committed Bytes In Use" 
            | summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer 
            | where avg_CounterValue > 85
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: enableAlerting ? [
        actionGroup.id
      ] : []
    }
  }
}

// Outputs
@description('Log Analytics workspace ID')
output workspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics workspace customer ID')
output customerId string = logAnalyticsWorkspace.properties.customerId

@description('Log Analytics workspace name')
output workspaceName string = logAnalyticsWorkspace.name

@description('Application Insights instrumentation key')
output instrumentationKey string = enableAppInsights ? applicationInsights.properties.InstrumentationKey : ''

@description('Application Insights connection string')
output connectionString string = enableAppInsights ? applicationInsights.properties.ConnectionString : ''

@description('Action group ID')
output actionGroupId string = enableAlerting ? actionGroup.id : ''
