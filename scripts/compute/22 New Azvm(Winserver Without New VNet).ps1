#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create VM(Winserver Without New VNet)

.DESCRIPTION
    Create VM(Winserver Without New VNet) operation


    Author: Wes Ellis (wes@wesellis.com)
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function New-IaaCAzVM -ErrorAction Stop {
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
    $NewAzResourceGroupSplat = @{
        Name     = $ResourceGroupName
        Location = $LocationName
        Tag      = $Tags
    }
    New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
    $GetAzVirtualNetworkSplat = @{
        Name = $VnetName
    }
    $vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat
    $GetAzVirtualNetworkSubnetConfigSplat = @{
        VirtualNetwork = $vnet
        Name           = $SubnetName
    }
    $VMsubnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat
    $NewAzPublicIpAddressSplat = @{
        Name              = $PublicIPAddressName
        DomainNameLabel   = $DNSNameLabel
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        AllocationMethod  = $PublicIPAllocation
        Tag               = $Tags
    }
    [string]$PIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat
    $NewAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = " $ResourceGroupName"
        Name              = " $ASGName"
        Location          = " $LocationName"
        Tag               = $Tags
    }
    [string]$ASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat
    $NewAzNetworkInterfaceIpConfigSplat = @{
        Name                     = $IPConfigName
        Subnet                   = $VMSubnet
        PublicIpAddress          = $PIP
        ApplicationSecurityGroup = $ASG
        Primary                  = $true
    }
    [string]$IPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat
    $NewAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        Name              = $NSGName
        Tag               = $Tags
    }
    [string]$NSG = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat
    $NewAzNetworkInterfaceSplat = @{
        Name                   = $NICName
        ResourceGroupName      = $ResourceGroupName
        Location               = $LocationName
        NetworkSecurityGroupId = $NSG.Id
        IpConfiguration        = $IPConfig1
        Tag                    = $Tags
    }
    [string]$NIC = New-AzNetworkInterface -ErrorAction Stop @newAzNetworkInterfaceSplat
    $Credential = Get-Credential -ErrorAction Stop
    $NewAzVMConfigSplat = @{
        VMName = $VMName
        VMSize = $VMSize
        Tags   = $Tags
    }
    [string]$VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
    $SetAzVMOperatingSystemSplat = @{
        VM           = $VirtualMachine
        Windows        = $true
        ComputerName = $ComputerName
        Credential   = $Credential
    }
    [string]$VirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat
    $AddAzVMNetworkInterfaceSplat = @{
        VM = $VirtualMachine
        Id = $NIC.Id
    }
    [string]$VirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat
    $SetAzVMSourceImageSplat = @{
        VM            = $VirtualMachine
        PublisherName = $PublisherName
        Offer         = $Offer
        Skus          = $Skus
        Version       = $Version
    }
    [string]$VirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat
    $SetAzVMOSDiskSplat = @{
        VM           = $VirtualMachine
        Name         = $OSDiskName
        Caching      = $OSDiskCaching
        CreateOption = $OSCreateOption
        DiskSizeInGB = $DiskSizeInGB
    }
    [string]$VirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat
    $NewAzVMSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        VM                = $VirtualMachine
        Verbose           = $true
        Tag               = $Tags
    }
    New-AzVM -ErrorAction Stop @newAzVMSplat
}
    [string]$LocationName = 'CanadaCentral'
    [string]$CustomerName = 'CanadaComputing'
    [string]$VMName = 'VEEAM-CCGW1'
    [string]$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
    [string]$ComputerName = $VMName
    [string]$VMSize = "Standard_B2MS"
    [string]$OSDiskCaching = "ReadWrite"
    [string]$OSCreateOption = "FromImage"
    [string]$GUID = [guid]::NewGuid()
    [string]$OSDiskName = -join (" $VMName" , "_OSDisk" , "_1" , "_$GUID" )
    [string]$ASGName = -join (" $VMName" , "_ASG1" )
    [string]$NSGName = -join (" $VMName" , "-nsg" )
    [string]$DNSNameLabel = -join (" $VMName" , "DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com
    [string]$NICPrefix = 'NIC1'
    [string]$NICName = -join (" $VMName" , "_$NICPrefix" ).ToLower()
    [string]$IPConfigName = -join (" $VMName" , "$NICName" , "_IPConfig1" ).ToLower()
    [string]$PublicIPAddressName = -join (" $VMName" , "-ip" )
    [string]$VnetName = 'VEEAM1-POC_group-vnet'
    [string]$SubnetName = 'VEEAM1-POC-subnet'
    [string]$PublicIPAllocation = 'Static'
    [string]$PublisherName = "MicrosoftWindowsServer"
    [string]$Offer = "WindowsServer"
    [string]$Skus = " 2019-datacenter-gensecond"
    [string]$Version = " latest"
    [string]$DiskSizeInGB = '127'
    [string]$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
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
    datetime            = $datetime
    Tags                = $Tags
    ComputerName        = $ComputerName
    VMSize              = $VMSize
    OSDiskCaching       = $OSDiskCaching
    OSCreateOption      = $OSCreateOption
    GUID                = $GUID
    OSDiskName          = $OSDiskName
    ASGName             = $ASGName
    NSGName             = $NSGName
    DNSNameLabel        = $DNSNameLabel
    NICPrefix           = $NICPrefix
    NICName             = $NICName
    IPConfigName        = $IPConfigName
    PublicIPAddressName = $PublicIPAddressName
    VnetName            = $VnetName
    SubnetName          = $SubnetName
    PublicIPAllocation  = $PublicIPAllocation
    PublisherName       = $PublisherName
    Offer               = $Offer
    Skus                = $Skus
    Version             = $Version
    DiskSizeInGB        = $DiskSizeInGB
}
New-IaaCAzVM -ErrorAction Stop @NewIaaCAzVMSplat
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
