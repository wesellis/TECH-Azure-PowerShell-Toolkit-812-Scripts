<#
.SYNOPSIS
    23 New Azvm Windowsserver 2022 Workgroup With New Vnet

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
    We Enhanced 23 New Azvm Windowsserver 2022 Workgroup With New Vnet

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = 'stop'


$WEHelpers = "$WEPsScriptRoot\Helpers\"

Get-ChildItem -Path $WEHelpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }



$WELocationName = 'Canadaeast'

$WECustomerName = 'CCI'
$WEVMName = 'Splunk1'

$WEResourceGroupName = -join (" $WECustomerName" , " _$WEVMName" , " _RG" )



$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"     = 'ON'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"    = " $WECustomerName"
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Dev'
    " Application"     = 'Splunk1'  
    " Purpose"         = 'Splunk1 to be used by Shan@canadacomputing.ca for FGC Health monitoring'
    " Uptime"          = '24/7'
    " Workload"        = 'Splunk1'
    " RebootCaution"   = 'Only reboot for maintenance'
    " VMSize"          = ''
    " Location"        = " $WELocationName"
    " Approved By"     = " Abdullah Ollivierre"
    " Approved On"     = " Jan-26-2022"

}




$newAzResourceGroupSplat = @{
    Name     = $WEResourceGroupName
    Location = $WELocationName
    Tag      = $WETags
}


New-AzResourceGroup @newAzResourceGroupSplat














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
$WESingleSubnet = New-AzVirtualNetworkSubnetConfig @newAzVirtualNetworkSubnetConfigSplat




$newAzVirtualNetworkSplat = @{
    Name              = $WENetworkName
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    AddressPrefix     = $WEVnetAddressPrefix
    Subnet            = $WESingleSubnet
    Tag               = $WETags
}
$WEVnet = New-AzVirtualNetwork @newAzVirtualNetworkSplat








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
$WEPIP = New-AzPublicIpAddress @newAzPublicIpAddressSplat






$WESourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip" ).Content #Gets the public IP of the current machine
$WESourceAddressPrefixCIDR = -join (" $WESourceAddressPrefix" , " /32" )





$WEASGName = -join (" $WEVMName" , " _ASG1" )
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = " $WEResourceGroupName"
    Name              = " $WEASGName"
    Location          = " $WELocationName"
    Tag               = $WETags
}
$WEASG = New-AzApplicationSecurityGroup @newAzApplicationSecurityGroupSplat



$getAzVirtualNetworkSubnetConfigSplat = @{
    Name           = $WESubnetName
    VirtualNetwork = $vnet
}

$WESubnet = Get-AzVirtualNetworkSubnetConfig @getAzVirtualNetworkSubnetConfigSplat




$newAzNetworkInterfaceIpConfigSplat = @{
    Name                     = $WEIPConfigName
    Subnet                   = $WESubnet
    # Subnet                   = $WEVnet.Subnets[0].Id
    # PublicIpAddress          = $WEPIP.ID
    PublicIpAddress          = $WEPIP
    ApplicationSecurityGroup = $WEASG
    Primary                  = $true
}

$WEIPConfig1 = New-AzNetworkInterfaceIpConfig @newAzNetworkInterfaceIpConfigSplat



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
$rule1 = New-AzNetworkSecurityRuleConfig @newAzNetworkSecurityRuleConfigSplat




$newAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    Name              = $WENSGName
    # SecurityRules     = $rule1, $rule2
    SecurityRules     = $rule1
    Tag               = $WETags
}
$WENSG = New-AzNetworkSecurityGroup @newAzNetworkSecurityGroupSplat




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
$WENIC = New-AzNetworkInterface @newAzNetworkInterfaceSplat




$WEVMLocalAdminUser = Read-Host -Prompt 'Please enter a username to be created'
$WEVMLocalAdminPassword = Generate-Password -length 16; 
$WEVMLocalAdminSecurePassword = $WEVMLocalAdminPassword | ConvertTo-SecureString -Force -AsPlainText
; 
$WECredential = New-Object PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);





$newAzVMConfigSplat = @{
    VMName       = $WEVMName
    VMSize       = $WEVMSize
    Tags         = $WETags
    IdentityType = 'SystemAssigned'
}
$WEVirtualMachine = New-AzVMConfig @newAzVMConfigSplat




$setAzVMOperatingSystemSplat = @{
    VM               = $WEVirtualMachine
    Windows          = $true
    # Linux        = $true
    ComputerName     = $WEComputerName
    Credential       = $WECredential
    ProvisionVMAgent = $true
    # EnableAutoUpdate = $true
    
}
$WEVirtualMachine = Set-AzVMOperatingSystem @setAzVMOperatingSystemSplat




$addAzVMNetworkInterfaceSplat = @{
    VM = $WEVirtualMachine
    Id = $WENIC.Id
}
$WEVirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat



$setAzVMSourceImageSplat = @{
    VM             = $WEVirtualMachine
    # PublisherName = " Canonical"
    # Offer         = " 0001-com-ubuntu-server-focal"
    # Skus          = " 20_04-lts-gen2"
    # Version       = " latest"
    # publisherName = " MicrosoftWindowsDesktop"
    # offer         = " office-365"
    # Skus          = " 20h2-evd-o365pp"
    # version       = " latest"


    publisherName = " MicrosoftWindowsServer"
    offer         = " WindowsServer"
    Skus          = " 2022-datacenter-azure-edition-smalldisk"
    version       = " latest"



    #Operating System
    # publisherName = " MicrosoftWindowsDesktop"
    # offer = " office-365"
    # Skus = " 20h2-evd-o365pp"
    # version = " latest"
    # Caching = 'ReadWrite'
}


$WEVirtualMachine = Set-AzVMSourceImage @setAzVMSourceImageSplat




$setAzVMOSDiskSplat = @{
    VM           = $WEVirtualMachine
    Name         = $WEOSDiskName
    # VhdUri = $WEOSDiskUri
    # SourceImageUri = $WESourceImageUri
    Caching      = $WEOSDiskCaching
    CreateOption = $WEOSCreateOption
    # Windows = $true
    # DiskSizeInGB = '128'
    # StorageAccountType = 'Standard_LRS' //For HDD
}
$WEVirtualMachine = Set-AzVMOSDisk @setAzVMOSDiskSplat




; 
$newAzVMSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    VM                = $WEVirtualMachine
    Verbose           = $true
    Tag               = $WETags
}
New-AzVM @newAzVMSplat











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

Set-AzVMAutoShutdown @setAzVMAutoShutdownSplat





Write-Host 'The VM is now ready.... here is your login details'
Write-Host 'username:' $WEVMLocalAdminUser
Write-Host 'Password:' $WEVMLocalAdminPassword

Write-WELog " DNSName:' $WEDNSNameLabel'.$WELocationName.cloudapp.azure.com" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================