@description('Virtual network name')
param vnetName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location for resources')
param location string = resourceGroup().location

@description('Address prefix for the virtual network')
param addressPrefix string = '10.0.0.0/16'

@description('Enable DDoS protection')
param enableDdosProtection bool = (environment == 'prod')

@description('Enable VM protection')
param enableVmProtection bool = true

@description('DNS servers (optional)')
param dnsServers array = []

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Network'
  DeployedBy: 'Bicep'
}

// Environment-specific subnet configurations
var environmentSubnets = {
  dev: [
    {
      name: 'default'
      addressPrefix: '10.0.1.0/24'
      serviceEndpoints: []
      delegations: []
    }
    {
      name: 'web'
      addressPrefix: '10.0.2.0/24'
      serviceEndpoints: [
        'Microsoft.Storage'
        'Microsoft.KeyVault'
      ]
      delegations: []
    }
  ]
  test: [
    {
      name: 'default'
      addressPrefix: '10.0.1.0/24'
      serviceEndpoints: []
      delegations: []
    }
    {
      name: 'web'
      addressPrefix: '10.0.2.0/24'
      serviceEndpoints: [
        'Microsoft.Storage'
        'Microsoft.KeyVault'
      ]
      delegations: []
    }
    {
      name: 'data'
      addressPrefix: '10.0.3.0/24'
      serviceEndpoints: [
        'Microsoft.Sql'
        'Microsoft.Storage'
      ]
      delegations: []
    }
  ]
  prod: [
    {
      name: 'default'
      addressPrefix: '10.0.1.0/24'
      serviceEndpoints: []
      delegations: []
    }
    {
      name: 'web'
      addressPrefix: '10.0.2.0/24'
      serviceEndpoints: [
        'Microsoft.Storage'
        'Microsoft.KeyVault'
        'Microsoft.Sql'
      ]
      delegations: [
        {
          name: 'app-service-delegation'
          serviceName: 'Microsoft.Web/serverFarms'
        }
      ]
    }
    {
      name: 'data'
      addressPrefix: '10.0.3.0/24'
      serviceEndpoints: [
        'Microsoft.Sql'
        'Microsoft.Storage'
        'Microsoft.KeyVault'
      ]
      delegations: []
    }
    {
      name: 'private-endpoints'
      addressPrefix: '10.0.4.0/24'
      serviceEndpoints: []
      delegations: []
      privateEndpointNetworkPolicies: 'Disabled'
    }
    {
      name: 'app-gateway'
      addressPrefix: '10.0.5.0/24'
      serviceEndpoints: []
      delegations: []
    }
  ]
}

var subnets = environmentSubnets[environment]

// DDoS Protection Plan (production only)
resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2023-05-01' = if (enableDdosProtection) {
  name: '${vnetName}-ddos-plan'
  location: location
  tags: tags
  properties: {}
}

// Network Security Groups for each subnet
resource defaultNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-default-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
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

resource webNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: '${vnetName}-web-nsg'
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
          sourceAddressPrefix: environment == 'prod' ? '10.0.5.0/24' : 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: environment == 'prod' ? '10.0.5.0/24' : 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
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

resource dataNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = if (contains(['test', 'prod'], environment)) {
  name: '${vnetName}-data-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSQLFromWeb'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '10.0.2.0/24'
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

resource privateEndpointNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = if (environment == 'prod') {
  name: '${vnetName}-pe-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVNetInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource appGatewayNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = if (environment == 'prod') {
  name: '${vnetName}-agw-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowGatewayManager'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPSInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1200
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Route Table for custom routing
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = if (environment == 'prod') {
  name: '${vnetName}-rt'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'default-route'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
    disableBgpRoutePropagation: false
  }
}

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    dhcpOptions: !empty(dnsServers) ? {
      dnsServers: dnsServers
    } : null
    enableDdosProtection: enableDdosProtection
    ddosProtectionPlan: enableDdosProtection ? {
      id: ddosProtectionPlan.id
    } : null
    enableVmProtection: enableVmProtection
    subnets: [for (subnet, index) in subnets: {
      name: subnet.name
      properties: union({
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: subnet.name == 'default' ? defaultNsg.id 
            : subnet.name == 'web' ? webNsg.id 
            : subnet.name == 'data' ? dataNsg.id 
            : subnet.name == 'private-endpoints' ? privateEndpointNsg.id 
            : subnet.name == 'app-gateway' ? appGatewayNsg.id 
            : defaultNsg.id
        }
        serviceEndpoints: [for endpoint in subnet.serviceEndpoints: {
          service: endpoint
        }]
        delegations: [for delegation in subnet.delegations: {
          name: delegation.name
          properties: {
            serviceName: delegation.serviceName
          }
        }]
        routeTable: (environment == 'prod' && subnet.name != 'app-gateway') ? {
          id: routeTable.id
        } : null
      }, contains(subnet, 'privateEndpointNetworkPolicies') ? {
        privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
      } : {})
    }]
  }
}

// Flow logs for production
resource networkWatcher 'Microsoft.Network/networkWatchers@2023-05-01' existing = if (environment == 'prod') {
  name: 'NetworkWatcher_${location}'
}

resource flowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-05-01' = if (environment == 'prod') {
  name: '${vnetName}-flowlog'
  parent: networkWatcher
  location: location
  tags: tags
  properties: {
    targetResourceId: defaultNsg.id
    enabled: true
    retentionPolicy: {
      days: 30
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
  }
}

// Outputs
@description('Virtual network resource ID')
output vnetId string = virtualNetwork.id

@description('Virtual network name')
output vnetName string = virtualNetwork.name

@description('Virtual network address space')
output addressSpace array = virtualNetwork.properties.addressSpace.addressPrefixes

@description('Subnet information')
output subnets array = [for i in range(0, length(subnets)): {
  name: virtualNetwork.properties.subnets[i].name
  id: virtualNetwork.properties.subnets[i].id
  addressPrefix: virtualNetwork.properties.subnets[i].properties.addressPrefix
  nsgId: virtualNetwork.properties.subnets[i].properties.networkSecurityGroup.id
}]

@description('Network Security Group IDs')
output nsgIds object = {
  default: defaultNsg.id
  web: webNsg.id
  data: contains(['test', 'prod'], environment) ? dataNsg.id : ''
  privateEndpoints: environment == 'prod' ? privateEndpointNsg.id : ''
  appGateway: environment == 'prod' ? appGatewayNsg.id : ''
}

@description('DDoS Protection Plan ID (if enabled)')
output ddosProtectionPlanId string = enableDdosProtection ? ddosProtectionPlan.id : ''

@description('Route Table ID (if created)')
output routeTableId string = environment == 'prod' ? routeTable.id : ''
