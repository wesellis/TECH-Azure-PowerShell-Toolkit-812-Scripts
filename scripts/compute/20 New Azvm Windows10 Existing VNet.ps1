#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create VM Windows 10 in Existing VNet with Azure AD Authentication

.DESCRIPTION
    Creates a Windows 10 Virtual Machine with Office 365 in an existing Azure Virtual Network
    Configures Azure AD authentication and role assignments for remote access
    Designed for TeamViewer and HyperV workloads
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER CustomerName
    Name of the customer/organization

.PARAMETER VMName
    Name for the virtual machine

.PARAMETER LocationName
    Azure region where resources will be created

.PARAMETER VnetName
    Name of the existing virtual network

.PARAMETER SubnetName
    Name of the subnet within the VNet

.PARAMETER VMSize
    Size of the virtual machine (default: Standard_B2MS)

.PARAMETER VMAdminUser
    Administrator username for the VM

.PARAMETER VMAdminPassword
    Administrator password for the VM (secure string)

.PARAMETER AutoShutdownTime
    Time for auto-shutdown in 24-hour format (default: 23:59)

.PARAMETER NotificationEmail
    Email address for shutdown notifications

.PARAMETER CreatePublicIP
    Whether to create a public IP address (default: true)

.PARAMETER WindowsVersion
    Windows 10 version/SKU (default: 20h2-evd-o365pp for Office 365)

.PARAMETER EnableAzureAD
    Enable Azure AD authentication (default: true)

.PARAMETER StandardUsersGroupName
    Azure AD group name for standard users (default: "Azure VM - Standard User")

.PARAMETER AdminUsersGroupName
    Azure AD group name for admin users (default: "Azure VM - Admins")

.EXAMPLE
    .\Create-Windows10VM-AAD.ps1 -CustomerName "CanadaComputing" -VMName "Client3" -LocationName "CanadaCentral" -VnetName "DC1_group-vnet" -SubnetName "DC1-subnet" -VMAdminUser "admin" -NotificationEmail "admin@company.com"

