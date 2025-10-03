#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create VM Windowsserver Workgroup With New VNet

.DESCRIPTION
    Create VM Windowsserver Workgroup With New VNet operation


    Author: Wes Ellis (wes@wesellis.com)
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = 'stop'
$Helpers = "$PsScriptRoot\Helpers\"
Get-ChildItem -Path $Helpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }
$LocationName = 'CanadaCentral'
$CustomerName = 'CCI'
$VMName = 'VEEAM-CCGW01'
$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Autoshutown"     = 'ON'
    "Createdby"       = 'Abdullah Ollivierre'
    "CustomerName"    = " $CustomerName"
    "DateTimeCreated" = " $datetime"
    "Environment"     = 'Production'
    "Application"     = 'VEEAM Cloud Connect Gateway'
    "Purpose"         = 'The cloud gateway is a network appliance that resides on the SP side. The cloud gateway acts as communication point in the cloud: it routes commands and traffic between the tenant Veeam backup server'
    "Uptime"          = '24/7'
    "Workload"        = 'VEEAM Cloud Connect Gateway'
    "RebootCaution"   = 'Reboot any time'
    "VMSize"          = ''
    "Location"        = " $LocationName"
    "Approved By"     = "Abdullah Ollivierre"
    "Approved On"     = ""
}
$newAzResourceGroupSplat = @{
    Name     = $ResourceGroupName
    Location = $LocationName
    Tag      = $Tags
}
New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
$ComputerName = $VMName
$VMSize = "Standard_B2S" # 1vCPUs and 2GB of RAM
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
$newAzPublicIpAddressSplat = @{
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
    PublicIpAddress          = $PIP
    ApplicationSecurityGroup = $ASG
    Primary                  = $true
}
$IPConfig1 = New-AzNetworkInterfaceIpConfig -ErrorAction Stop @newAzNetworkInterfaceIpConfigSplat
$newAzNetworkSecurityRuleConfigSplat = @{
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
$newAzNetworkSecurityGroupSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location          = $LocationName
    Name              = $NSGName
    SecurityRules     = $rule1
    Tag               = $Tags
}
$NSG = New-AzNetworkSecurityGroup -ErrorAction Stop @newAzNetworkSecurityGroupSplat
$newAzNetworkInterfaceSplat = @{
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
$newAzVMConfigSplat = @{
    VMName       = $VMName
    VMSize       = $VMSize
    Tags         = $Tags
    IdentityType = 'SystemAssigned'
}
$VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
$setAzVMOperatingSystemSplat = @{
    VM               = $VirtualMachine
    Windows          = $true
    ComputerName     = $ComputerName
    Credential       = $Credential
    ProvisionVMAgent = $true
}
$VirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @setAzVMOperatingSystemSplat
$addAzVMNetworkInterfaceSplat = @{
    VM = $VirtualMachine
    Id = $NIC.Id
}
$VirtualMachine = Add-AzVMNetworkInterface @addAzVMNetworkInterfaceSplat
$setAzVMSourceImageSplat = @{
    VM             = $VirtualMachine
    publisherName = "MicrosoftWindowsServer"
    offer         = "WindowsServer"
    Skus          = " 2019-datacenter-gensecond"
    version       = " latest"
}
$VirtualMachine = Set-AzVMSourceImage -ErrorAction Stop @setAzVMSourceImageSplat
$setAzVMOSDiskSplat = @{
    VM           = $VirtualMachine
    Name         = $OSDiskName
    Caching      = $OSDiskCaching
    CreateOption = $OSCreateOption
    DiskSizeInGB = '128'
    StorageAccountType = 'Standard_LRS'
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
$setAzVMAutoShutdownSplat = @{
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
Write-Information \'DNSName:\' $DNSNameLabel'.canadacentral.cloudapp.azure.com'


