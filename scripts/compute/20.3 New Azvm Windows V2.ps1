#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create Windows VM V2

.DESCRIPTION
    Deploy Windows virtual machine v2


    Author: Wes Ellis (wes@wesellis.com)
#>
$Helpers = "$PsScriptRoot\Helpers\"
Write-Information \'DNSName:\' $DNSNameLabel
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$Helpers = " $PsScriptRoot\Helpers\"
Get-ChildItem -Path $Helpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }
$LocationName = 'CanadaCentral'
$VMName = 'TeamViewer'
$CustomerName = 'CanadaComputing'
$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Autoshutown"     = 'ON'
    "Createdby"       = 'Abdullah Ollivierre'
    "CustomerName"    = " $CustomerName"
    "DateTimeCreated" = " $datetime"
    "Environment"     = 'Production'
    "Application"     = 'TeamViewer'
    "Purpose"         = 'TeamViewer'
    "Uptime"          = '24/7'
    "Workload"        = 'WinSCP'
    "RebootCaution"   = 'Schedule a window first before rebooting'
    "VMSize"          = 'B2MS'
    "Location"        = " $LocationName"
    "Approved By"     = "Abdullah Ollivierre"
    "Approved On"     = ""
}
$newAzResourceGroupSplat = @{
    Name = $ResourceGroupName
    Location = $LocationName
    Tag = $Tags
}
New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
$ComputerName = $VMName
$VMSize = "Standard_B2MS"
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"
$GUID = [guid]::NewGuid()
$OSDiskName = -join (" $VMName" , "_OSDisk" , "_1" , "_$GUID" )
$DNSNameLabel = -join (" $VMName" , "DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com
$NetworkName = -join (" $VMName" , "_group-vnet" )
$NICPrefix = 'NIC1'
$NICName = -join (" $VMName" , "_$NICPrefix" ).ToLower()
$IPConfigName = -join (" $VMName" , "$NICName" , "_IPConfig1" ).ToLower()
$PublicIPAddressName = -join (" $VMName" , "-ip" )
$SubnetName = -join (" $VMName" , "-subnet" )
$SubnetAddressPrefix = " 10.0.0.0/24"
$VnetAddressPrefix = " 10.0.0.0/16"
$NSGName = -join (" $VMName" , "-nsg" )
$newAzVirtualNetworkSubnetConfigSplat = @{
    Name          = $SubnetName
    AddressPrefix = $SubnetAddressPrefix
}
$SingleSubnet = New-AzVirtualNetworkSubnetConfig -ErrorAction Stop @newAzVirtualNetworkSubnetConfigSplat
$newAzVirtualNetworkSplat = @{
    Name              = $NetworkName
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    AddressPrefix     = $VnetAddressPrefix
    Subnet            = $SingleSubnet
    Tag               = $Tags
}
$Vnet = New-AzVirtualNetwork -ErrorAction Stop @newAzVirtualNetworkSplat
    # IpTagType = "FirstPartyUsage"
    # Tag       = " /Sql"
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
$SourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip" ).Content #Gets the public IP of the current machine
$SourceAddressPrefixCIDR = -join (" $SourceAddressPrefix" , "/32" )
$ASGName = -join (" $VMName" , "_ASG1" )
$newAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = " $ResourceGroupName"
    Name              = " $ASGName"
    Location          = " $LocationName"
    Tag               = $Tags
}
$ASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat
$getAzVirtualNetworkSubnetConfigSplat = @{
    Name = $SubnetName
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
$newAzNetworkSecurityRuleConfigSplat = @{
    # Name = 'rdp-rule'
    Name                                = 'RDP-rule'
    # Description = "Allow RDP"
    Description                         = 'Allow RDP'
    Access                              = 'Allow'
    Protocol                            = 'Tcp'
    Direction                           = 'Inbound'
    Priority                            = 100
    SourceAddressPrefix                 = $SourceAddressPrefixCIDR
    SourcePortRange                     = '*'
    # DestinationAddressPrefix = '*'
    # DestinationAddressPrefix = $DestinationAddressPrefixCIDR #this will throw an error due to {Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress/32} work on it some time to fix
    # DestinationAddressPrefix = '*'
    # DestinationPortRange = 3389
    DestinationPortRange                = '3389'
    DestinationApplicationSecurityGroup = $ASG
}
$rule1 = New-AzNetworkSecurityRuleConfig -ErrorAction Stop @newAzNetworkSecurityRuleConfigSplat
$newAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    Name              = $NSGName
    # SecurityRules     = $rule1, $rule2
    SecurityRules     = $rule1
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
$VMLocalAdminPassword = Generate-Password -length 16;
$VMLocalAdminSecurePassword = $VMLocalAdminPassword | Read-Host -AsSecureString -Prompt "Enter secure value"
$Credential = New-Object -ErrorAction Stop PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
$Credential = Get-Credential -ErrorAction Stop
$newAzVMConfigSplat = @{
    VMName = $VMName
    VMSize = $VMSize
    Tags   = $Tags
    IdentityType = 'SystemAssigned'
}
$VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
$setAzVMOperatingSystemSplat = @{
    VM           = $VirtualMachine
    Windows      = $true
    # Linux        = $true
    ComputerName = $ComputerName
    Credential   = $Credential
    ProvisionVMAgent = $true
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
    # PublisherName = "Canonical"
    # Offer         = " 0001-com-ubuntu-server-focal"
    # Skus          = " 20_04-lts-gen2"
    # Version       = " latest"
    publisherName = "MicrosoftWindowsDesktop"
    offer         = " office-365"
    Skus          = " 20h2-evd-o365pp"
    version       = " latest"
    # publisherName = "MicrosoftWindowsServer"
    # offer         = "WindowsServer"
    # Skus          = " 2019-datacenter-gensecond"
    # version       = " latest"
    # Caching = 'ReadWrite'
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
    DiskSizeInGB = '128'
}
$VirtualMachine = Set-AzVMOSDisk -ErrorAction Stop @setAzVMOSDiskSplat
$newAzVMSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    VM                = $VirtualMachine
    Verbose           = $true
    Tag               = $Tags
}
New-AzVM -ErrorAction Stop @newAzVMSplat
$setAzVMExtensionSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $LocationName
    VMName = $VMName
    Name = "AADLoginForWindows"
    Publisher = "Microsoft.Azure.ActiveDirectory"
    ExtensionType = "AADLoginForWindows"
    TypeHandlerVersion = " 1.0"
    # SettingString = $SettingsString
}
Set-AzVMExtension -ErrorAction Stop @setAzVMExtensionSplat
$UsersGroupName = "Azure VM - Standard User"
$ObjectID = (Get-AzADGroup -SearchString $UsersGroupName).ID
$vmtype = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName).Type
New-AzRoleAssignment -ObjectId $ObjectID -RoleDefinitionName 'Virtual Machine User Login' -ResourceGroupName $ResourceGroupName -ResourceName $VMName -ResourceType $vmtype
$AdminsGroupName = "Azure VM - Admins"
$ObjectID = (Get-AzADGroup -SearchString $AdminsGroupName).ID
$vmtype = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName).Type
New-AzRoleAssignment -ObjectId $ObjectID -RoleDefinitionName 'Virtual Machine Administrator Login' -ResourceGroupName $ResourceGroupName -ResourceName $VMName -ResourceType $vmtype
$setAzVMAutoShutdownSplat = @{
    # ResourceGroupName = 'RG-WE-001'
    ResourceGroupName = $ResourceGroupName
    # Name              = 'MYVM001'
    Name              = $VMName
    Enable            = $true
    Time              = '23:59'
    # TimeZone = "W. Europe Standard Time"
    TimeZone          = "Central Standard Time"
    Email             = " abdullah@canadacomputing.ca"
}
Set-AzVMAutoShutdown -ErrorAction Stop @setAzVMAutoShutdownSplat
Write-Information \'The VM is now ready.... here is your login details\'
Write-Information \'username:\' $VMLocalAdminUser
Write-Information \'Password:\' $VMLocalAdminPassword
Write-Information \'DNSName:\' $DNSNameLabel

