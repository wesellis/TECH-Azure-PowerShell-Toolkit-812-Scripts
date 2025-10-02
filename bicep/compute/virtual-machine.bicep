@description('Name of the virtual machine')
@minLength(1)
@maxLength(15)
param vmName string

@description('Environment (dev, test, prod)')
@allowed(['dev', 'test', 'prod'])
param environment string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Administrator username')
@minLength(1)
@maxLength(20)
param adminUsername string

@description('Administrator password or SSH public key')
@secure()
@minLength(12)
param adminPasswordOrKey string

@description('Authentication type (password or sshPublicKey)')
@allowed(['password', 'sshPublicKey'])
param authenticationType string = 'sshPublicKey'

@description('Operating system type')
@allowed(['Windows', 'Ubuntu', 'RHEL'])
param osType string = 'Ubuntu'

@description('Create public IP address')
param createPublicIP bool = (environment != 'prod')

@description('Network access (restricted or open)')
@allowed(['restricted', 'open'])
param networkAccess string = (environment == 'prod') ? 'restricted' : 'open'

@description('Enable monitoring and diagnostics')
param enableMonitoring bool = true

@description('Enable backup')
param enableBackup bool = (environment == 'prod')

@description('Enable boot diagnostics')
param enableBootDiagnostics bool = true

@description('Enable accelerated networking')
param enableAcceleratedNetworking bool = false

@description('Data disks configuration')
param dataDisks array = []

@description('Existing virtual network resource ID (optional)')
param existingVnetId string = ''

@description('Existing subnet resource ID (optional)')
param existingSubnetId string = ''

@description('Log Analytics workspace ID for monitoring')
param logAnalyticsWorkspaceId string = ''

@description('Resource tags')
param tags object = {
  Environment: environment
  Service: 'Compute'
  DeployedBy: 'Bicep'
}

// Environment-specific configurations
var environmentConfig = {
  dev: {
    vmSize: 'Standard_B2s'
    osDiskType: 'StandardSSD_LRS'
    availabilityZones: []
    enableDiskEncryption: false
  }
  test: {
    vmSize: 'Standard_D2s_v3'
    osDiskType: 'StandardSSD_LRS'
    availabilityZones: []
    enableDiskEncryption: false
  }
  prod: {
    vmSize: 'Standard_D4s_v3'
    osDiskType: 'Premium_LRS'
    availabilityZones: ['1']
    enableDiskEncryption: true
  }
}

var config = environmentConfig[environment]
var isProd = environment == 'prod'
var resourcePrefix = '${vmName}-${environment}'

// OS Image configurations
var osImages = {
  Windows: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  Ubuntu: {
    publisher: 'Canonical'
    offer: '0001-com-ubuntu-server-jammy'
    sku: '22_04-lts-gen2'
    version: 'latest'
  }
  RHEL: {
    publisher: 'RedHat'
    offer: 'RHEL'
    sku: '9-lvm-gen2'
    version: 'latest'
  }
}

var isLinux = osType != 'Windows'
var useExistingNetwork = !empty(existingVnetId) && !empty(existingSubnetId)

// Linux configuration for SSH
var linuxConfiguration = {
  disablePasswordAuthentication: authenticationType == 'sshPublicKey'
  ssh: {
    publicKeys: authenticationType == 'sshPublicKey' ? [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ] : []
  }
  provisionVMAgent: true
  patchSettings: {
    patchMode: 'ImageDefault'
    assessmentMode: 'ImageDefault'
  }
}

// Windows configuration
var windowsConfiguration = {
  enableAutomaticUpdates: true
  provisionVMAgent: true
  patchSettings: {
    patchMode: 'AutomaticByPlatform'
    automaticByPlatformSettings: {
      rebootSetting: 'IfRequired'
    }
    assessmentMode: 'AutomaticByPlatform'
  }
  timeZone: 'UTC'
}

