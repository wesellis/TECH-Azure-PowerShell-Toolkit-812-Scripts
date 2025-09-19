#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    22 New Azvm(Win10 Without New Vnet)

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
    We Enhanced 22 New Azvm(Win10 Without New Vnet)
try {
    # Main script execution
.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
function WE-New-IaaCAzVM -ErrorAction Stop {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WELocationName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WECustomerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WEVMName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WEResourceGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$datetime,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$WETags,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$WEComputerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVMSize,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOSDiskCaching,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOSCreateOption,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGUID,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOSDiskName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEASGName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WENSGName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDNSNameLabel,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WENICPrefix,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WENICName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEIPConfigName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPublicIPAddressName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVnetName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubnetName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPublicIPAllocation,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPublisherName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOffer,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESkus,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVersion,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$WEDiskSizeInGB

    )

    #Creating the Resource Group Name
    $newAzResourceGroupSplat = @{
        Name     = $WEResourceGroupName
        Location = $WELocationName
        Tag      = $WETags
    }

    New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat

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
    $newAzPublicIpAddressSplat = @{
        Name              = $WEPublicIPAddressName
        DomainNameLabel   = $WEDNSNameLabel
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        AllocationMethod  = $WEPublicIPAllocation
        Tag               = $WETags
    }
    $WEPIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat

    #Creating the Application Security Group
    $newAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = " $WEResourceGroupName"
        Name              = " $WEASGName"
        Location          = " $WELocationName"
        Tag               = $WETags
    }
    $WEASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat

    $newAzNetworkInterfaceIpConfigSplat = @{
        Name                     = $WEIPConfigName
        Subnet                   = $WEVMSubnet
        PublicIpAddress          = $WEPIP
        ApplicationSecurityGroup = $WEASG
        Primary                  = $true
    }
    $WEIPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat

    $newAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        Name              = $WENSGName
        Tag               = $WETags
    }
    $WENSG = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat

    #Creating the NIC for the VM
    $newAzNetworkInterfaceSplat = @{
        Name                   = $WENICName
        ResourceGroupName      = $WEResourceGroupName
        Location               = $WELocationName
        NetworkSecurityGroupId = $WENSG.Id
        IpConfiguration        = $WEIPConfig1
        Tag                    = $WETags
    
    }
    $WENIC = New-AzNetworkInterface -ErrorAction Stop @newAzNetworkInterfaceSplat

    #Creating the Cred Object for the VM
    $WECredential = Get-Credential -ErrorAction Stop

    #Creating the VM Config Object for the VM
    $newAzVMConfigSplat = @{
        VMName = $WEVMName
        VMSize = $WEVMSize
        Tags   = $WETags
    }
    $WEVirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat

    #Creating the OS Object for the VM
    $setAzVMOperatingSystemSplat = @{
        VM           = $WEVirtualMachine
        Windows        = $true
        ComputerName = $WEComputerName
        Credential   = $WECredential
    }
    $WEVirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat

    #Adding the NIC to the VM
    $addAzVMNetworkInterfaceSplat = @{
        VM = $WEVirtualMachine
        Id = $WENIC.Id
    }
    $WEVirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat

    $setAzVMSourceImageSplat = @{
        VM            = $WEVirtualMachine
        PublisherName = $WEPublisherName
        Offer         = $WEOffer
        Skus          = $WESkus
        Version       = $WEVersion
    
    }
    $WEVirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat

    #Setting the VM OS Disk to the VM
    $setAzVMOSDiskSplat = @{
        VM           = $WEVirtualMachine
        Name         = $WEOSDiskName
        Caching      = $WEOSDiskCaching
        CreateOption = $WEOSCreateOption
        DiskSizeInGB = $WEDiskSizeInGB
    }
    $WEVirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat

    #Creating the VM
    $newAzVMSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        VM                = $WEVirtualMachine
        Verbose           = $true
        Tag               = $WETags
    }
    New-AzVM -ErrorAction Stop @newAzVMSplat
    
}




