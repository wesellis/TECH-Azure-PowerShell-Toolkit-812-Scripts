#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create Windows 7 VM with New VNet

.DESCRIPTION
    Creates a Windows 7 Enterprise Virtual Machine with a new Azure Virtual Network
    Designed for TeamViewer testing on PowerShell 2.0 and Windows 7 environments
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

    CRITICAL SECURITY WARNING:
    Windows 7 reached end-of-life on January 14, 2020, and no longer receives security updates.
    This script is provided for legacy testing purposes only.
    Microsoft has discontinued Windows 7 VM images in Azure Marketplace.

.PARAMETER CustomerName
    Name of the customer/organization

.PARAMETER VMName
    Name for the virtual machine

.PARAMETER LocationName
    Azure region where resources will be created

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

.PARAMETER VnetAddressPrefix
    Address prefix for the new VNet (default: 10.0.0.0/16)

.PARAMETER SubnetAddressPrefix
    Address prefix for the subnet (default: 10.0.0.0/24)

.PARAMETER Environment
    Environment tag (default: Production)

.EXAMPLE
    .\Create-Windows7VM-NewVNet.ps1 -CustomerName "CanadaComputing" -VMName "GPO1" -LocationName "CanadaCentral" -VMAdminUser "admin" -NotificationEmail "admin@company.com"

