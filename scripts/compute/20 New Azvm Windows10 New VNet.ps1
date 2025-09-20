#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create VM Windows 10 with New VNet

.DESCRIPTION
    Creates a Windows 10 Virtual Machine with Office 365 in a new Azure Virtual Network
    Configures Azure AD authentication and role assignments for remote access
    Designed for rendering workloads with Windows Movie Maker
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER CustomerName
    Name of the customer/organization

.PARAMETER VMName
    Name for the virtual machine

.PARAMETER LocationName
    Azure region where resources will be created

.PARAMETER VMSize
    Size of the virtual machine (default: Standard_D4as_v4 for rendering workloads)

.PARAMETER VMAdminUser
    Administrator username for the VM

.PARAMETER VMAdminPassword
    Administrator password for the VM (secure string)

.PARAMETER AutoShutdownTime
    Time for auto-shutdown in 24-hour format (default: 23:59)

.PARAMETER NotificationEmail
    Email address for shutdown notifications

.PARAMETER VnetAddressPrefix
    Address prefix for the new VNet (default: 10.0.0.0/16)

.PARAMETER SubnetAddressPrefix
    Address prefix for the subnet (default: 10.0.0.0/24)

.PARAMETER WindowsVersion
    Windows 10 version/SKU (default: 20h2-evd-o365pp for Office 365)

.PARAMETER EnableAzureAD
    Enable Azure AD authentication (default: true)

.PARAMETER StandardUsersGroupName
    Azure AD group name for standard users (default: "Azure VM - Standard User")

.PARAMETER AdminUsersGroupName
    Azure AD group name for admin users (default: "Azure VM - Admins")

.PARAMETER Environment
    Environment tag (default: Dev)

.EXAMPLE
    .\Create-Windows10VM-NewVNet.ps1 -CustomerName "CanadaComputing" -VMName "Render02" -LocationName "CanadaCentral" -VMAdminUser "admin" -NotificationEmail "admin@company.com"

.EXAMPLE
    $securePassword = ConvertTo-SecureString "MyP@ssw0rd123!" -AsPlainText -Force
    .\Create-Windows10VM-NewVNet.ps1 -CustomerName "MediaCompany" -VMName "RenderStation" -LocationName "EastUS" -VMAdminUser "renderadmin" -VMAdminPassword $securePassword -NotificationEmail "it@mediacompany.com" -VMSize "Standard_D8as_v4"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$CustomerName,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LocationName,
    
    [Parameter()]
    [string]$VMSize = "Standard_D4as_v4",
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMAdminUser,
    
    [Parameter(Mandatory = $true)]
    [SecureString]$VMAdminPassword,
    
    [Parameter()]
    [ValidatePattern('^\d{2}:\d{2}$')]
    [string]$AutoShutdownTime = "23:59",
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$NotificationEmail,
    
    [Parameter()]
    [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$')]
    [string]$VnetAddressPrefix = "10.0.0.0/16",
    
    [Parameter()]
    [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$')]
    [string]$SubnetAddressPrefix = "10.0.0.0/24",
    
    [Parameter()]
    [ValidateSet("20h2-evd-o365pp", "21h1-evd-o365pp", "win10-21h2-ent", "win10-22h2-ent")]
    [string]$WindowsVersion = "20h2-evd-o365pp",
    
    [Parameter()]
    [bool]$EnableAzureAD = $true,
    
    [Parameter()]
    [string]$StandardUsersGroupName = "Azure VM - Standard User",
    
    [Parameter()]
    [string]$AdminUsersGroupName = "Azure VM - Admins",
    
    [Parameter()]
    [ValidateSet("Dev", "Test", "Staging", "Production")]
    [string]$Environment = "Dev"
)

# Set error handling preference
$ErrorActionPreference = 'Stop'

# Custom logging function
function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    
    $logEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

# Function to generate secure password
function Generate-Password {
    param([int]$Length = 16)
    
    $characters = 'abcdefghkmnprstuvwxyzABCDEFGHKMNPRSTUVWXYZ23456789!@#$%&*'
    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $characters[(Get-Random -Maximum $characters.Length)]
    }
    return $password
}

