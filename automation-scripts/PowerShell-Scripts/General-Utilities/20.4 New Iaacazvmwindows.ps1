<#
.SYNOPSIS
    20.4 New Iaacazvmwindows

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
    We Enhanced 20.4 New Iaacazvmwindows

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }

function WE-New-IaaCAzVMWindows {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    

function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

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
    [string]$WEVnetAddressPrefix, 
        # [Parameter(Mandatory = $true)]
        # [ValidateNotNullOrEmpty()]
        # [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESourceAddressPrefixCIDR,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubnetAddressPrefix,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESourceAddressPrefix,

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
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDiskSizeInGB,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEExtensionName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEExtensionPublisher,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEExtensionType,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETypeHandlerVersion,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEUsersGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAdminsGroupName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERoleDefinitionNameUsers,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERoleDefinitionNameAdmins,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETime,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETimeZone,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEmail,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$secretLength

    )

    #Creating the Resource Group Name
    $newAzResourceGroupSplat = @{
        Name     = $WEResourceGroupName
        Location = $WELocationName
        Tag      = $WETags
    }

    New-AzResourceGroup @newAzResourceGroupSplat


    #Creating the Subnet for the VM
    $newAzVirtualNetworkSubnetConfigSplat = @{
        Name          = $WESubnetName
        AddressPrefix = $WESubnetAddressPrefix
    }
    $WESingleSubnet = New-AzVirtualNetworkSubnetConfig @newAzVirtualNetworkSubnetConfigSplat

    #Creating the VNET for the VM
    $newAzVirtualNetworkSplat = @{
        Name              = $WENetworkName
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        AddressPrefix     = $WEVnetAddressPrefix
        Subnet            = $WESingleSubnet
        Tag               = $WETags
    }
    $WEVnet = New-AzVirtualNetwork @newAzVirtualNetworkSplat


    $getAzVirtualNetworkSubnetConfigSplat = @{
        Name           = $WESubnetName
        VirtualNetwork = $vnet
    }
    
    $WESubnet = Get-AzVirtualNetworkSubnetConfig @getAzVirtualNetworkSubnetConfigSplat


    $newAzNetworkInterfaceIpConfigSplat = @{
        Name                     = $WEIPConfigName
        Subnet                   = $WESubnet
        PublicIpAddress          = $WEPIP
        ApplicationSecurityGroup = $WEASG
        Primary                  = $true
    }
    
    $WEIPConfig1 = New-AzNetworkInterfaceIpConfig @newAzNetworkInterfaceIpConfigSplat

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


    $newAzNetworkSecurityRuleConfigSplat = @{
        # Name = 'rdp-rule'
        Name                                = 'RDP-rule'
        # Description = " Allow RDP"
        Description                         = 'Allow RDP'
        Access                              = 'Allow'
        Protocol                            = 'Tcp'
        Direction                           = 'Inbound'
        Priority                            = 100
        SourceAddressPrefix                 = $WESourceAddressPrefix
        # SourceAddressPrefixCIDR             = $WESourceAddressPrefixCIDR
        SourcePortRange                     = '*'
        DestinationPortRange                = '3389'
        DestinationApplicationSecurityGroup = $WEASG
    }
    $rule1 = New-AzNetworkSecurityRuleConfig @newAzNetworkSecurityRuleConfigSplat

    #Create a new NSG based on Rules #1 & #2
    $newAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        Name              = $WENSGName
        # SecurityRules     = $rule1, $rule2
        SecurityRules     = $rule1
        Tag               = $WETags
    }
    $WENSG = New-AzNetworkSecurityGroup @newAzNetworkSecurityGroupSplat


    #Creating the NIC for the VM
    $newAzNetworkInterfaceSplat = @{
        Name                   = $WENICName
        ResourceGroupName      = $WEResourceGroupName
        Location               = $WELocationName
        NetworkSecurityGroupId = $WENSG.Id
        # ApplicationSecurityGroup = $WEASG
        IpConfiguration        = $WEIPConfig1
        Tag                    = $WETags
    
    }
    $WENIC = New-AzNetworkInterface @newAzNetworkInterfaceSplat


    #Define a credential object to store the username and password for the VM
    $WEVMLocalAdminPassword = Generate-Password -length $WEPassWordLength
   ;  $WEVMLocalAdminSecurePassword = $WEVMLocalAdminPassword | ConvertTo-SecureString -Force -AsPlainText
   ;  $WECredential = New-Object PSCredential ($WEVMLocalAdminUser, $WEVMLocalAdminSecurePassword);
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
        Windows      = $true
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
    $WEVirtualMachine = Set-AzVMOSDisk @setAzVMOSDiskSplat

    #Creating the VM
    $newAzVMSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Location          = $WELocationName
        VM                = $WEVirtualMachine
        Verbose           = $true
        Tag               = $WETags
    }
    New-AzVM @newAzVMSplat
    
    #Post Deployment Configuration #1
    $setAzVMExtensionSplat = @{
        ResourceGroupName  = $WEResourceGroupName
        Location           = $WELocationName
        VMName             = $WEVMName
        Name               = $WEExtensionName
        Publisher          = $WEExtensionPublisher
        ExtensionType      = $WEExtensionType
        TypeHandlerVersion = $WETypeHandlerVersion
        # SettingString = $WESettingsString
    }
    Set-AzVMExtension @setAzVMExtensionSplat


    #Post Deployment Configuration #2
    $WEUsersGroupName = $WEUsersGroupName
    #Store the Object ID in a var
    $WEObjectID = (Get-AzADGroup -SearchString $WEUsersGroupName).ID
    #Store the Resource Type of the VM
    $vmtype = (Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVMName).Type
    #Create a new AZ Role Assignment at the Azure RBAC Level for that VM for Standard users

    $WENewAzRoleAssignmentParams = @{
        ObjectId           = $WEObjectID
        RoleDefinitionName = $WERoleDefinitionNameUsers
        ResourceGroupName  = $WEResourceGroupName
        ResourceName       = $WEVMName
        ResourceType       = $vmtype
    }
    New-AzRoleAssignment @NewAzRoleAssignmentParams




    #Post Deployment Configuration #3
    $WEAdminsGroupName = $WEAdminsGroupName
    #Store the Object ID in a var
    $WEObjectID = (Get-AzADGroup -SearchString $WEUsersGroupName).ID
    #Store the Resource Type of the VM
    $vmtype = (Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVMName).Type
    #Create a new AZ Role Assignment at the Azure RBAC Level for that VM for Standard users
    
   ;  $WENewAzRoleAssignmentParams = @{
        ObjectId           = $WEObjectID
        RoleDefinitionName = $WERoleDefinitionNameAdmins
        ResourceGroupName  = $WEResourceGroupName
        ResourceName       = $WEVMName
        ResourceType       = $vmtype
    }
    New-AzRoleAssignment @NewAzRoleAssignmentParams


    #Post Deployment Configuration #4
   ;  $setAzVMAutoShutdownSplat = @{
        ResourceGroupName = $WEResourceGroupName
        Name              = $WEVMName
        Enable            = $true
        Time              = $WETime
        TimeZone          = $WETimeZone
        Email             = $WEEmail
    }

    Set-AzVMAutoShutdown @setAzVMAutoShutdownSplat



    #Give the user their VM Login Details
    Write-Host 'The VM is now ready.... here is your login details'
    Write-Host 'username:' $WEVMLocalAdminUser
    Write-Host 'Password:' $WEVMLocalAdminPassword
    Write-Host 'DNSName:' $WEDNSNameLabel
        

}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