.EXAMPLE
    $securePassword = ConvertTo-SecureString "MyP@ssw0rd123!" -AsPlainText -Force
    .\Create-Windows10VM-AAD.ps1 -CustomerName "TestCompany" -VMName "TeamViewer-Client" -LocationName "EastUS" -VnetName "TestVNet" -SubnetName "default" -VMAdminUser "localadmin" -VMAdminPassword $securePassword -NotificationEmail "it@testcompany.com" -EnableAzureAD $true
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
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VnetName,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SubnetName,
    
    [Parameter()]
    [string]$VMSize = "Standard_B2MS",
    
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
    [bool]$CreatePublicIP = $true,
    
    [Parameter()]
    [ValidateSet("20h2-evd-o365pp", "21h1-evd-o365pp", "win10-21h2-ent", "win10-22h2-ent")]
    [string]$WindowsVersion = "20h2-evd-o365pp",
    
    [Parameter()]
    [bool]$EnableAzureAD = $true,
    
    [Parameter()]
    [string]$StandardUsersGroupName = "Azure VM - Standard User",
    
    [Parameter()]
    [string]$AdminUsersGroupName = "Azure VM - Admins"
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
    Write-LogMessage "Starting Windows 10 VM creation with Azure AD authentication..." -Level "INFO"
    Write-LogMessage "Customer: $CustomerName" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Location: $LocationName" -Level "INFO"
    Write-LogMessage "VNet: $VnetName" -Level "INFO"
    Write-LogMessage "Subnet: $SubnetName" -Level "INFO"
    Write-LogMessage "Windows Version: $WindowsVersion" -Level "INFO"
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
        "Environment"     = 'Production'
        "Application"     = 'TeamViewer'
        "Purpose"         = 'TeamViewer Remote Access'
        "Uptime"          = '24/7'
        "Workload"        = 'HyperV'
        "RebootCaution"   = 'Schedule a window first before rebooting'
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

    # Define VM configuration variables
    $ComputerName = $VMName
    $OSDiskCaching = "ReadWrite"
    $OSCreateOption = "FromImage"
    $GUID = [guid]::NewGuid()
    $OSDiskName = "${VMName}_OSDisk_1_$GUID"
    $DNSNameLabel = "${VMName}dns".ToLower()
    $NICPrefix = 'NIC1'
    $NICName = "${VMName}_${NICPrefix}".ToLower()
    $IPConfigName = "${VMName}${NICName}_IPConfig1".ToLower()
    $PublicIPAddressName = "${VMName}-ip"
    $PublicIPAllocation = 'Dynamic'
    $NSGName = "${VMName}-nsg"
    $ASGName = "${VMName}_ASG1"

    # Get existing VNet
    Write-LogMessage "Retrieving existing virtual network: $VnetName" -Level "INFO"
    $vnet = Get-AzVirtualNetwork -Name $VnetName -ErrorAction Stop
    Write-LogMessage "Virtual network found successfully" -Level "SUCCESS"

    # Get existing subnet
    Write-LogMessage "Retrieving subnet: $SubnetName" -Level "INFO"
    $VMsubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName -ErrorAction Stop
    Write-LogMessage "Subnet found successfully" -Level "SUCCESS"

    # Create Public IP (if requested)
    $PIP = $null
    if ($CreatePublicIP) {
        Write-LogMessage "Creating public IP address: $PublicIPAddressName" -Level "INFO"
        $newAzPublicIpAddressSplat = @{
            Name              = $PublicIPAddressName
            DomainNameLabel   = $DNSNameLabel
            ResourceGroupName = $ResourceGroupName
            Location          = $LocationName
            AllocationMethod  = $PublicIPAllocation
            Tag               = $Tags
        }
        $PIP = New-AzPublicIpAddress @newAzPublicIpAddressSplat
        Write-LogMessage "Public IP created successfully" -Level "SUCCESS"
    }

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

    # Create IP Configuration
    Write-LogMessage "Creating network interface IP configuration" -Level "INFO"
    $ipConfigParams = @{
        Name                     = $IPConfigName
        Subnet                   = $VMSubnet
        ApplicationSecurityGroup = $ASG
        Primary                  = $true
    }
    if ($PIP) {
        $ipConfigParams.PublicIpAddress = $PIP
    }
    $IPConfig1 = New-AzNetworkInterfaceIpConfig @ipConfigParams

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
    Write-LogMessage "Operating System: Windows 10 with Office 365 ($WindowsVersion)" -Level "INFO"
    Write-LogMessage "Local Username: $VMAdminUser" -Level "INFO"
    Write-LogMessage "Azure AD Authentication: $EnableAzureAD" -Level "INFO"
    
    if ($CreatePublicIP) {
        $fqdn = "${DNSNameLabel}.${LocationName}.cloudapp.azure.com"
        Write-LogMessage "FQDN: $fqdn" -Level "INFO"
        Write-LogMessage "RDP Connection: mstsc /v:$fqdn" -Level "INFO"
    } else {
        Write-LogMessage "No public IP created - connect via private IP or bastion" -Level "INFO"
    }
    
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
    Write-LogMessage "Next Steps for TeamViewer/HyperV Workload:" -Level "INFO"
    Write-LogMessage "1. Wait 3-5 minutes for VM to fully boot and configure" -Level "INFO"
    Write-LogMessage "2. Connect via RDP using local or Azure AD credentials" -Level "INFO"
    Write-LogMessage "3. Office 365 applications are pre-installed" -Level "INFO"
    Write-LogMessage "4. Install TeamViewer for remote access" -Level "INFO"
    Write-LogMessage "5. Configure Hyper-V role if needed" -Level "INFO"
    Write-LogMessage "6. Test Azure AD authentication (if enabled)" -Level "INFO"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw
}
