<#
.SYNOPSIS
    20.3 New Iaacazvm

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
    We Enhanced 20.3 New Iaacazvm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


function WE-New-IaaCAzVM {



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }

function WE-New-IaaCAzVM {
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

    New-AzResourceGroup @newAzResourceGroupSplat

    #Getting the Existing VNET. We put our VMs in the same VNET as much as possible, so we do not have to create new bastions and new VPN gateways for each VM
    $getAzVirtualNetworkSplat = @{
        Name = $WEVnetName
    }
    $vnet = Get-AzVirtualNetwork @getAzVirtualNetworkSplat

    #Getting the Existing Subnet
    $getAzVirtualNetworkSubnetConfigSplat = @{
        VirtualNetwork = $vnet
        Name           = $WESubnetName
    }
    $WEVMsubnet = Get-AzVirtualNetworkSubnetConfig @getAzVirtualNetworkSubnetConfigSplat

    #Creating the PublicIP for the VM
    $newAzPublicIpAddressSplat = @{
        Name              = $WEPublicIPAddressName
        DomainNameLabel   = $WEDNSNameLabel
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        AllocationMethod  = $WEPublicIPAllocation
        Tag               = $WETags
    }
    $WEPIP = New-AzPublicIpAddress @newAzPublicIpAddressSplat

    #Creating the Application Security Group
    $newAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = " $WEResourceGroupName"
        Name              = " $WEASGName"
        Location          = " $WELocationName"
        Tag               = $WETags
    }
    $WEASG = New-AzApplicationSecurityGroup @newAzApplicationSecurityGroupSplat

    $newAzNetworkInterfaceIpConfigSplat = @{
        Name                     = $WEIPConfigName
        Subnet                   = $WEVMSubnet
        PublicIpAddress          = $WEPIP
        ApplicationSecurityGroup = $WEASG
        Primary                  = $true
    }
    $WEIPConfig1 = New-AzNetworkInterfaceIpConfig @newAzNetworkInterfaceIpConfigSplat

    $newAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        Name              = $WENSGName
        Tag               = $WETags
    }
    $WENSG = New-AzNetworkSecurityGroup @newAzNetworkSecurityGroupSplat

    #Creating the NIC for the VM
    $newAzNetworkInterfaceSplat = @{
        Name                   = $WENICName
        ResourceGroupName      = $WEResourceGroupName
        Location               = $WELocationName
        NetworkSecurityGroupId = $WENSG.Id
        IpConfiguration        = $WEIPConfig1
        Tag                    = $WETags
    
    }
    $WENIC = New-AzNetworkInterface @newAzNetworkInterfaceSplat

    #Creating the Cred Object for the VM
    $WECredential = Get-Credential

    #Creating the VM Config Object for the VM
    $newAzVMConfigSplat = @{
        VMName = $WEVMName
        VMSize = $WEVMSize
        Tags   = $WETags
    }
    $WEVirtualMachine = New-AzVMConfig @newAzVMConfigSplat

    #Creating the OS Object for the VM
    $setAzVMOperatingSystemSplat = @{
        VM           = $WEVirtualMachine
        Linux        = $true
        ComputerName = $WEComputerName
        Credential   = $WECredential
    }
    $WEVirtualMachine = Set-AzVMOperatingSystem @setAzVMOperatingSystemSplat

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
    $WEVirtualMachine = Set-AzVMSourceImage @setAzVMSourceImageSplat

    #Setting the VM OS Disk to the VM
    $setAzVMOSDiskSplat = @{
        VM           = $WEVirtualMachine
        Name         = $WEOSDiskName
        Caching      = $WEOSDiskCaching
        CreateOption = $WEOSCreateOption
        DiskSizeInGB = $WEDiskSizeInGB
    }
   ;  $WEVirtualMachine = Set-AzVMOSDisk @setAzVMOSDiskSplat

    #Creating the VM
   ;  $newAzVMSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        VM                = $WEVirtualMachine
        Verbose           = $true
        Tag               = $WETags
    }
    New-AzVM @newAzVMSplat
    
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
