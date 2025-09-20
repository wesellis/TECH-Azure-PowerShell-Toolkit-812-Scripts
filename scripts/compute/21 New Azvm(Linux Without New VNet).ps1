#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create VM(Linux Without New VNet)

.DESCRIPTION
    Create VM(Linux Without New VNet) operation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
."$PSScriptRoot\13-Set-AzVMAutoShutdown.ps1"
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
." $PSScriptRoot\13-Set-AzVMAutoShutdown.ps1"
$LocationName = 'CanadaCentral'
$CustomerName = 'FGCHealth'
$VMName = 'Prod-Nifi1'
$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Autoshutown"       = 'OFF'
    "Createdby"         = 'Abdullah Ollivierre'
    "CustomerName"      = " $CustomerName"
    "DateTimeCreated"   = " $datetime"
    "Environment"       = 'Production'
    "Application"       = 'Apache Nifi'
    "Purpose"           = 'EDW Prod'
    "Uptime"            = '5 hours by 31 days'
    "Workload"          = 'Apache Nifi'
    "VMGenenetation"    = 'Gen2'
    "RebootCaution"     = 'Schedule a maintenance window first before rebooting'
    "VMSize"            = 'Standard_F8s_v2'
    "Location"          = " $LocationName"
    "Approved By"       = "Hamza Musaphir"
    "Approved On"       = "Friday Dec 11 2020"
    "Ticket ID"         = " 1515933"
    "CSP"               = "Canada Computing Inc."
    "Subscription Name" = "Microsoft Azure - FGC Production"
    "Subscription ID"   = " 3532a85c-c00a-4465-9b09-388248166360"
    "Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"
}
$newAzResourceGroupSplat = @{
    Name     = $ResourceGroupName
    Location = $LocationName
    Tag      = $Tags
}
New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
$ComputerName = $VMName
$VMSize = "Standard_F8s_v2"
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"
$GUID = [guid]::NewGuid()
$OSDiskName = -join (" $VMName" , "_OSDisk" , "_1" , "_$GUID" )
$DNSNameLabel = -join (" $VMName" , "DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com
$NICPrefix = 'NIC1'
$NICName = -join (" $VMName" , "_$NICPrefix" ).ToLower()
$IPConfigName = -join (" $VMName" , "$NICName" , "_IPConfig1" ).ToLower()
$PublicIPAddressName = -join (" $VMName" , "-ip" )
$SubnetName = -join (" $VMName" , "-subnet" )
$NSGName = -join (" $VMName" , "-nsg" )
$getAzVirtualNetworkSplat = @{
    Name = 'ProductionVNET'
}
$vnet = Get-AzVirtualNetwork -ErrorAction Stop @getAzVirtualNetworkSplat
$newAzPublicIpAddressSplat = @{
    Name              = $PublicIPAddressName
    DomainNameLabel   = $DNSNameLabel
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    # AllocationMethod  = 'Dynamic'
    AllocationMethod  = 'Static'
    # IpTag             = $ipTag
    Tag               = $Tags
}
$PIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat
$ASGName = -join (" $VMName" , "_ASG1" )
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = " $ResourceGroupName"
    Name              = " $ASGName"
    Location          = " $LocationName"
    Tag               = $Tags
}
$ASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat
$getAzVirtualNetworkSubnetConfigSplat = @{
    Name           = $SubnetName
    VirtualNetwork = $vnet
}
$Subnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat
$newAzNetworkInterfaceIpConfigSplat = @{
    Name                     = $IPConfigName
    Subnet                   = $Subnet
    # Subnet                   = $Vnet.Subnets[0].Id
    # PublicIpAddress          = $PIP.ID
    PublicIpAddress          = $PIP
    ApplicationSecurityGroup = $ASG
    Primary                  = $true
}
$IPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat
$newAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    Name              = $NSGName
    # SecurityRules     = $rule1, $rule2
    # SecurityRules     = $rule1
    Tag               = $Tags
}
$NSG = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat
$newAzNetworkInterfaceSplat = @{
    Name                   = $NICName
    ResourceGroupName      = $ResourceGroupName
    Location               = $LocationName
    # SubnetId                 = $Vnet.Subnets[0].Id
    # PublicIpAddressId        = $PIP.Id
    NetworkSecurityGroupId = $NSG.Id
    # ApplicationSecurityGroup = $ASG
    IpConfiguration        = $IPConfig1
    Tag                    = $Tags
}
$NIC = New-AzNetworkInterface -ErrorAction Stop @newAzNetworkInterfaceSplat
$Credential = Get-Credential -ErrorAction Stop
$newAzVMConfigSplat = @{
    VMName = $VMName
    VMSize = $VMSize
    Tags   = $Tags
}
$VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
$setAzVMOperatingSystemSplat = @{
    VM           = $VirtualMachine
    # Windows      = $true
    Linux        = $true
    ComputerName = $ComputerName
    Credential   = $Credential
    # ProvisionVMAgent = $true
    # EnableAutoUpdate = $true
}
$VirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat
$addAzVMNetworkInterfaceSplat = @{
    VM = $VirtualMachine
    Id = $NIC.Id
}
$VirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat
$setAzVMSourceImageSplat = @{
    VM            = $VirtualMachine
    PublisherName = "OpenLogic"
    Offer         = "CentOS"
    Skus          = " 8_2-gen2"
    Version       = " latest"
}
$VirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat
$setAzVMOSDiskSplat = @{
    VM           = $VirtualMachine
    Name         = $OSDiskName
    # VhdUri = $OSDiskUri
    # SourceImageUri = $SourceImageUri
    Caching      = $OSDiskCaching
    CreateOption = $OSCreateOption
    # Windows = $true
    DiskSizeInGB = '100'
};
$VirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat
$newAzVMSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    VM                = $VirtualMachine
    Verbose           = $true
    Tag               = $Tags
}
New-AzVM -ErrorAction Stop @newAzVMSplat


