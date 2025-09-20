@description('Name of the virtual machine')
@minLength(1)
@maxLength(15)
param vmName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Size of the virtual machine')
@allowed([
  'Standard_B1s'
  'Standard_B2s'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_E2s_v3'
  'Standard_E4s_v3'
])
param vmSize string = 'Standard_B2s'

@description('Administrator username')
@minLength(1)
@maxLength(20)
param adminUsername string

@description('Administrator password or SSH public key')
@secure()
param adminPasswordOrKey string

@description('Authentication type (password or sshPublicKey)')
@allowed(['password', 'sshPublicKey'])
param authenticationType string = 'password'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Operating system type')
@allowed(['Windows', 'Ubuntu'])
param osType string = 'Ubuntu'

@description('Enable monitoring and diagnostics')
param enableMonitoring bool = true

@description('Create public IP address')
param createPublicIP bool = true

@description('Network access (restricted or open)')
@allowed(['restricted', 'open'])
param networkAccess string = 'restricted'

@description('Resource tags')
param tags object = {
  Environment: environment
  CreatedBy: 'Bicep'
}

// Variables
var resourcePrefix = '${vmName}-${environment}'
var networkSecurityGroupName = '${resourcePrefix}-nsg'
var networkInterfaceName = '${resourcePrefix}-nic'
var publicIPAddressName = '${resourcePrefix}-pip'
var vnetName = '${resourcePrefix}-vnet'
var subnetName = 'vm-subnet'
var osDiskName = '${resourcePrefix}-osdisk'

var linuxConfiguration = {
  disablePasswordAuthentication: authenticationType == 'sshPublicKey'
  ssh: {
    publicKeys: authenticationType == 'sshPublicKey' ? [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ] : null
  }
}

var securityRules = networkAccess == 'restricted' ? [
  {
    name: osType == 'Windows' ? 'RDP-Restricted' : 'SSH-Restricted'
    properties: {
      priority: 1000
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '10.0.0.0/8'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: osType == 'Windows' ? '3389' : '22'
    }
  }
] : [
  {
    name: osType == 'Windows' ? 'RDP' : 'SSH'
    properties: {
      priority: 1000
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: osType == 'Windows' ? '3389' : '22'
    }
  }
]

// Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: networkSecurityGroupName
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
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
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// Public IP (conditional)
resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (createPublicIP) {
  name: publicIPAddressName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: environment == 'prod' ? ['1', '2', '3'] : []
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${environment}-${uniqueString(resourceGroup().id)}')
    }
  }
}

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: networkInterfaceName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: createPublicIP ? {
            id: publicIPAddress.id
          } : null
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
    enableAcceleratedNetworking: contains(['Standard_D2s_v3', 'Standard_D4s_v3', 'Standard_E2s_v3', 'Standard_E4s_v3'], vmSize)
  }
  dependsOn: [
    virtualNetwork
  ]
}

// Virtual Machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  tags: tags
  zones: environment == 'prod' ? ['1'] : []
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: authenticationType == 'password' ? adminPasswordOrKey : null
      linuxConfiguration: osType == 'Ubuntu' ? linuxConfiguration : null
      windowsConfiguration: osType == 'Windows' ? {
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
        }
      } : null
    }
    storageProfile: {
      imageReference: osType == 'Windows' ? {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      } : {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: environment == 'prod' ? 'Premium_LRS' : 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: {
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
      securityType: 'TrustedLaunch'
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Outputs
@description('Virtual machine resource ID')
output vmId string = virtualMachine.id

@description('Virtual machine name')
output vmName string = virtualMachine.name

@description('Public IP address (if created)')
output publicIPAddress string = createPublicIP ? publicIPAddress.properties.ipAddress : 'No public IP created'

@description('Private IP address')
output privateIPAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

@description('FQDN (if public IP created)')
output fqdn string = createPublicIP ? publicIPAddress.properties.dnsSettings.fqdn : 'No public IP created'

@description('Connection command')
output connectionCommand string = createPublicIP ? (osType == 'Windows'
  ? 'mstsc /v:${publicIPAddress.properties.dnsSettings.fqdn}'
  : 'ssh ${adminUsername}@${publicIPAddress.properties.dnsSettings.fqdn}') : 'Connect via private IP: ${networkInterface.properties.ipConfigurations[0].properties.privateIPAddress}'

@description('Network security group ID')
output nsgId string = networkSecurityGroup.id

@description('Virtual network ID')
output vnetId string = virtualNetwork.id