try {
    Write-LogMessage "Starting Windows 10 VM creation with new VNet..." -Level "INFO"
    Write-LogMessage "Customer: $CustomerName" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Location: $LocationName" -Level "INFO"
    Write-LogMessage "VM Size: $VMSize (optimized for rendering)" -Level "INFO"
    Write-LogMessage "Windows Version: $WindowsVersion" -Level "INFO"
    Write-LogMessage "Environment: $Environment" -Level "INFO"
    Write-LogMessage "Azure AD Authentication: $EnableAzureAD" -Level "INFO"

    # Validate Azure context
    $context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }
    
    Write-LogMessage "Using Azure subscription: $($context.Subscription.Name)" -Level "INFO"

    # Define variables
    $ResourceGroupName = "${CustomerName}_${VMName}_RG"
    $datetime = [System.DateTime]::Now.ToString("yyyy_MM_dd_HH_mm_ss")
    
    # Define tags
    [hashtable]$Tags = @{
        "Autoshutdown"    = 'ON'
        "Createdby"       = $context.Account.Id
        "CustomerName"    = $CustomerName
        "DateTimeCreated" = $datetime
        "Environment"     = $Environment
        "Application"     = 'Windows Movie Maker'
        "Purpose"         = 'Rendering with Movie Maker'
        "Uptime"          = 'Rendering with Movie Maker'
        "Workload"        = 'Rendering with Movie Maker'
        "RebootCaution"   = 'Reboot any time'
        "VMSize"          = $VMSize
        "Location"        = $LocationName
        "ApprovedBy"      = $context.Account.Id
        "ApprovedOn"      = (Get-Date).ToString("yyyy-MM-dd")
        "WindowsVersion"  = $WindowsVersion
        "AzureAD"         = $EnableAzureAD.ToString()
    }

    # Create Resource Group
    Write-LogMessage "Creating resource group: $ResourceGroupName" -Level "INFO"
    $newAzResourceGroupSplat = @{
        Name     = $ResourceGroupName
        Location = $LocationName
        Tag      = $Tags
    }
    $resourceGroup = New-AzResourceGroup @newAzResourceGroupSplat
    Write-LogMessage "Resource group created successfully" -Level "SUCCESS"

    # Define network configuration variables
    $ComputerName = $VMName
    $OSDiskCaching = "ReadWrite"
    $OSCreateOption = "FromImage"
    $GUID = [guid]::NewGuid()
    $OSDiskName = "${VMName}_OSDisk_1_$GUID"
    $DNSNameLabel = "${VMName}dns".ToLower()
    $NetworkName = "${VMName}_group-vnet"
    $NICPrefix = 'NIC1'
    $NICName = "${VMName}_${NICPrefix}".ToLower()
    $IPConfigName = "${VMName}${NICName}_IPConfig1".ToLower()
    $PublicIPAddressName = "${VMName}-ip"
    $SubnetName = "${VMName}-subnet"
    $NSGName = "${VMName}-nsg"
    $ASGName = "${VMName}_ASG1"

    # Create Virtual Network and Subnet
    Write-LogMessage "Creating virtual network: $NetworkName" -Level "INFO"
    Write-LogMessage "VNet Address Prefix: $VnetAddressPrefix" -Level "INFO"
    Write-LogMessage "Subnet Address Prefix: $SubnetAddressPrefix" -Level "INFO"
    
    $newAzVirtualNetworkSubnetConfigSplat = @{
        Name          = $SubnetName
        AddressPrefix = $SubnetAddressPrefix
    }
    $SingleSubnet = New-AzVirtualNetworkSubnetConfig @newAzVirtualNetworkSubnetConfigSplat

    $newAzVirtualNetworkSplat = @{
        Name              = $NetworkName
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        AddressPrefix     = $VnetAddressPrefix
        Subnet            = $SingleSubnet
        Tag               = $Tags
    }
    $Vnet = New-AzVirtualNetwork @newAzVirtualNetworkSplat
    Write-LogMessage "Virtual network created successfully" -Level "SUCCESS"

    # Create Public IP
    Write-LogMessage "Creating static public IP address: $PublicIPAddressName" -Level "INFO"
    $newAzPublicIpAddressSplat = @{
        Name              = $PublicIPAddressName
        DomainNameLabel   = $DNSNameLabel
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        AllocationMethod  = 'Static'
        Tag               = $Tags
    }
    $PIP = New-AzPublicIpAddress @newAzPublicIpAddressSplat
    Write-LogMessage "Public IP created successfully" -Level "SUCCESS"

    # Get current public IP for NSG rule
    Write-LogMessage "Retrieving current public IP for security rules..." -Level "INFO"
    try {
        $SourceAddressPrefix = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -TimeoutSec 10).Content.Trim()
        $SourceAddressPrefixCIDR = "${SourceAddressPrefix}/32"
        Write-LogMessage "Current public IP: $SourceAddressPrefix" -Level "INFO"
    }
    catch {
        Write-LogMessage "Could not retrieve public IP, using 0.0.0.0/0 (less secure)" -Level "WARN"
        $SourceAddressPrefixCIDR = "0.0.0.0/0"
    }

    # Create Application Security Group
    Write-LogMessage "Creating application security group: $ASGName" -Level "INFO"
    $newAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $ASGName
        Location          = $LocationName
        Tag               = $Tags
    }
    $ASG = New-AzApplicationSecurityGroup @newAzApplicationSecurityGroupSplat
    Write-LogMessage "Application security group created successfully" -Level "SUCCESS"

    # Get subnet configuration
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $Vnet

    # Create IP Configuration
    Write-LogMessage "Creating network interface IP configuration" -Level "INFO"
    $newAzNetworkInterfaceIpConfigSplat = @{
        Name                     = $IPConfigName
        Subnet                   = $Subnet
        PublicIpAddress          = $PIP
        ApplicationSecurityGroup = $ASG
        Primary                  = $true
    }
    $IPConfig1 = New-AzNetworkInterfaceIpConfig @newAzNetworkInterfaceIpConfigSplat

    # Create Network Security Group Rule
    Write-LogMessage "Creating network security group rule for RDP access" -Level "INFO"
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
    $rule1 = New-AzNetworkSecurityRuleConfig @newAzNetworkSecurityRuleConfigSplat

    # Create Network Security Group
    Write-LogMessage "Creating network security group: $NSGName" -Level "INFO"
    $newAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        Name              = $NSGName
        SecurityRules     = $rule1
        Tag               = $Tags
    }
    $NSG = New-AzNetworkSecurityGroup @newAzNetworkSecurityGroupSplat
    Write-LogMessage "Network security group created successfully" -Level "SUCCESS"

    # Create Network Interface
    Write-LogMessage "Creating network interface: $NICName" -Level "INFO"
    $newAzNetworkInterfaceSplat = @{
        Name                   = $NICName
        ResourceGroupName      = $ResourceGroupName
        Location               = $LocationName
        NetworkSecurityGroupId = $NSG.Id
        IpConfiguration        = $IPConfig1
        Tag                    = $Tags
    }
    $NIC = New-AzNetworkInterface @newAzNetworkInterfaceSplat
    Write-LogMessage "Network interface created successfully" -Level "SUCCESS"

    # Create credential object
    $Credential = New-Object PSCredential ($VMAdminUser, $VMAdminPassword)

    # Create VM Configuration
    Write-LogMessage "Creating VM configuration with system-assigned managed identity" -Level "INFO"
    $newAzVMConfigSplat = @{
        VMName       = $VMName
        VMSize       = $VMSize
        Tags         = $Tags
        IdentityType = 'SystemAssigned'
    }
    $VirtualMachine = New-AzVMConfig @newAzVMConfigSplat

    # Set VM Operating System
    $setAzVMOperatingSystemSplat = @{
        VM               = $VirtualMachine
        Windows          = $true
        ComputerName     = $ComputerName
        Credential       = $Credential
        ProvisionVMAgent = $true
    }
    $VirtualMachine = Set-AzVMOperatingSystem @setAzVMOperatingSystemSplat

    # Add Network Interface to VM
    $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id

    # Set VM Source Image
    Write-LogMessage "Configuring VM source image (Windows 10 with Office 365: $WindowsVersion)" -Level "INFO"
    $setAzVMSourceImageSplat = @{
        VM            = $VirtualMachine
        PublisherName = "MicrosoftWindowsDesktop"
        Offer         = "office-365"
        Skus          = $WindowsVersion
        Version       = "latest"
    }
    $VirtualMachine = Set-AzVMSourceImage @setAzVMSourceImageSplat

    # Set VM OS Disk
    $setAzVMOSDiskSplat = @{
        VM           = $VirtualMachine
        Name         = $OSDiskName
        Caching      = $OSDiskCaching
        CreateOption = $OSCreateOption
        DiskSizeInGB = 128
    }
    $VirtualMachine = Set-AzVMOSDisk @setAzVMOSDiskSplat

    # Create the VM
    Write-LogMessage "Creating virtual machine: $VMName (this may take 5-10 minutes)" -Level "INFO"
    $newAzVMSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        VM                = $VirtualMachine
        Tag               = $Tags
    }
    $vmResult = New-AzVM @newAzVMSplat
    Write-LogMessage "Virtual machine created successfully!" -Level "SUCCESS"

    # Configure Azure AD Authentication Extension
    if ($EnableAzureAD) {
        Write-LogMessage "Installing Azure AD login extension..." -Level "INFO"
        try {
            $setAzVMExtensionSplat = @{
                ResourceGroupName  = $ResourceGroupName
                Location           = $LocationName
                VMName             = $VMName
                Name               = "AADLoginForWindows"
                Publisher          = "Microsoft.Azure.ActiveDirectory"
                ExtensionType      = "AADLoginForWindows"
                TypeHandlerVersion = "1.0"
            }
            Set-AzVMExtension @setAzVMExtensionSplat
            Write-LogMessage "Azure AD extension installed successfully" -Level "SUCCESS"

            # Configure role assignments for Azure AD groups
            Write-LogMessage "Configuring Azure AD group role assignments..." -Level "INFO"
            
            # Get VM details for role assignment
            $vmDetails = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
            $vmType = $vmDetails.Type

            # Assign Standard User role
            try {
                $standardUsersGroup = Get-AzADGroup -SearchString $StandardUsersGroupName -ErrorAction SilentlyContinue
                if ($standardUsersGroup) {
                    New-AzRoleAssignment -ObjectId $standardUsersGroup.Id -RoleDefinitionName 'Virtual Machine User Login' -ResourceGroupName $ResourceGroupName -ResourceName $VMName -ResourceType $vmType -ErrorAction SilentlyContinue
                    Write-LogMessage "Assigned 'Virtual Machine User Login' role to '$StandardUsersGroupName'" -Level "SUCCESS"
                } else {
                    Write-LogMessage "Azure AD group '$StandardUsersGroupName' not found - skipping standard user role assignment" -Level "WARN"
                }
            }
            catch {
                Write-LogMessage "Failed to assign standard user role: $($_.Exception.Message)" -Level "WARN"
            }

            # Assign Admin role
            try {
                $adminUsersGroup = Get-AzADGroup -SearchString $AdminUsersGroupName -ErrorAction SilentlyContinue
                if ($adminUsersGroup) {
                    New-AzRoleAssignment -ObjectId $adminUsersGroup.Id -RoleDefinitionName 'Virtual Machine Administrator Login' -ResourceGroupName $ResourceGroupName -ResourceName $VMName -ResourceType $vmType -ErrorAction SilentlyContinue
                    Write-LogMessage "Assigned 'Virtual Machine Administrator Login' role to '$AdminUsersGroupName'" -Level "SUCCESS"
                } else {
                    Write-LogMessage "Azure AD group '$AdminUsersGroupName' not found - skipping admin role assignment" -Level "WARN"
                }
            }
            catch {
                Write-LogMessage "Failed to assign admin role: $($_.Exception.Message)" -Level "WARN"
            }
        }
        catch {
            Write-LogMessage "Failed to install Azure AD extension: $($_.Exception.Message)" -Level "WARN"
            Write-LogMessage "VM will only support local authentication" -Level "WARN"
        }
    }

    # Configure Auto-Shutdown
    Write-LogMessage "Configuring auto-shutdown for $AutoShutdownTime" -Level "INFO"
    $setAzVMAutoShutdownSplat = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $VMName
        Enable            = $true
        Time              = $AutoShutdownTime
        TimeZone          = "Central Standard Time"
        Email             = $NotificationEmail
    }
    Set-AzVMAutoShutdown @setAzVMAutoShutdownSplat
    Write-LogMessage "Auto-shutdown configured successfully" -Level "SUCCESS"

    # Display connection information
    Write-Host ""
    Write-LogMessage "VM Creation Completed Successfully!" -Level "SUCCESS"
    Write-LogMessage "==================================" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    Write-LogMessage "Location: $LocationName" -Level "INFO"
    Write-LogMessage "VM Size: $VMSize (optimized for rendering)" -Level "INFO"
    Write-LogMessage "Operating System: Windows 10 with Office 365 ($WindowsVersion)" -Level "INFO"
    Write-LogMessage "Local Username: $VMAdminUser" -Level "INFO"
    Write-LogMessage "Azure AD Authentication: $EnableAzureAD" -Level "INFO"
    Write-LogMessage "Environment: $Environment" -Level "INFO"
    
    $fqdn = "${DNSNameLabel}.${LocationName}.cloudapp.azure.com"
    Write-LogMessage "FQDN: $fqdn" -Level "INFO"
    Write-LogMessage "Public IP: Static allocation" -Level "INFO"
    Write-LogMessage "RDP Connection: mstsc /v:$fqdn" -Level "INFO"
    
    Write-LogMessage "Virtual Network: $NetworkName" -Level "INFO"
    Write-LogMessage "VNet Address Space: $VnetAddressPrefix" -Level "INFO"
    Write-LogMessage "Subnet: $SubnetName ($SubnetAddressPrefix)" -Level "INFO"
    Write-LogMessage "Auto-shutdown: $AutoShutdownTime Central Standard Time" -Level "INFO"
    Write-LogMessage "Notification email: $NotificationEmail" -Level "INFO"
    
    if ($EnableAzureAD) {
        Write-Host ""
        Write-LogMessage "Azure AD Authentication Details:" -Level "INFO"
        Write-LogMessage "Standard Users Group: $StandardUsersGroupName" -Level "INFO"
        Write-LogMessage "Admin Users Group: $AdminUsersGroupName" -Level "INFO"
        Write-LogMessage "Users in these groups can login with: AzureAD\\username@domain.com" -Level "INFO"
    }
    
    Write-Host ""
    Write-LogMessage "Next Steps for Rendering Workload:" -Level "INFO"
    Write-LogMessage "1. Wait 3-5 minutes for VM to fully boot and configure" -Level "INFO"
    Write-LogMessage "2. Connect via RDP using local or Azure AD credentials" -Level "INFO"
    Write-LogMessage "3. Windows Movie Maker and Office 365 are ready for use" -Level "INFO"
    Write-LogMessage "4. Install additional rendering software as needed" -Level "INFO"
    Write-LogMessage "5. Configure GPU acceleration if available in the VM size" -Level "INFO"
    Write-LogMessage "6. Test Azure AD authentication (if enabled)" -Level "INFO"
    Write-LogMessage "7. VM can be rebooted anytime without scheduling" -Level "INFO"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw
}
