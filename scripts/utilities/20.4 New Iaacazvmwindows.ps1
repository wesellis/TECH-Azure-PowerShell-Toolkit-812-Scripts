#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    New Iaacazvmwindows

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function New-IaaCAzVMWindows -ErrorAction Stop {
    function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
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
    $VnetAddressPrefix,
    [ValidateNotNullOrEmpty()]
    $SourceAddressPrefixCIDR,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubnetAddressPrefix,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SourceAddressPrefix,
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
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $DiskSizeInGB,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ExtensionName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ExtensionPublisher,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ExtensionType,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $TypeHandlerVersion,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $UsersGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $AdminsGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $RoleDefinitionNameUsers,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $RoleDefinitionNameAdmins,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Time,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $TimeZone,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Email,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$SecretLength
    )
    $NewAzResourceGroupSplat = @{
        Name     = $ResourceGroupName
        Location = $LocationName
        Tag      = $Tags
    }
    New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat
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
    $NewAzNetworkSecurityRuleConfigSplat = @{
        Name                                = 'RDP-rule'
        Description                         = 'Allow RDP'
        Access                              = 'Allow'
        Protocol                            = 'Tcp'
        Direction                           = 'Inbound'
        Priority                            = 100
        SourceAddressPrefix                 = $SourceAddressPrefix
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
    $VMLocalAdminPassword = Generate-Password -length $PassWordLength
    $VMLocalAdminSecurePassword = $VMLocalAdminPassword | Read-Host -AsSecureString -Prompt "Enter secure value"
    $Credential = New-Object -ErrorAction Stop PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
    $Credential = Get-Credential -ErrorAction Stop
    $NewAzVMConfigSplat = @{
        VMName = $VMName
        VMSize = $VMSize
        Tags   = $Tags
    }
    $VirtualMachine = New-AzVMConfig -ErrorAction Stop @newAzVMConfigSplat
    $SetAzVMOperatingSystemSplat = @{
        VM           = $VirtualMachine
        Windows      = $true
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
    $SetAzVMExtensionSplat = @{
        ResourceGroupName  = $ResourceGroupName
        Location           = $LocationName
        VMName             = $VMName
        Name               = $ExtensionName
        Publisher          = $ExtensionPublisher
        ExtensionType      = $ExtensionType
        TypeHandlerVersion = $TypeHandlerVersion
    }
    Set-AzVMExtension -ErrorAction Stop @setAzVMExtensionSplat
    $UsersGroupName = $UsersGroupName
    $ObjectID = (Get-AzADGroup -SearchString $UsersGroupName).ID
    $vmtype = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName).Type
    $NewAzRoleAssignmentParams = @{
        ObjectId           = $ObjectID
        RoleDefinitionName = $RoleDefinitionNameUsers
        ResourceGroupName  = $ResourceGroupName
        ResourceName       = $VMName
        ResourceType       = $vmtype
    }
    New-AzRoleAssignment -ErrorAction Stop @NewAzRoleAssignmentParams
    $AdminsGroupName = $AdminsGroupName
    $ObjectID = (Get-AzADGroup -SearchString $UsersGroupName).ID
    $vmtype = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName).Type
    $NewAzRoleAssignmentParams = @{
        ObjectId           = $ObjectID
        RoleDefinitionName = $RoleDefinitionNameAdmins
        ResourceGroupName  = $ResourceGroupName
        ResourceName       = $VMName
        ResourceType       = $vmtype
    }
    New-AzRoleAssignment -ErrorAction Stop @NewAzRoleAssignmentParams
    $SetAzVMAutoShutdownSplat = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $VMName
        Enable            = $true
        Time              = $Time
        TimeZone          = $TimeZone
        Email             = $Email
    }
    Set-AzVMAutoShutdown -ErrorAction Stop @setAzVMAutoShutdownSplat
    Write-Information \'The VM is now ready.... here is your login details\'
    Write-Information \'username:\' $VMLocalAdminUser
    Write-Information \'Password:\' $VMLocalAdminPassword
    Write-Information \'DNSName:\' $DNSNameLabel
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