$WELocationName = 'CanadaCentral'
$WECustomerName = 'CanadaComputing'
$WEVMName = 'Client9'
$WEResourceGroupName = -join (" $WECustomerName" , " _$WEVMName" , " _RG" )



$WEComputerName = $WEVMName
$WEVMSize = " Standard_B2MS"
$WEOSDiskCaching = " ReadWrite"
$WEOSCreateOption = " FromImage"
$WEGUID = [guid]::NewGuid()
$WEOSDiskName = -join (" $WEVMName" , " _OSDisk" , " _1" , " _$WEGUID" )


$WEASGName = -join (" $WEVMName" , " _ASG1" )


$WENSGName = -join (" $WEVMName" , " -nsg" )


$WEDNSNameLabel = -join (" $WEVMName" , " DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com
$WENICPrefix = 'NIC1'
$WENICName = -join (" $WEVMName" , " _$WENICPrefix" ).ToLower()
$WEIPConfigName = -join (" $WEVMName" , " $WENICName" , " _IPConfig1" ).ToLower()
$WEPublicIPAddressName = -join (" $WEVMName" , " -ip" )
$WEVnetName = 'DC1_group-vnet'
$WESubnetName = 'DC1-subnet'
$WEPublicIPAllocation = 'Dynamic'



$publisherName = " MicrosoftWindowsDesktop"
$offer = " office-365"
$WESkus = " 20h2-evd-o365pp"
$version = " latest"


$WEDiskSizeInGB = '127'


; 
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"       = 'OFF'
    " Createdby"         = 'Abdullah Ollivierre'
    " CustomerName"      = " $WECustomerName"
    " DateTimeCreated"   = " $datetime"
    " Environment"       = 'Production'
    " Application"       = 'WindowsADTesting'  
    " Purpose"           = 'WindowsADTesting'
    " Uptime"            = '730 hrs'
    " Workload"          = 'WindowsADTesting'
    " VMGenenetation"    = 'Gen2'
    " RebootCaution"     = 'Schedule a maintenance window first before rebooting'
    " VMSize"            = " $WEVMSize"
    " Location"          = " $WELocationName"
    " CSP"               = " Canada Computing Inc."

}

; 
$WENewIaaCAzVMSplat = @{

    LocationName        = $WELocationName
    CustomerName        = $WECustomerName 
    VMName              = $WEVMName  
    ResourceGroupName   = $WEResourceGroupName
        
    #Creating the Tag Hashtable for the VM
    datetime            = $datetime
    Tags                = $WETags 
        
        
    ##VM
    ComputerName        = $WEComputerName
    VMSize              = $WEVMSize
    OSDiskCaching       = $WEOSDiskCaching
    OSCreateOption      = $WEOSCreateOption
    GUID                = $WEGUID
    OSDiskName          = $WEOSDiskName
        
    #ASG
    ASGName             = $WEASGName 
        
    #Defining the NSG name
    NSGName             = $WENSGName  
        
    ## Networking
    DNSNameLabel        = $WEDNSNameLabel   # mydnsname.westus.cloudapp.azure.com
    NICPrefix           = $WENICPrefix 
    NICName             = $WENICName
    IPConfigName        = $WEIPConfigName 
    PublicIPAddressName = $WEPublicIPAddressName
    VnetName            = $WEVnetName
    SubnetName          = $WESubnetName
    PublicIPAllocation  = $WEPublicIPAllocation
        
        
    ##Operating System
    PublisherName       = $WEPublisherName
    Offer               = $WEOffer 
    Skus                = $WESkus  
    Version             = $WEVersion 
        
    ##Disk
    DiskSizeInGB        = $WEDiskSizeInGB

}
New-IaaCAzVM -ErrorAction Stop @NewIaaCAzVMSplat





} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
