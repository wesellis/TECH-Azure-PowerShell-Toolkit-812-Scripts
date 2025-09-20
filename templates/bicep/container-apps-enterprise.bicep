// Azure Container Apps with Application Gateway Enterprise Template
// Deploys a scalable, secure container application with load balancing

@description('Name prefix for all resources')
param namePrefix string = 'containerapp'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Container image to deploy')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Environment type')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'prod'

@description('Enable Application Gateway for external access')
param enableApplicationGateway bool = true

@description('Enable private networking')
param enablePrivateNetworking bool = true

@description('Enable Application Insights monitoring')
param enableApplicationInsights bool = true

@description('Enable Key Vault integration')
param enableKeyVault bool = true

@description('Custom domain name for the application')
param customDomain string = ''

@description('SSL certificate name in Key Vault')
param sslCertificateName string = 'ssl-cert'

// Variables
var environmentName = '${namePrefix}-env-${environment}'
var containerAppName = '${namePrefix}-app-${environment}'
var applicationGatewayName = '${namePrefix}-agw-${environment}'
var vnetName = '${namePrefix}-vnet-${environment}'
var keyVaultName = '${namePrefix}-kv-${uniqueString(resourceGroup().id)}'
var applicationInsightsName = '${namePrefix}-ai-${environment}'
var logAnalyticsName = '${namePrefix}-law-${environment}'

// Common tags
var commonTags = {
  Environment: environment
  Application: 'ContainerApp'
  ManagedBy: 'Bicep'
  CreatedDate: utcNow('yyyy-MM-dd')
}

// Virtual Network for private networking
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = if (enablePrivateNetworking) {
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
        name: 'container-apps-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'Microsoft.App/environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        name: 'application-gateway-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'private-endpoints-subnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
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
  }
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = if (enableApplicationInsights) {
  name: applicationInsightsName
  location: location
  tags: commonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Key Vault for secrets management
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = if (enableKeyVault) {
  name: keyVaultName
  location: location
  tags: commonTags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Container Apps Environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  tags: commonTags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: enablePrivateNetworking ? {
      infrastructureSubnetId: vnet.properties.subnets[0].id
      internal: true
    } : null
    zoneRedundant: environment == 'prod'
  }
}

// Managed Identity for Container App
resource containerAppManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${containerAppName}-identity'
  location: location
  tags: commonTags
}

// Role assignment for Key Vault access
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableKeyVault) {
  name: guid(keyVault.id, containerAppManagedIdentity.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: containerAppManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  tags: commonTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerAppManagedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: !enablePrivateNetworking
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      secrets: enableKeyVault ? [
        {
          name: 'app-secrets'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/app-config'
          identity: containerAppManagedIdentity.id
        }
      ] : []
      registries: []
    }
    template: {
      containers: [
        {
          name: 'main'
          image: containerImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: concat([
            {
              name: 'ENVIRONMENT'
              value: environment
            }
          ], enableApplicationInsights ? [
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ] : [], enableKeyVault ? [
            {
              name: 'AZURE_CLIENT_ID'
              value: containerAppManagedIdentity.properties.clientId
            }
            {
              name: 'KEY_VAULT_URL'
              value: keyVault.properties.vaultUri
            }
          ] : [])
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 80
              }
              initialDelaySeconds: 30
              periodSeconds: 10
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/ready'
                port: 80
              }
              initialDelaySeconds: 5
              periodSeconds: 5
            }
          ]
        }
      ]
      scale: {
        minReplicas: environment == 'prod' ? 2 : 1
        maxReplicas: environment == 'prod' ? 10 : 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
          {
            name: 'cpu-scaling'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
          }
        ]
      }
    }
  }
}

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = if (enableApplicationGateway) {
  name: '${applicationGatewayName}-pip'
  location: location
  tags: commonTags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: customDomain != '' ? {
      domainNameLabel: split(customDomain, '.')[0]
    } : null
  }
}

// Application Gateway
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-04-01' = if (enableApplicationGateway && enablePrivateNetworking) {
  name: applicationGatewayName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'gateway-ip-config'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontend-ip-config'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port-80'
        properties: {
          port: 80
        }
      }
      {
        name: 'port-443'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'container-app-backend'
        properties: {
          backendAddresses: [
            {
              fqdn: containerApp.properties.configuration.ingress.fqdn
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backend-http-settings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          pickHostNameFromBackendAddress: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'health-probe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'http-listener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'frontend-ip-config')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port-80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routing-rule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'http-listener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'container-app-backend')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'backend-http-settings')
          }
        }
      }
    ]
    probes: [
      {
        name: 'health-probe'
        properties: {
          protocol: 'Https'
          path: '/health'
          interval: 30
          timeout: 10
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
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 2
      maxCapacity: 10
    }
  }
  dependsOn: [
    containerApp
  ]
}

// Diagnostic Settings for Container App
resource containerAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'container-app-diagnostics'
  scope: containerApp
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
      {
        category: 'ContainerAppSystemLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
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

// Outputs
output containerAppUrl string = enableApplicationGateway && enablePrivateNetworking ? 'https://${publicIp.properties.ipAddress}' : 'https://${containerApp.properties.configuration.ingress.fqdn}'
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output applicationGatewayPublicIp string = enableApplicationGateway ? publicIp.properties.ipAddress : ''
output keyVaultUri string = enableKeyVault ? keyVault.properties.vaultUri : ''
output applicationInsightsConnectionString string = enableApplicationInsights ? applicationInsights.properties.ConnectionString : ''
output logAnalyticsWorkspaceId string = logAnalytics.properties.customerId
output managedIdentityClientId string = containerAppManagedIdentity.properties.clientId
output environmentId string = containerAppsEnvironment.id
