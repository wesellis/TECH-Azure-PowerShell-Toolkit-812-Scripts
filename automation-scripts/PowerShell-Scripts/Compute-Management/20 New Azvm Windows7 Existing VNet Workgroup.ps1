<#
.SYNOPSIS
    20 New Azvm Windows7 Existing Vnet Workgroup

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
    We Enhanced 20 New Azvm Windows7 Existing Vnet Workgroup

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



$WELocationName = 'CanadaCentral'

$WECustomerName = 'CCI'
$WEVMName = 'Win7'
$WECustomerName = 'CanadaComputing'
$WEResourceGroupName = -join (" $WECustomerName" , " _$WEVMName" , " _RG" )



$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"     = 'ON'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"    = " $WECustomerName"
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Production'
    " Application"     = 'Oultook'  
    " Purpose"         = 'Mailbox Migration using Exchange Hybrid'
    " Uptime"          = '24/7'
    " Workload"        = 'Outlook'
    " RebootCaution"   = 'Schedule a window first before rebooting'
    " VMSize"          = 'B2MS'
    " Location"        = " $WELocationName"
    " Approved By"     = " Abdullah Ollivierre"
    " Approved On"     = ""

}




$newAzResourceGroupSplat = @{
    Name     = $WEResourceGroupName
    Location = $WELocationName
    Tag      = $WETags
}


New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat














$WEComputerName = $WEVMName



$WEVMSize = " Standard_B2MS"
$WEOSDiskCaching = " ReadWrite"
$WEOSCreateOption = " FromImage"


$WEGUID = [guid]::NewGuid()
$WEOSDiskName = -join (" $WEVMName" , " _OSDisk" , " _1" , " _$WEGUID" )



$WEDNSNameLabel = -join (" $WEVMName" , " DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com




$WENICPrefix = 'NIC1'
$WENICName = -join (" $WEVMName" , " _$WENICPrefix" ).ToLower()
$WEIPConfigName = -join (" $WEVMName" , " $WENICName" , " _IPConfig1" ).ToLower()


$WEPublicIPAddressName = -join (" $WEVMName" , " -ip" )



$WEVnetName = 'DC01_group-vnet'
$WESubnetName = 'DC01-subnet'


$WEPublicIPAllocation = 'Dynamic'


$WENSGName = -join (" $WEVMName" , " -nsg" )



    #Getting the Existing VNET. We put our VMs in the same VNET as much as possible, so we do not have to create new bastions and new VPN gateways for each VM
    $getAzVirtualNetworkSplat = @{
        Name = $WEVnetName
    }
    $vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat

    #Getting the Existing Subnet
    $getAzVirtualNetworkSubnetConfigSplat = @{
        VirtualNetwork = $vnet
        Name           = $WESubnetName
    }
    $WEVMsubnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat

    #Creating the PublicIP for the VM
    # $newAzPublicIpAddressSplat = @{
    #     Name              = $WEPublicIPAddressName
    #     DomainNameLabel   = $WEDNSNameLabel
    #     ResourceGroupName = $WEResourceGroupName
    #     Location          = $WELocationName
    #     AllocationMethod  = $WEPublicIPAllocation
    #     Tag               = $WETags
    # }
    # $WEPIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat








    #Creating the PublicIP for the VM
    $newAzPublicIpAddressSplat = @{
        Name              = $WEPublicIPAddressName
        DomainNameLabel   = $WEDNSNameLabel
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        AllocationMethod  = $WEPublicIPAllocation
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



    #Getting the Existing Subnet
    $getAzVirtualNetworkSubnetConfigSplat = @{
        VirtualNetwork = $vnet
        Name           = $WESubnetName
    }
    $WEVMsubnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat




$newAzNetworkInterfaceIpConfigSplat = @{
    Name                     = $WEIPConfigName
    Subnet                   = $WEVMSubnet
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




$WEVMLocalAdminUser = Read-Host -Prompt 'Please enter a username to be created'
$WEVMLocalAdminPassword = Generate-Password -length 16; 
$WEVMLocalAdminSecurePassword = $WEVMLocalAdminPassword | ConvertTo-SecureString -Force -AsPlainText
; 
$WECredential = New-Object -ErrorAction Stop PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);





$newAzVMConfigSplat = @{
    VMName       = $WEVMName
    VMSize       = $WEVMSize
    Tags         = $WETags
    # IdentityType = 'SystemAssigned'
}
$WEVirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat




$setAzVMOperatingSystemSplat = @{
    VM               = $WEVirtualMachine
    Windows          = $true
    # Linux        = $true
    ComputerName     = $WEComputerName
    Credential       = $WECredential
    ProvisionVMAgent = $true
    # EnableAutoUpdate = $true
    
}
$WEVirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat




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


    # publisherName = " MicrosoftWindowsServer"
    # offer         = " WindowsServer"
    # Skus          = " 2019-datacenter-gensecond"
    # version       = " latest"



    ##Operating System
    publisherName = " microsoftwindowsdesktop"
    offer         = " windows-7"
    Skus          = " win7-enterprise"
    version       = " latest"
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





Write-Information \'The VM is now ready.... here is your login details\'
Write-Information \'username:\' $WEVMLocalAdminUser
Write-Information \'Password:\' $WEVMLocalAdminPassword
Write-Information \'DNSName:\' $WEDNSNameLabel'.canadacentral.cloudapp.azure.com'



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================