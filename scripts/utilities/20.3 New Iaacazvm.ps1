#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    New Iaacazvm

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
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
    $VMSize,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $OSDiskCaching,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $OSCreateOption,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $GUID,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $OSDiskName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ASGName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $NSGName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $DNSNameLabel,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $NICPrefix,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $NICName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $IPConfigName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $PublicIPAddressName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $VnetName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubnetName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $PublicIPAllocation,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $PublisherName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Offer,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Skus,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Version,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $DiskSizeInGB
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
    $PIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat
    $NewAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = " $ResourceGroupName"
        Name              = " $ASGName"
        Location          = " $LocationName"
        Tag               = $Tags
    }
    $ASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat
    $NewAzNetworkInterfaceIpConfigSplat = @{
        Name                     = $IPConfigName
        Subnet                   = $VMSubnet
        PublicIpAddress          = $PIP
        ApplicationSecurityGroup = $ASG
        Primary                  = $true
    }
    $IPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat
    $NewAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        Name              = $NSGName
        Tag               = $Tags
    }
    $NSG = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat
    $NewAzNetworkInterfaceSplat = @{
        Name                   = $NICName
        ResourceGroupName      = $ResourceGroupName
        Location               = $LocationName
        NetworkSecurityGroupId = $NSG.Id
        IpConfiguration        = $IPConfig1
        Tag                    = $Tags
    }
    $NIC = New-AzNetworkInterface -ErrorAction Stop @newAzNetworkInterfaceSplat
    $Credential = Get-Credential -ErrorAction Stop
    $NewAzVMConfigSplat = @{
        VMName = $VMName
        VMSize = $VMSize
        Tags   = $Tags
    }
    $VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
    $SetAzVMOperatingSystemSplat = @{
        VM           = $VirtualMachine
        Linux        = $true
        ComputerName = $ComputerName
        Credential   = $Credential
    }
    $VirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat
    $AddAzVMNetworkInterfaceSplat = @{
        VM = $VirtualMachine
        Id = $NIC.Id
    }
    $VirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat
    $SetAzVMSourceImageSplat = @{
        VM            = $VirtualMachine
        PublisherName = $PublisherName
        Offer         = $Offer
        Skus          = $Skus
        Version       = $Version
    }
    $VirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat
    $SetAzVMOSDiskSplat = @{
        VM           = $VirtualMachine
        Name         = $OSDiskName
        Caching      = $OSDiskCaching
        CreateOption = $OSCreateOption
        DiskSizeInGB = $DiskSizeInGB
    }
    $VirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat
    $NewAzVMSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        VM                = $VirtualMachine
        Verbose           = $true
        Tag               = $Tags
    }
    New-AzVM -ErrorAction Stop @newAzVMSplat
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
