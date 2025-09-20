<#
.SYNOPSIS
    Create VM(Winserver Without New VNet)

.DESCRIPTION
    Create VM(Winserver Without New VNet) operation
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function New-IaaCAzVM -ErrorAction Stop {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$LocationName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$CustomerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$VMName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ResourceGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$datetime,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$Tags,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ComputerName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VMSize,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OSDiskCaching,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OSCreateOption,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GUID,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OSDiskName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ASGName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$NSGName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DNSNameLabel,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$NICPrefix,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$NICName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$IPConfigName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PublicIPAddressName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VnetName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubnetName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PublicIPAllocation,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PublisherName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Offer,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Skus,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Version,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DiskSizeInGB
    )
    #Creating the Resource Group Name
    $newAzResourceGroupSplat = @{
        Name     = $ResourceGroupName
        Location = $LocationName
        Tag      = $Tags
    }
    New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
    #Getting the Existing VNET. We put our VMs in the same VNET as much as possible, so we do not have to create new bastions and new VPN gateways for each VM
    $getAzVirtualNetworkSplat = @{
        Name = $VnetName
    }
    $vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat
    #Getting the Existing Subnet
    $getAzVirtualNetworkSubnetConfigSplat = @{
        VirtualNetwork = $vnet
        Name           = $SubnetName
    }
    $VMsubnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat
    #Creating the PublicIP for the VM
    $newAzPublicIpAddressSplat = @{
        Name              = $PublicIPAddressName
        DomainNameLabel   = $DNSNameLabel
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        AllocationMethod  = $PublicIPAllocation
        Tag               = $Tags
    }
    $PIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat
    #Creating the Application Security Group
    $newAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = " $ResourceGroupName"
        Name              = " $ASGName"
        Location          = " $LocationName"
        Tag               = $Tags
    }
    $ASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat
    $newAzNetworkInterfaceIpConfigSplat = @{
        Name                     = $IPConfigName
        Subnet                   = $VMSubnet
        PublicIpAddress          = $PIP
        ApplicationSecurityGroup = $ASG
        Primary                  = $true
    }
    $IPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat
    $newAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        Name              = $NSGName
        Tag               = $Tags
    }
    $NSG = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat
    #Creating the NIC for the VM
    $newAzNetworkInterfaceSplat = @{
        Name                   = $NICName
        ResourceGroupName      = $ResourceGroupName
        Location               = $LocationName
        NetworkSecurityGroupId = $NSG.Id
        IpConfiguration        = $IPConfig1
        Tag                    = $Tags
    }
    $NIC = New-AzNetworkInterface -ErrorAction Stop @newAzNetworkInterfaceSplat
    #Creating the Cred Object for the VM
    $Credential = Get-Credential -ErrorAction Stop
    #Creating the VM Config Object for the VM
    $newAzVMConfigSplat = @{
        VMName = $VMName
        VMSize = $VMSize
        Tags   = $Tags
    }
    $VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
    #Creating the OS Object for the VM
    $setAzVMOperatingSystemSplat = @{
        VM           = $VirtualMachine
        Windows        = $true
        ComputerName = $ComputerName
        Credential   = $Credential
    }
    $VirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat
    #Adding the NIC to the VM
    $addAzVMNetworkInterfaceSplat = @{
        VM = $VirtualMachine
        Id = $NIC.Id
    }
    $VirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat
    $setAzVMSourceImageSplat = @{
        VM            = $VirtualMachine
        PublisherName = $PublisherName
        Offer         = $Offer
        Skus          = $Skus
        Version       = $Version
    }
    $VirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat
    #Setting the VM OS Disk to the VM
    $setAzVMOSDiskSplat = @{
        VM           = $VirtualMachine
        Name         = $OSDiskName
        Caching      = $OSDiskCaching
        CreateOption = $OSCreateOption
        DiskSizeInGB = $DiskSizeInGB
    }
    $VirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat
    #Creating the VM
    $newAzVMSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        VM                = $VirtualMachine
        Verbose           = $true
        Tag               = $Tags
    }
    New-AzVM -ErrorAction Stop @newAzVMSplat
}
$LocationName = 'CanadaCentral'
$CustomerName = 'CanadaComputing'
$VMName = 'VEEAM-CCGW1'
$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
$ComputerName = $VMName
$VMSize = "Standard_B2MS"
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"
$GUID = [guid]::NewGuid()
$OSDiskName = -join (" $VMName" , "_OSDisk" , "_1" , "_$GUID" )
$ASGName = -join (" $VMName" , "_ASG1" )
$NSGName = -join (" $VMName" , "-nsg" )
$DNSNameLabel = -join (" $VMName" , "DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com
$NICPrefix = 'NIC1'
$NICName = -join (" $VMName" , "_$NICPrefix" ).ToLower()
$IPConfigName = -join (" $VMName" , "$NICName" , "_IPConfig1" ).ToLower()
$PublicIPAddressName = -join (" $VMName" , "-ip" )
$VnetName = 'VEEAM1-POC_group-vnet'
$SubnetName = 'VEEAM1-POC-subnet'
$PublicIPAllocation = 'Static'
$PublisherName = "MicrosoftWindowsServer"
$Offer = "WindowsServer"
$Skus = " 2019-datacenter-gensecond"
$Version = " latest"
$DiskSizeInGB = '127'
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Autoshutown"       = 'OFF'
    "Createdby"         = 'Abdullah Ollivierre'
    "CustomerName"      = " $CustomerName"
    "DateTimeCreated"   = " $datetime"
    "Environment"       = 'Dev'
    "Application"       = ''
    "Purpose"           = 'setting up Veeam Cloud Connect Gateway'
    "Uptime"            = '16/7'
    "Workload"          = 'Veeam Cloud Connect Gateway to allow over the cloud comm with no VPN'
    "VMGenenetation"    = 'Gen2'
    "RebootCaution"     = 'Reboot as needed'
    "VMSize"            = " $VMSize"
    "Location"          = " $LocationName"
    "Requested By"      = 'Michael.p'
    "Approved By"       = "Abdullah Ollivierre"
    "Approved On"       = "Tue July 27 2021"
    "Ticket ID"         = ""
    "CSP"               = "Canada Computing Inc."
    "Subscription Name" = "Microsoft Azure"
    "Subscription ID"   = ""
    "Tenant ID"         = ""
}
$NewIaaCAzVMSplat = @{
    LocationName        = $LocationName
    CustomerName        = $CustomerName
    VMName              = $VMName
    ResourceGroupName   = $ResourceGroupName
    #Creating the Tag Hashtable for the VM
    datetime            = $datetime
    Tags                = $Tags
    ##VM
    ComputerName        = $ComputerName
    VMSize              = $VMSize
    OSDiskCaching       = $OSDiskCaching
    OSCreateOption      = $OSCreateOption
    GUID                = $GUID
    OSDiskName          = $OSDiskName
    #ASG
    ASGName             = $ASGName
    #Defining the NSG name
    NSGName             = $NSGName
    ## Networking
    DNSNameLabel        = $DNSNameLabel   # mydnsname.westus.cloudapp.azure.com
    NICPrefix           = $NICPrefix
    NICName             = $NICName
    IPConfigName        = $IPConfigName
    PublicIPAddressName = $PublicIPAddressName
    VnetName            = $VnetName
    SubnetName          = $SubnetName
    PublicIPAllocation  = $PublicIPAllocation
    ##Operating System
    PublisherName       = $PublisherName
    Offer               = $Offer
    Skus                = $Skus
    Version             = $Version
    ##Disk
    DiskSizeInGB        = $DiskSizeInGB
}
New-IaaCAzVM -ErrorAction Stop @NewIaaCAzVMSplat
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

