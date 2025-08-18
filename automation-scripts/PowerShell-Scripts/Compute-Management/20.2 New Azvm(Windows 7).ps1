<#
.SYNOPSIS
    20.2 New Azvm(Windows 7)

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 20.2 New Azvm(Windows 7)

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


."$WEPSScriptRoot\13-Set-AzVMAutoShutdown.ps1"



$WEErrorActionPreference = " Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

." $WEPSScriptRoot\13-Set-AzVMAutoShutdown.ps1"

$WELocationName = 'CanadaCentral'

$WECustomerName = 'CanadaComputing'
$WEVMName = 'GPO1'
$WEResourceGroupName = -join (" $WECustomerName" , " _$WEVMName" , " _RG" )



$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"     = 'ON'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"    = " $WECustomerName"
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Production'
    " Application"     = 'TeamViewer'  
    " Purpose"         = 'TeamViewer testing on PS2.0 and Win7'
    " Uptime"          = '24/7'
    " Workload"        = 'TeamViewer'
    " VMGenenetation"  = 'Gen2'
    " RebootCaution"   = 'Schedule a window first before rebooting'
    " VMSize"          = 'B2MS'
    " Location"        = " $WELocationName"
    " Approved By"     = " Abdullah Ollivierre"
    " Approved On"     = ""

}


$newAzResourceGroupSplat = @{
    Name = $WEResourceGroupName
    Location = $WELocationName
    Tag = $WETags
}

New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat














$WEComputerName = $WEVMName



$WEVMSize = " Standard_B2MS"
$WEOSDiskCaching = " ReadWrite"
$WEOSCreateOption = " FromImage"


$WEGUID = [guid]::NewGuid()
$WEOSDiskName = -join (" $WEVMName" , " _OSDisk" , " _1" , " _$WEGUID" )


$WEDNSNameLabel = -join (" $WEVMName" , " DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com


$WENetworkName = -join (" $WEVMName" , " _group-vnet" )


$WENICPrefix = 'NIC1'
$WENICName = -join (" $WEVMName" , " _$WENICPrefix" ).ToLower()
$WEIPConfigName = -join (" $WEVMName" , " $WENICName" , " _IPConfig1" ).ToLower()


$WEPublicIPAddressName = -join (" $WEVMName" , " -ip" )


$WESubnetName = -join (" $WEVMName" , " -subnet" )
$WESubnetAddressPrefix = " 10.0.0.0/24"
$WEVnetAddressPrefix = " 10.0.0.0/16"


$WENSGName = -join (" $WEVMName" , " -nsg" )


$newAzVirtualNetworkSubnetConfigSplat = @{
    Name          = $WESubnetName
    AddressPrefix = $WESubnetAddressPrefix
}
$WESingleSubnet = New-AzVirtualNetworkSubnetConfig -ErrorAction Stop @newAzVirtualNetworkSubnetConfigSplat


$newAzVirtualNetworkSplat = @{
    Name              = $WENetworkName
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    AddressPrefix     = $WEVnetAddressPrefix
    Subnet            = $WESingleSubnet
    Tag               = $WETags
}
$WEVnet = New-AzVirtualNetwork -ErrorAction Stop @newAzVirtualNetworkSplat



    # IpTagType = " FirstPartyUsage"
    # Tag       = " /Sql"





$newAzPublicIpAddressSplat = @{
    Name              = $WEPublicIPAddressName
    DomainNameLabel   = $WEDNSNameLabel
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    # AllocationMethod  = 'Dynamic'
    AllocationMethod  = 'Static'
    # IpTag             = $ipTag
    Tag               = $WETags
}
$WEPIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat






$WESourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip" ).Content #Gets the public IP of the current machine
$WESourceAddressPrefixCIDR = -join (" $WESourceAddressPrefix" , " /32" )





$WEASGName = -join (" $WEVMName" , " _ASG1" )
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = " $WEResourceGroupName"
    Name              = " $WEASGName"
    Location          = " $WELocationName"
    Tag               = $WETags
}
$WEASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat



$getAzVirtualNetworkSubnetConfigSplat = @{
    Name = $WESubnetName
    VirtualNetwork = $vnet
}

$WESubnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat


$newAzNetworkInterfaceIpConfigSplat = @{
    Name                     = $WEIPConfigName
    Subnet                   = $WESubnet
    # Subnet                   = $WEVnet.Subnets[0].Id
    # PublicIpAddress          = $WEPIP.ID
    PublicIpAddress          = $WEPIP
    ApplicationSecurityGroup = $WEASG
    Primary                  = $true
}

$WEIPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat

$newAzNetworkSecurityRuleConfigSplat = @{
    # Name = 'rdp-rule'
    Name                                = 'RDP-rule'
    # Description = " Allow RDP"
    Description                         = 'Allow RDP'
    Access                              = 'Allow'
    Protocol                            = 'Tcp'
    Direction                           = 'Inbound'
    Priority                            = 100
    SourceAddressPrefix                 = $WESourceAddressPrefixCIDR
    SourcePortRange                     = '*'
    # DestinationAddressPrefix = '*'
    # DestinationAddressPrefix = $WEDestinationAddressPrefixCIDR #this will throw an error due to {Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress/32} work on it some time to fix 
    # DestinationAddressPrefix = '*'
    # DestinationPortRange = 3389
    DestinationPortRange                = '3389'
    DestinationApplicationSecurityGroup = $WEASG
}
$rule1 = New-AzNetworkSecurityRuleConfig -ErrorAction Stop @newAzNetworkSecurityRuleConfigSplat


$newAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    Name              = $WENSGName
    # SecurityRules     = $rule1, $rule2
    SecurityRules     = $rule1
    Tag               = $WETags
}
$WENSG = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat


$newAzNetworkInterfaceSplat = @{
    Name                   = $WENICName
    ResourceGroupName      = $WEResourceGroupName
    Location               = $WELocationName
    # SubnetId                 = $WEVnet.Subnets[0].Id
    # PublicIpAddressId        = $WEPIP.Id
    NetworkSecurityGroupId = $WENSG.Id
    # ApplicationSecurityGroup = $WEASG
    IpConfiguration        = $WEIPConfig1
    Tag                    = $WETags
    
}
$WENIC = New-AzNetworkInterface -ErrorAction Stop @newAzNetworkInterfaceSplat


$WECredential = Get-Credential -ErrorAction Stop


$newAzVMConfigSplat = @{
    VMName = $WEVMName
    VMSize = $WEVMSize
    Tags   = $WETags
}
$WEVirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat


$setAzVMOperatingSystemSplat = @{
    VM           = $WEVirtualMachine
    Windows      = $true
    # Linux        = $true
    ComputerName = $WEComputerName
    Credential   = $WECredential
    # ProvisionVMAgent = $true
    # EnableAutoUpdate = $true
}
$WEVirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat


$addAzVMNetworkInterfaceSplat = @{
    VM = $WEVirtualMachine
    Id = $WENIC.Id
}
$WEVirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat


$setAzVMSourceImageSplat = @{
    VM            = $WEVirtualMachine
    # PublisherName = " Canonical"
    # Offer         = " 0001-com-ubuntu-server-focal"
    # Skus          = " 20_04-lts-gen2"
    # Version       = " latest"
    publisherName = " microsoftwindowsdesktop"
    offer         = " windows-7"
    Skus          = " win7-enterprise"
    version       = " latest"


    # publisherName = " MicrosoftWindowsServer"
    # offer         = " WindowsServer"
    # Skus          = " 2019-datacenter-gensecond"
    # version       = " latest"



    # Caching = 'ReadWrite'
}

$WEVirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat


$setAzVMOSDiskSplat = @{
    VM           = $WEVirtualMachine
    Name         = $WEOSDiskName
    # VhdUri = $WEOSDiskUri
    # SourceImageUri = $WESourceImageUri
    Caching      = $WEOSDiskCaching
    CreateOption = $WEOSCreateOption
    # Windows = $true
    DiskSizeInGB = '128'
}
$WEVirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat

; 
$newAzVMSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    VM                = $WEVirtualMachine
    Verbose           = $true
    Tag               = $WETags
}
New-AzVM -ErrorAction Stop @newAzVMSplat

; 
$setAzVMAutoShutdownSplat = @{
    # ResourceGroupName = 'RG-WE-001'
    ResourceGroupName = $WEResourceGroupName
    # Name              = 'MYVM001'
    Name              = $WEVMName
    Enable            = $true
    Time              = '23:59'
    # TimeZone = " W. Europe Standard Time"
    TimeZone          = " Central Standard Time"
    Email             = " abdullah@canadacomputing.ca"
}

Set-AzVMAutoShutdown -ErrorAction Stop @setAzVMAutoShutdownSplat




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================