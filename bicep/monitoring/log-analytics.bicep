@description('Log Analytics workspace name')
param workspaceName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location for resources')
param location string = resourceGroup().location

@description('Data retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = environment == 'prod' ? 180 : 90

@description('Pricing tier')
@allowed(['Free', 'PerGB2018', 'PerNode', 'Premium', 'Standalone', 'Standard'])
param sku string = 'PerGB2018'

@description('Daily quota in GB')
@minValue(1)
@maxValue(1000)
param dailyQuotaGb int = environment == 'prod' ? 50 : 10

@description('Enable solutions')
param enableSolutions array = [
  'Security'
  'Updates'
  'ChangeTracking'
]

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Monitoring'
}

// Variables
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

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Solutions
resource solutions 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for solution in enableSolutions: {
  name: '${solutionMap[solution].name}(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  plan: {
    name: '${solutionMap[solution].name}(${logAnalyticsWorkspace.name})'
    publisher: solutionMap[solution].publisher
    product: solutionMap[solution].product
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}]

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
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

// Action Group for alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: '${workspaceName}-alerts'
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'alerts'
    enabled: true
    emailReceivers: [
      {
        name: 'admin'
        emailAddress: 'admin@company.com'
        useCommonAlertSchema: true
      }
    ]
  }
}

// Sample alert rule
resource alertRule 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: '${workspaceName}-high-cpu-alert'
  location: location
  tags: tags
  properties: {
    displayName: 'High CPU Usage Alert'
    description: 'Alert when CPU usage exceeds 80%'
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
          query: 'Perf | where ObjectName == "Processor" and CounterName == "% Processor Time" and InstanceName == "_Total" | summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer | where avg_CounterValue > 80'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

// Outputs
@description('Log Analytics workspace ID')
output workspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics workspace customer ID')
output customerId string = logAnalyticsWorkspace.properties.customerId

@description('Application Insights instrumentation key')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('Application Insights connection string')
output connectionString string = applicationInsights.properties.ConnectionString

@description('Action group ID')
output actionGroupId string = actionGroup.id