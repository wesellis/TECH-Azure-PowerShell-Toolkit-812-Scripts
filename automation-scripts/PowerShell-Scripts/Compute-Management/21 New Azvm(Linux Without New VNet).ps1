#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    21 New Azvm(Linux Without New Vnet)

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 21 New Azvm(Linux Without New Vnet)

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


."$WEPSScriptRoot\13-Set-AzVMAutoShutdown.ps1"



$WEErrorActionPreference = " Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

." $WEPSScriptRoot\13-Set-AzVMAutoShutdown.ps1"

$WELocationName = 'CanadaCentral'
$WECustomerName = 'FGCHealth'
$WEVMName = 'Prod-Nifi1'
$WEResourceGroupName = -join (" $WECustomerName" , " _$WEVMName" , " _RG" )



$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"       = 'OFF'
    " Createdby"         = 'Abdullah Ollivierre'
    " CustomerName"      = " $WECustomerName"
    " DateTimeCreated"   = " $datetime"
    " Environment"       = 'Production'
    " Application"       = 'Apache Nifi'  
    " Purpose"           = 'EDW Prod'
    " Uptime"            = '5 hours by 31 days'
    " Workload"          = 'Apache Nifi'
    " VMGenenetation"    = 'Gen2'
    " RebootCaution"     = 'Schedule a maintenance window first before rebooting'
    " VMSize"            = 'Standard_F8s_v2'
    " Location"          = " $WELocationName"
    " Approved By"       = " Hamza Musaphir"
    " Approved On"       = " Friday Dec 11 2020"
    " Ticket ID"         = " 1515933"
    " CSP"               = " Canada Computing Inc."
    " Subscription Name" = " Microsoft Azure - FGC Production"
    " Subscription ID"   = " 3532a85c-c00a-4465-9b09-388248166360"
    " Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"

}


$newAzResourceGroupSplat = @{
    Name     = $WEResourceGroupName
    Location = $WELocationName
    Tag      = $WETags
}

New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat














$WEComputerName = $WEVMName



$WEVMSize = " Standard_F8s_v2"
$WEOSDiskCaching = " ReadWrite"
$WEOSCreateOption = " FromImage"


$WEGUID = [guid]::NewGuid()
$WEOSDiskName = -join (" $WEVMName" , " _OSDisk" , " _1" , " _$WEGUID" )


$WEDNSNameLabel = -join (" $WEVMName" , " DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com




$WENICPrefix = 'NIC1'
$WENICName = -join (" $WEVMName" , " _$WENICPrefix" ).ToLower()
$WEIPConfigName = -join (" $WEVMName" , " $WENICName" , " _IPConfig1" ).ToLower()


$WEPublicIPAddressName = -join (" $WEVMName" , " -ip" )


$WESubnetName = -join (" $WEVMName" , " -subnet" )



$WENSGName = -join (" $WEVMName" , " -nsg" )





$getAzVirtualNetworkSplat = @{
    Name = 'ProductionVNET'
}

$vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat






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










$WEASGName = -join (" $WEVMName" , " _ASG1" )
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = " $WEResourceGroupName"
    Name              = " $WEASGName"
    Location          = " $WELocationName"
    Tag               = $WETags
}
$WEASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat



$getAzVirtualNetworkSubnetConfigSplat = @{
    Name           = $WESubnetName
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




$newAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Location          = $WELocationName
    Name              = $WENSGName
    # SecurityRules     = $rule1, $rule2
    # SecurityRules     = $rule1
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
    # Windows      = $true
    Linux        = $true
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
    PublisherName = " OpenLogic"
    Offer         = " CentOS"
    Skus          = " 8_2-gen2"
    Version       = " latest"
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
    DiskSizeInGB = '100'
}; 
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









# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
