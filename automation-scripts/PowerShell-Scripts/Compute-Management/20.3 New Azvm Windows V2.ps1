<#
.SYNOPSIS
    We Enhanced 20.3 New Azvm Windows V2

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

$WEHelpers = "$WEPsScriptRoot\Helpers\"
Write-Host 'DNSName:' $WEDNSNameLabel


$WEErrorActionPreference = " Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$WEHelpers = " $WEPsScriptRoot\Helpers\"

Get-ChildItem -Path $WEHelpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }

$WELocationName = 'CanadaCentral'

$WEVMName = 'TeamViewer'
$WECustomerName = 'CanadaComputing'
$WEResourceGroupName = -join (" $WECustomerName", " _$WEVMName", " _RG")



$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss")
[hashtable]$WETags = @{

    " Autoshutown"     = 'ON'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"    = " $WECustomerName"
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Production'
    " Application"     = 'TeamViewer'  
    " Purpose"         = 'TeamViewer'
    " Uptime"          = '24/7'
    " Workload"        = 'WinSCP'
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

New-AzResourceGroup @newAzResourceGroupSplat














$WEComputerName = $WEVMName



$WEVMSize = " Standard_B2MS"
$WEOSDiskCaching = " ReadWrite"
$WEOSCreateOption = " FromImage"


$WEGUID = [guid]::NewGuid()
$WEOSDiskName = -join (" $WEVMName", " _OSDisk", " _1", " _$WEGUID")


$WEDNSNameLabel = -join (" $WEVMName", " DNS").ToLower() # mydnsname.westus.cloudapp.azure.com


$WENetworkName = -join (" $WEVMName", " _group-vnet")


$WENICPrefix = 'NIC1'
$WENICName = -join (" $WEVMName", " _$WENICPrefix").ToLower()
$WEIPConfigName = -join (" $WEVMName", " $WENICName", " _IPConfig1").ToLower()


$WEPublicIPAddressName = -join (" $WEVMName", " -ip")


$WESubnetName = -join (" $WEVMName", " -subnet")
$WESubnetAddressPrefix = " 10.0.0.0/24"
$WEVnetAddressPrefix = " 10.0.0.0/16"


$WENSGName = -join (" $WEVMName", " -nsg")


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
$WEPIP = New-AzPublicIpAddress @newAzPublicIpAddressSplat






$WESourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip").Content #Gets the public IP of the current machine
$WESourceAddressPrefixCIDR = -join (" $WESourceAddressPrefix", " /32")





$WEASGName = -join (" $WEVMName", " _ASG1")
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = " $WEResourceGroupName"
    Name              = " $WEASGName"
    Location          = " $WELocationName"
    Tag               = $WETags
}
$WEASG = New-AzApplicationSecurityGroup @newAzApplicationSecurityGroupSplat



$getAzVirtualNetworkSubnetConfigSplat = @{
    Name = $WESubnetName
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


$WEVMLocalAdminPassword = Generate-Password -length 16
$WEVMLocalAdminSecurePassword = $WEVMLocalAdminPassword | ConvertTo-SecureString -Force -AsPlainText
; 
$WECredential = New-Object PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);


$WECredential = Get-Credential


$newAzVMConfigSplat = @{
    VMName = $WEVMName
    VMSize = $WEVMSize
    Tags   = $WETags
    IdentityType = 'SystemAssigned'
}
$WEVirtualMachine = New-AzVMConfig @newAzVMConfigSplat


$setAzVMOperatingSystemSplat = @{
    VM           = $WEVirtualMachine
    Windows      = $true
    # Linux        = $true
    ComputerName = $WEComputerName
    Credential   = $WECredential
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
    VM            = $WEVirtualMachine
    # PublisherName = " Canonical"
    # Offer         = " 0001-com-ubuntu-server-focal"
    # Skus          = " 20_04-lts-gen2"
    # Version       = " latest"
    publisherName = " MicrosoftWindowsDesktop"
    offer         = " office-365"
    Skus          = " 20h2-evd-o365pp"
    version       = " latest"


    # publisherName = " MicrosoftWindowsServer"
    # offer         = " WindowsServer"
    # Skus          = " 2019-datacenter-gensecond"
    # version       = " latest"



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
    DiskSizeInGB = '128'
}
$WEVirtualMachine = Set-AzVMOSDisk @setAzVMOSDiskSplat


$newAzVMSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    VM                = $WEVirtualMachine
    Verbose           = $true
    Tag               = $WETags
}
New-AzVM @newAzVMSplat




$setAzVMExtensionSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Location = $WELocationName
    VMName = $WEVMName
    Name = " AADLoginForWindows"
    Publisher = " Microsoft.Azure.ActiveDirectory"
    ExtensionType = " AADLoginForWindows"
    TypeHandlerVersion = " 1.0"
    # SettingString = $WESettingsString
}
Set-AzVMExtension @setAzVMExtensionSplat




$WEUsersGroupName = " Azure VM - Standard User"

$WEObjectID = (Get-AzADGroup -SearchString $WEUsersGroupName).ID

$vmtype = (Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVMName).Type

New-AzRoleAssignment -ObjectId $WEObjectID -RoleDefinitionName 'Virtual Machine User Login' -ResourceGroupName $WEResourceGroupName -ResourceName $WEVMName -ResourceType $vmtype



$WEAdminsGroupName = " Azure VM - Admins"

$WEObjectID = (Get-AzADGroup -SearchString $WEAdminsGroupName).ID

$vmtype = (Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVMName).Type

New-AzRoleAssignment -ObjectId $WEObjectID -RoleDefinitionName 'Virtual Machine Administrator Login' -ResourceGroupName $WEResourceGroupName -ResourceName $WEVMName -ResourceType $vmtype



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
Write-Host 'DNSName:' $WEDNSNameLabel


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================