.NOTES
    This script will likely fail because Windows 7 images are no longer available in Azure Marketplace.
    Consider using Windows 10 or Windows 11 for modern testing scenarios.
    If Windows 7 is absolutely required, consider using custom images or on-premises virtualization.

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
    [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$')]
    [string]$VnetAddressPrefix = "10.0.0.0/16",

    [Parameter()]
    [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$')]
    [string]$SubnetAddressPrefix = "10.0.0.0/24",

    [Parameter()]
    [ValidateSet("Dev", "Test", "Staging", "Production")]
    [string]$Environment = "Production"
)
    [string]$ErrorActionPreference = "Stop"

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    [string]$LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Output ""
    Write-LogMessage "==========================================" -Level "ERROR"
    Write-LogMessage "CRITICAL SECURITY WARNING" -Level "ERROR"
    Write-LogMessage "==========================================" -Level "ERROR"
    Write-LogMessage "Windows 7 reached END-OF-LIFE on January 14, 2020" -Level "ERROR"
    Write-LogMessage "This OS receives NO security updates from Microsoft" -Level "ERROR"
    Write-LogMessage "Windows 7 images are NO LONGER AVAILABLE in Azure" -Level "ERROR"
    Write-LogMessage "This script will likely FAIL due to discontinued images" -Level "ERROR"
    Write-LogMessage "==========================================" -Level "ERROR"
    Write-Output ""

    Write-LogMessage "Starting Windows 7 VM creation attempt..." -Level "WARN"
    Write-LogMessage "Customer: $CustomerName" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Location: $LocationName" -Level "INFO"
    Write-LogMessage "VM Size: $VMSize" -Level "INFO"
    Write-LogMessage "Environment: $Environment" -Level "INFO"
    $context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }

    Write-LogMessage "Using Azure subscription: $($context.Subscription.Name)" -Level "INFO"
    [string]$ResourceGroupName = "${CustomerName}_${VMName}_RG"
    [string]$datetime = [System.DateTime]::Now.ToString("yyyy_MM_dd_HH_mm_ss")

    [hashtable]$Tags = @{
        "Autoshutdown"      = 'ON'
        "Createdby"         = $context.Account.Id
        "CustomerName"      = $CustomerName
        "DateTimeCreated"   = $datetime
        "Environment"       = $Environment
        "Application"       = 'TeamViewer'
        "Purpose"           = 'TeamViewer testing on PS2.0 and Win7'
        "Uptime"            = '24/7'
        "Workload"          = 'TeamViewer'
        "VMGeneration"      = 'Gen2'
        "RebootCaution"     = 'Schedule a window first before rebooting'
        "VMSize"            = $VMSize
        "Location"          = $LocationName
        "ApprovedBy"        = $context.Account.Id
        "ApprovedOn"        = (Get-Date).ToString("yyyy-MM-dd")
        "SecurityWarning"   = "END-OF-LIFE OS - DISCONTINUED"
        "OSStatus"          = "No Security Updates"
        "ImageAvailability" = "DISCONTINUED in Azure"
    }

    Write-LogMessage "Creating resource group: $ResourceGroupName" -Level "INFO"
    $NewAzResourceGroupSplat = @{
        Name     = $ResourceGroupName
        Location = $LocationName
        Tag      = $Tags
    }
    [string]$ResourceGroup = New-AzResourceGroup @newAzResourceGroupSplat
    Write-LogMessage "Resource group created successfully" -Level "SUCCESS"
    [string]$ComputerName = $VMName
    [string]$OSDiskCaching = "ReadWrite"
    [string]$OSCreateOption = "FromImage"
    [string]$GUID = [guid]::NewGuid()
    [string]$OSDiskName = "${VMName}_OSDisk_1_$GUID"
    [string]$DNSNameLabel = "${VMName}dns".ToLower()
    [string]$NetworkName = "${VMName}_group-vnet"
    [string]$NICPrefix = 'NIC1'
    [string]$NICName = "${VMName}_${NICPrefix}".ToLower()
    [string]$IPConfigName = "${VMName}${NICName}_IPConfig1".ToLower()
    [string]$PublicIPAddressName = "${VMName}-ip"
    [string]$SubnetName = "${VMName}-subnet"
    [string]$NSGName = "${VMName}-nsg"
    [string]$ASGName = "${VMName}_ASG1"

    Write-LogMessage "Creating virtual network: $NetworkName" -Level "INFO"
    Write-LogMessage "VNet Address Prefix: $VnetAddressPrefix" -Level "INFO"
    Write-LogMessage "Subnet Address Prefix: $SubnetAddressPrefix" -Level "INFO"
    $NewAzVirtualNetworkSubnetConfigSplat = @{
        Name          = $SubnetName
        AddressPrefix = $SubnetAddressPrefix
    }
    [string]$SingleSubnet = New-AzVirtualNetworkSubnetConfig @newAzVirtualNetworkSubnetConfigSplat
    $NewAzVirtualNetworkSplat = @{
        Name              = $NetworkName
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        AddressPrefix     = $VnetAddressPrefix
        Subnet            = $SingleSubnet
        Tag               = $Tags
    }
    [string]$Vnet = New-AzVirtualNetwork @newAzVirtualNetworkSplat
    Write-LogMessage "Virtual network created successfully" -Level "SUCCESS"

    Write-LogMessage "Creating static public IP address: $PublicIPAddressName" -Level "INFO"
    $NewAzPublicIpAddressSplat = @{
        Name              = $PublicIPAddressName
        DomainNameLabel   = $DNSNameLabel
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        AllocationMethod  = 'Static'
        Tag               = $Tags
    }
    [string]$PIP = New-AzPublicIpAddress @newAzPublicIpAddressSplat
    Write-LogMessage "Public IP created successfully" -Level "SUCCESS"

    Write-LogMessage "Retrieving current public IP for security rules..." -Level "INFO"
    try {
    [string]$SourceAddressPrefix = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -TimeoutSec 10).Content.Trim()
    [string]$SourceAddressPrefixCIDR = "${SourceAddressPrefix}/32"
        Write-LogMessage "Current public IP: $SourceAddressPrefix" -Level "INFO"
    }
    catch {
        Write-LogMessage "Could not retrieve public IP, using 0.0.0.0/0 (less secure)" -Level "WARN"
    [string]$SourceAddressPrefixCIDR = "0.0.0.0/0"
    }

    Write-LogMessage "Creating application security group: $ASGName" -Level "INFO"
    $NewAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $ASGName
        Location          = $LocationName
        Tag               = $Tags
    }
    [string]$ASG = New-AzApplicationSecurityGroup @newAzApplicationSecurityGroupSplat
    Write-LogMessage "Application security group created successfully" -Level "SUCCESS"
    $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $Vnet

    Write-LogMessage "Creating network interface IP configuration" -Level "INFO"
    $NewAzNetworkInterfaceIpConfigSplat = @{
        Name                     = $IPConfigName
        Subnet                   = $Subnet
        PublicIpAddress          = $PIP
        ApplicationSecurityGroup = $ASG
        Primary                  = $true
    }
    [string]$IPConfig1 = New-AzNetworkInterfaceIpConfig @newAzNetworkInterfaceIpConfigSplat

    Write-LogMessage "Creating network security group rule for RDP access" -Level "INFO"
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
    [string]$rule1 = New-AzNetworkSecurityRuleConfig @newAzNetworkSecurityRuleConfigSplat

    Write-LogMessage "Creating network security group: $NSGName" -Level "INFO"
    $NewAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        Name              = $NSGName
        SecurityRules     = $rule1
        Tag               = $Tags
    }
    [string]$NSG = New-AzNetworkSecurityGroup @newAzNetworkSecurityGroupSplat
    Write-LogMessage "Network security group created successfully" -Level "SUCCESS"

    Write-LogMessage "Creating network interface: $NICName" -Level "INFO"
    $NewAzNetworkInterfaceSplat = @{
        Name                   = $NICName
        ResourceGroupName      = $ResourceGroupName
        Location               = $LocationName
        NetworkSecurityGroupId = $NSG.Id
        IpConfiguration        = $IPConfig1
        Tag                    = $Tags
    }
    [string]$NIC = New-AzNetworkInterface @newAzNetworkInterfaceSplat
    Write-LogMessage "Network interface created successfully" -Level "SUCCESS"
    [string]$Credential = New-Object PSCredential ($VMAdminUser, $VMAdminPassword)

    Write-LogMessage "Creating VM configuration" -Level "INFO"
    $NewAzVMConfigSplat = @{
        VMName = $VMName
        VMSize = $VMSize
        Tags   = $Tags
    }
    [string]$VirtualMachine = New-AzVMConfig @newAzVMConfigSplat
    $SetAzVMOperatingSystemSplat = @{
        VM           = $VirtualMachine
        Windows      = $true
        ComputerName = $ComputerName
        Credential   = $Credential
    }
    [string]$VirtualMachine = Set-AzVMOperatingSystem @setAzVMOperatingSystemSplat
    [string]$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id

    Write-LogMessage "Attempting to configure VM source image (Windows 7 Enterprise)" -Level "WARN"
    Write-LogMessage "WARNING: This will likely fail - Windows 7 images discontinued" -Level "ERROR"

    try {
        Write-LogMessage "Checking for Windows 7 image availability..." -Level "INFO"
    $SetAzVMSourceImageSplat = @{
            VM            = $VirtualMachine
            PublisherName = "microsoftwindowsdesktop"
            Offer         = "windows-7"
            Skus          = "win7-enterprise"
            Version       = "latest"
        }
    [string]$VirtualMachine = Set-AzVMSourceImage @setAzVMSourceImageSplat
        Write-LogMessage "VM source image configured (unexpected success!)" -Level "SUCCESS"
    }
    catch {
        Write-LogMessage "EXPECTED FAILURE: Windows 7 images are not available" -Level "ERROR"
        Write-LogMessage "Error details: $($_.Exception.Message)" -Level "ERROR"
        Write-LogMessage "" -Level "ERROR"
        Write-LogMessage "SOLUTION OPTIONS:" -Level "WARN"
        Write-LogMessage "1. Use Windows 10 instead (recommended)" -Level "WARN"
        Write-LogMessage "2. Use Windows 11 for modern testing" -Level "WARN"
        Write-LogMessage "3. Create custom Windows 7 image (complex)" -Level "WARN"
        Write-LogMessage "4. Use on-premises virtualization for legacy testing" -Level "WARN"

        throw "Windows 7 VM images are not available in Azure Marketplace. Consider using Windows 10 or 11 instead."
    }
    $SetAzVMOSDiskSplat = @{
        VM           = $VirtualMachine
        Name         = $OSDiskName
        Caching      = $OSDiskCaching
        CreateOption = $OSCreateOption
        DiskSizeInGB = 128
    }
    [string]$VirtualMachine = Set-AzVMOSDisk @setAzVMOSDiskSplat

    Write-LogMessage "Creating virtual machine: $VMName (this may take 5-10 minutes)" -Level "INFO"
    $NewAzVMSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        VM                = $VirtualMachine
        Tag               = $Tags
    }
    [string]$VmResult = New-AzVM @newAzVMSplat
    Write-LogMessage "Virtual machine created successfully!" -Level "SUCCESS"

    Write-LogMessage "Configuring auto-shutdown for $AutoShutdownTime" -Level "INFO"
    $SetAzVMAutoShutdownSplat = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $VMName
        Enable            = $true
        Time              = $AutoShutdownTime
        TimeZone          = "Central Standard Time"
        Email             = $NotificationEmail
    }
    Set-AzVMAutoShutdown @setAzVMAutoShutdownSplat
    Write-LogMessage "Auto-shutdown configured successfully" -Level "SUCCESS"

    Write-Output ""
    Write-LogMessage "VM Creation Completed Successfully!" -Level "SUCCESS"
    Write-LogMessage "==================================" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    Write-LogMessage "Location: $LocationName" -Level "INFO"
    Write-LogMessage "Operating System: Windows 7 Enterprise (END-OF-LIFE)" -Level "ERROR"
    Write-LogMessage "Username: $VMAdminUser" -Level "INFO"
    [string]$fqdn = "${DNSNameLabel}.${LocationName}.cloudapp.azure.com"
    Write-LogMessage "FQDN: $fqdn" -Level "INFO"
    Write-LogMessage "RDP Connection: mstsc /v:$fqdn" -Level "INFO"

    Write-LogMessage "Virtual Network: $NetworkName" -Level "INFO"
    Write-LogMessage "Auto-shutdown: $AutoShutdownTime Central Standard Time" -Level "INFO"
    Write-LogMessage "Notification email: $NotificationEmail" -Level "INFO"

    Write-Output ""
    Write-LogMessage "CRITICAL SECURITY REMINDERS:" -Level "ERROR"
    Write-LogMessage "1. Windows 7 is END-OF-LIFE - NO security updates" -Level "ERROR"
    Write-LogMessage "2. Isolate this VM completely from internet access" -Level "ERROR"
    Write-LogMessage "3. Use only for essential legacy testing" -Level "ERROR"
    Write-LogMessage "4. Plan immediate migration to supported OS" -Level "ERROR"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"

    if ($_.Exception.Message -like "*Windows 7*" -or $_.Exception.Message -like "*image*" -or $_.Exception.Message -like "*not available*") {
        Write-Output ""
        Write-LogMessage "EXPECTED FAILURE - Windows 7 Images Discontinued" -Level "WARN"
        Write-LogMessage "=============================================" -Level "WARN"
        Write-LogMessage "This failure is expected because:" -Level "WARN"
        Write-LogMessage "1. Windows 7 reached end-of-life in January 2020" -Level "WARN"
        Write-LogMessage "2. Microsoft discontinued Windows 7 VM images" -Level "WARN"
        Write-LogMessage "3. No security updates are available" -Level "WARN"
        Write-Output ""
        Write-LogMessage "RECOMMENDED ALTERNATIVES:" -Level "INFO"
        Write-LogMessage "• Use Windows 10 for modern testing" -Level "INFO"
        Write-LogMessage "• Use Windows 11 for latest features" -Level "INFO"
        Write-LogMessage "• Use Windows Server 2019/2022 for server workloads" -Level "INFO"
        Write-LogMessage "• For legacy testing, consider on-premises virtualization" -Level "INFO"
    }

    Write-Error $_.Exception.Message
    throw`n}
