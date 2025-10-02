#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create VM Windowsserver 2022 Workgroup With New VNet

.DESCRIPTION
    Create VM Windowsserver 2022 Workgroup With New VNet operation


    Author: Wes Ellis (wes@wesellis.com)
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = 'stop'
$Helpers = "$PsScriptRoot\Helpers\"
Get-ChildItem -Path $Helpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }
$LocationName = 'Canadaeast'
$CustomerName = 'CCI'
$VMName = 'Splunk1'
$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Autoshutown"     = 'ON'
    "Createdby"       = 'Abdullah Ollivierre'
    "CustomerName"    = " $CustomerName"
    "DateTimeCreated" = " $datetime"
    "Environment"     = 'Dev'
    "Application"     = 'Splunk1'
    "Purpose"         = 'Splunk1 to be used by Shan@canadacomputing.ca for FGC Health monitoring'
    "Uptime"          = '24/7'
    "Workload"        = 'Splunk1'
    "RebootCaution"   = 'Only reboot for maintenance'
    "VMSize"          = ''
    "Location"        = " $LocationName"
    "Approved By"     = "Abdullah Ollivierre"
    "Approved On"     = "Jan-26-2022"
}
$NewAzResourceGroupSplat = @{
    Name     = $ResourceGroupName
    Location = $LocationName
    Tag      = $Tags
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
$NewAzVirtualNetworkSubnetConfigSplat = @{
    Name          = $SubnetName
    AddressPrefix = $SubnetAddressPrefix
}
$SingleSubnet = New-AzVirtualNetworkSubnetConfig -ErrorAction Stop @newAzVirtualNetworkSubnetConfigSplat
$NewAzVirtualNetworkSplat = @{
    Name              = $NetworkName
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    AddressPrefix     = $VnetAddressPrefix
    Subnet            = $SingleSubnet
    Tag               = $Tags
}
$Vnet = New-AzVirtualNetwork -ErrorAction Stop @newAzVirtualNetworkSplat
$NewAzPublicIpAddressSplat = @{
    Name              = $PublicIPAddressName
    DomainNameLabel   = $DNSNameLabel
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    AllocationMethod  = 'Static'
    Tag               = $Tags
}
$PIP = New-AzPublicIpAddress -ErrorAction Stop @newAzPublicIpAddressSplat
$SourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip" ).Content #Gets the public IP of the current machine
$SourceAddressPrefixCIDR = -join (" $SourceAddressPrefix" , "/32" )
$ASGName = -join (" $VMName" , "_ASG1" )
$NewAzApplicationSecurityGroupSplat = @{
    ResourceGroupName = " $ResourceGroupName"
    Name              = " $ASGName"
    Location          = " $LocationName"
    Tag               = $Tags
}
$ASG = New-AzApplicationSecurityGroup -ErrorAction Stop @newAzApplicationSecurityGroupSplat
$GetAzVirtualNetworkSubnetConfigSplat = @{
    Name           = $SubnetName
    VirtualNetwork = $vnet
}
$Subnet = Get-AzVirtualNetworkSubnetConfig -ErrorAction Stop @getAzVirtualNetworkSubnetConfigSplat
$NewAzNetworkInterfaceIpConfigSplat = @{
    Name                     = $IPConfigName
    Subnet                   = $Subnet
    PublicIpAddress          = $PIP
    ApplicationSecurityGroup = $ASG
    Primary                  = $true
}
$IPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat
$NewAzNetworkSecurityRuleConfigSplat = @{
    Name                                = 'RDP-rule'
    Description                         = 'Allow RDP'
    Access                              = 'Allow'
    Protocol                            = 'Tcp'
    Direction                           = 'Inbound'
    Priority                            = 100
    SourceAddressPrefix                 = $SourceAddressPrefixCIDR
    SourcePortRange                     = '*'
    DestinationPortRange                = '3389'
    DestinationApplicationSecurityGroup = $ASG
}
$rule1 = New-AzNetworkSecurityRuleConfig -ErrorAction Stop @newAzNetworkSecurityRuleConfigSplat
$NewAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    Name              = $NSGName
    SecurityRules     = $rule1
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
$VMLocalAdminUser = Read-Host -Prompt 'Please enter a username to be created'
$VMLocalAdminPassword = Generate-Password -length 16;
$VMLocalAdminSecurePassword = $VMLocalAdminPassword | Read-Host -AsSecureString -Prompt "Enter secure value"
$Credential = New-Object -ErrorAction Stop PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
$NewAzVMConfigSplat = @{
    VMName       = $VMName
    VMSize       = $VMSize
    Tags         = $Tags
    IdentityType = 'SystemAssigned'
}
$VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
$SetAzVMOperatingSystemSplat = @{
    VM               = $VirtualMachine
    Windows          = $true
    ComputerName     = $ComputerName
    Credential       = $Credential
    ProvisionVMAgent = $true
}
$VirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat
$AddAzVMNetworkInterfaceSplat = @{
    VM = $VirtualMachine
    Id = $NIC.Id
}
$VirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat
$SetAzVMSourceImageSplat = @{
    VM             = $VirtualMachine
    publisherName = "MicrosoftWindowsServer"
    offer         = "WindowsServer"
    Skus          = " 2022-datacenter-azure-edition-smalldisk"
    version       = " latest"
}
$VirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat
$SetAzVMOSDiskSplat = @{
    VM           = $VirtualMachine
    Name         = $OSDiskName
    Caching      = $OSDiskCaching
    CreateOption = $OSCreateOption
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
$SetAzVMAutoShutdownSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name              = $VMName
    Enable            = $true
    Time              = '23:59'
    TimeZone          = "Central Standard Time"
    Email             = " abdullah@canadacomputing.ca"
}
Set-AzVMAutoShutdown -ErrorAction Stop @setAzVMAutoShutdownSplat
Write-Information \'The VM is now ready.... here is your login details\'
Write-Information \'username:\' $VMLocalAdminUser
Write-Information \'Password:\' $VMLocalAdminPassword
Write-Output "DNSName:' $DNSNameLabel'.$LocationName.cloudapp.azure.com"



