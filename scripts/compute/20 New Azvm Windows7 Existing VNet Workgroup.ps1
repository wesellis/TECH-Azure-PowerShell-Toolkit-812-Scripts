#Requires -Version 7.0
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create VM Windows 7 in Existing VNet Workgroup

.DESCRIPTION
    Creates a Windows 7 Enterprise Virtual Machine in an existing Azure Virtual Network
    Designed for Exchange Hybrid mailbox migration scenarios with Outlook
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

    IMPORTANT SECURITY WARNING:
    Windows 7 reached end-of-life on January 14, 2020, and no longer receives security updates.
    This script is provided for legacy application support only. Consider upgrading to supported OS versions.

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

.PARAMETER WindowsEdition
    Windows 7 edition (default: win7-enterprise)

.EXAMPLE
    .\Create-Windows7VM.ps1 -CustomerName "CanadaComputing" -VMName "Win7" -LocationName "CanadaCentral" -VnetName "DC01_group-vnet" -SubnetName "DC01-subnet" -VMAdminUser "admin" -NotificationEmail "admin@company.com"

.NOTES
    Windows 7 is no longer supported by Microsoft and should only be used for legacy applications.
    Consider migration to Windows 10 or Windows 11 for better security and support.
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
    [ValidateSet("win7-enterprise")]
    [string]$WindowsEdition = "win7-enterprise"
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
    # Display security warning
    Write-LogMessage "SECURITY WARNING: Windows 7 reached end-of-life on January 14, 2020" -Level "WARN"
    Write-LogMessage "This OS no longer receives security updates from Microsoft" -Level "WARN"
    Write-LogMessage "Use only for legacy applications - consider upgrading to supported OS" -Level "WARN"
    Write-Host ""
    
    Write-LogMessage "Starting Windows 7 VM creation process..." -Level "INFO"
    Write-LogMessage "Customer: $CustomerName" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Location: $LocationName" -Level "INFO"
    Write-LogMessage "VNet: $VnetName" -Level "INFO"
    Write-LogMessage "Subnet: $SubnetName" -Level "INFO"
    Write-LogMessage "Windows Edition: $WindowsEdition" -Level "INFO"

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
        "Application"     = 'Outlook'
        "Purpose"         = 'Mailbox Migration using Exchange Hybrid'
        "Uptime"          = '24/7'
        "Workload"        = 'Outlook'
        "RebootCaution"   = 'Schedule a window first before rebooting'
        "VMSize"          = $VMSize
        "Location"        = $LocationName
        "ApprovedBy"      = $context.Account.Id
        "ApprovedOn"      = (Get-Date).ToString("yyyy-MM-dd")
        "WindowsVersion"  = $WindowsEdition
        "SecurityWarning" = "End-of-Life OS - No Security Updates"
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

    # Create VM Configuration (without managed identity for Windows 7)
    Write-LogMessage "Creating VM configuration" -Level "INFO"
    $newAzVMConfigSplat = @{
        VMName = $VMName
        VMSize = $VMSize
        Tags   = $Tags
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
    Write-LogMessage "Configuring VM source image (Windows 7 Enterprise)" -Level "INFO"
    Write-LogMessage "WARNING: Verifying Windows 7 image availability..." -Level "WARN"
    
    # Check if Windows 7 images are still available
    try {
        $availableImages = Get-AzVMImagePublisher -Location $LocationName | Where-Object { $_.PublisherName -like "*microsoft*" }
        $win7Publisher = $availableImages | Where-Object { $_.PublisherName -eq "microsoftwindowsdesktop" }
        
        if (-not $win7Publisher) {
            throw "Windows 7 images may no longer be available in Azure Marketplace"
        }
        
        $setAzVMSourceImageSplat = @{
            VM            = $VirtualMachine
            PublisherName = "microsoftwindowsdesktop"
            Offer         = "windows-7"
            Skus          = $WindowsEdition
            Version       = "latest"
        }
        $VirtualMachine = Set-AzVMSourceImage @setAzVMSourceImageSplat
        Write-LogMessage "VM source image configured successfully" -Level "SUCCESS"
    }
    catch {
        Write-LogMessage "ERROR: Windows 7 images are no longer available in Azure Marketplace" -Level "ERROR"
        Write-LogMessage "Microsoft discontinued Windows 7 VM images due to end-of-life status" -Level "ERROR"
        Write-LogMessage "Consider using Windows 10 or Windows 11 instead" -Level "ERROR"
        throw "Windows 7 VM images are not available. Use a supported Windows version."
    }

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
    Write-LogMessage "Operating System: Windows 7 Enterprise (END-OF-LIFE)" -Level "WARN"
    Write-LogMessage "Username: $VMAdminUser" -Level "INFO"
    
    if ($CreatePublicIP) {
        $fqdn = "${DNSNameLabel}.${LocationName}.cloudapp.azure.com"
        Write-LogMessage "FQDN: $fqdn" -Level "INFO"
        Write-LogMessage "RDP Connection: mstsc /v:$fqdn" -Level "INFO"
    } else {
        Write-LogMessage "No public IP created - connect via private IP or bastion" -Level "INFO"
    }
    
    Write-LogMessage "Auto-shutdown: $AutoShutdownTime Central Standard Time" -Level "INFO"
    Write-LogMessage "Notification email: $NotificationEmail" -Level "INFO"
    
    Write-Host ""
    Write-LogMessage "CRITICAL SECURITY REMINDERS:" -Level "ERROR"
    Write-LogMessage "1. Windows 7 is END-OF-LIFE and receives NO security updates" -Level "ERROR"
    Write-LogMessage "2. Isolate this VM from internet and untrusted networks" -Level "ERROR"
    Write-LogMessage "3. Use only for legacy applications that cannot be upgraded" -Level "ERROR"
    Write-LogMessage "4. Plan migration to Windows 10/11 as soon as possible" -Level "ERROR"
    
    Write-Host ""
    Write-LogMessage "Next Steps for Exchange Hybrid Migration:" -Level "INFO"
    Write-LogMessage "1. Wait 3-5 minutes for VM to fully boot" -Level "INFO"
    Write-LogMessage "2. Connect via RDP using the credentials provided" -Level "INFO"
    Write-LogMessage "3. Install Outlook and configure with source mailbox" -Level "INFO"
    Write-LogMessage "4. Set up the hybrid Exchange connection" -Level "INFO"
    Write-LogMessage "5. Begin mailbox migration process" -Level "INFO"
    Write-LogMessage "6. Plan to migrate to supported OS after migration complete" -Level "INFO"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw
}