// Security rules based on network access and OS type
var securityRules = concat([
  // Common deny rule
  {
    name: 'DenyAllInbound'
    properties: {
      priority: 4096
      protocol: '*'
      access: 'Deny'
      direction: 'Inbound'
      sourceAddressPrefix: '*'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '*'
    }
  }
], networkAccess == 'restricted' ? [
  // Restricted access
  {
    name: isLinux ? 'SSH-Restricted' : 'RDP-Restricted'
    properties: {
      priority: 1000
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: '10.0.0.0/8'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: isLinux ? '22' : '3389'
    }
  }
] : [
  // Open access
  {
    name: isLinux ? 'SSH' : 'RDP'
    properties: {
      priority: 1000
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'Internet'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: isLinux ? '22' : '3389'
    }
  }
])

// Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = if (!useExistingNetwork) {
  name: '${resourcePrefix}-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: securityRules
  }
}

// Virtual Network (only if not using existing)
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = if (!useExistingNetwork) {
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
        name: 'vm-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          serviceEndpoints: isProd ? [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.KeyVault'
            }
          ] : []
        }
      }
    ]
  }
}

// Public IP Address (conditional)
resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (createPublicIP) {
  name: '${resourcePrefix}-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: config.availabilityZones
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: toLower('${vmName}-${environment}-${uniqueString(resourceGroup().id)}')
    }
    idleTimeoutInMinutes: 4
  }
}

// Network Interface
resource networkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${resourcePrefix}-nic'
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
            id: useExistingNetwork ? existingSubnetId : resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'vm-subnet')
          }
        }
      }
    ]
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: false
    networkSecurityGroup: useExistingNetwork ? null : {
      id: networkSecurityGroup.id
    }
  }
  dependsOn: useExistingNetwork ? [] : [
    virtualNetwork
  ]
}

// Storage Account for boot diagnostics (if enabled)
resource bootDiagnosticsStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = if (enableBootDiagnostics) {
  name: 'bootdiag${uniqueString(resourceGroup().id, vmName)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// Virtual Machine
resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  tags: tags
  zones: config.availabilityZones
  properties: {
    hardwareProfile: {
      vmSize: config.vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: authenticationType == 'password' ? adminPasswordOrKey : null
      linuxConfiguration: isLinux ? linuxConfiguration : null
      windowsConfiguration: !isLinux ? windowsConfiguration : null
      allowExtensionOperations: true
    }
    storageProfile: {
      imageReference: osImages[osType]
      osDisk: {
        name: '${resourcePrefix}-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: config.osDiskType
        }
        deleteOption: 'Delete'
        diskSizeGB: isLinux ? 30 : 127
      }
      dataDisks: [for (disk, i) in dataDisks: {
        name: '${resourcePrefix}-datadisk-${i}'
        diskSizeGB: disk.sizeGB
        lun: i
        caching: contains(disk, 'caching') ? disk.caching : 'ReadWrite'
        createOption: 'Empty'
        managedDisk: {
          storageAccountType: contains(disk, 'storageAccountType') ? disk.storageAccountType : config.osDiskType
        }
        deleteOption: 'Delete'
      }]
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
      encryptionAtHost: config.enableDiskEncryption
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: enableBootDiagnostics
        storageUri: enableBootDiagnostics ? bootDiagnosticsStorage.properties.primaryEndpoints.blob : null
      }
    }
    priority: 'Regular'
    availabilitySet: null
  }
}

// VM Extensions
resource azureMonitorAgent 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = if (enableMonitoring && !empty(logAnalyticsWorkspaceId)) {
  name: 'AzureMonitorAgent'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: isLinux ? 'AzureMonitorLinuxAgent' : 'AzureMonitorWindowsAgent'
    typeHandlerVersion: isLinux ? '1.0' : '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      workspaceId: !empty(logAnalyticsWorkspaceId) ? reference(logAnalyticsWorkspaceId, '2023-09-01').customerId : ''
    }
    protectedSettings: {
      workspaceKey: !empty(logAnalyticsWorkspaceId) ? listKeys(logAnalyticsWorkspaceId, '2023-09-01').primarySharedKey : ''
    }
  }
}

resource dependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = if (enableMonitoring && !empty(logAnalyticsWorkspaceId)) {
  name: 'DependencyAgent'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: isLinux ? 'DependencyAgentLinux' : 'DependencyAgentWindows'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
  dependsOn: [
    azureMonitorAgent
  ]
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = if (isLinux) {
  name: 'CustomScript'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      script: base64('''
        #!/bin/bash
        
        # Update system
        apt-get update -y
        
        # Install basic packages
        apt-get install -y curl wget unzip htop
        
        # Configure firewall
        ufw enable
        ufw allow ssh
        
        # Set timezone
        timedatectl set-timezone UTC
        
        # Configure automatic updates
        apt-get install -y unattended-upgrades
        dpkg-reconfigure -plow unattended-upgrades
        
        echo "VM setup completed successfully" > /var/log/vm-setup.log
      ''')
    }
  }
  dependsOn: [
    dependencyAgent
  ]
}

// Backup (for production)
resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-06-01' = if (enableBackup) {
  name: '${resourcePrefix}-rsv'
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-06-01' = if (enableBackup) {
  name: '${vmName}-backup-policy'
  parent: recoveryServicesVault
  properties: {
    backupManagementType: 'AzureIaasVM'
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2023-01-01T02:00:00Z'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
        ]
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2023-01-01T02:00:00Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Months'
        }
      }
    }
    timeZone: 'UTC'
  }
}

// Outputs
@description('Virtual machine resource ID')
output vmId string = virtualMachine.id

@description('Virtual machine name')
output vmName string = virtualMachine.name

@description('Virtual machine computer name')
output computerName string = virtualMachine.properties.osProfile.computerName

@description('Public IP address (if created)')
output publicIPAddress string = createPublicIP ? publicIPAddress.properties.ipAddress : 'No public IP created'

@description('Private IP address')
output privateIPAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress

@description('FQDN (if public IP created)')
output fqdn string = createPublicIP ? publicIPAddress.properties.dnsSettings.fqdn : 'No public IP created'

@description('SSH/RDP connection command')
output connectionCommand string = createPublicIP ? (isLinux
  ? 'ssh ${adminUsername}@${publicIPAddress.properties.dnsSettings.fqdn}'
  : 'mstsc /v:${publicIPAddress.properties.dnsSettings.fqdn}') : 'Connect via private IP: ${networkInterface.properties.ipConfigurations[0].properties.privateIPAddress}'

@description('Network security group ID (if created)')
output nsgId string = useExistingNetwork ? '' : networkSecurityGroup.id

@description('Virtual network ID (if created)')
output vnetId string = useExistingNetwork ? existingVnetId : virtualNetwork.id

@description('Subnet ID')
output subnetId string = useExistingNetwork ? existingSubnetId : resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'vm-subnet')

@description('Network interface ID')
output nicId string = networkInterface.id

@description('Boot diagnostics storage account (if created)')
output bootDiagnosticsStorageAccount string = enableBootDiagnostics ? bootDiagnosticsStorage.name : ''

@description('Recovery Services Vault ID (if backup enabled)')
output recoveryServicesVaultId string = enableBackup ? recoveryServicesVault.id : ''

@description('VM configuration summary')
output configurationSummary object = {
  vmSize: config.vmSize
  osType: osType
  osDiskType: config.osDiskType
  availabilityZones: config.availabilityZones
  publicIPEnabled: createPublicIP
  networkAccess: networkAccess
  monitoringEnabled: enableMonitoring
  backupEnabled: enableBackup
  bootDiagnosticsEnabled: enableBootDiagnostics
  diskEncryptionEnabled: config.enableDiskEncryption
  acceleratedNetworkingEnabled: enableAcceleratedNetworking
}
