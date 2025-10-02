#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create Windows 10 VM for DevOps/Development

.DESCRIPTION
    Creates a Windows 10 Virtual Machine with Office 365 optimized for development work
    Configures Azure AD authentication and role assignments for development teams
    Designed for Visual Studio/IDE workloads with appropriate VM sizing
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER CustomerName
    Name of the customer/organization

.PARAMETER VMName
    Name for the virtual machine

.PARAMETER LocationName
    Azure region where resources will be created

.PARAMETER VMSize
    Size of the virtual machine (default: Standard_D4s_v3 for development workloads)

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
    Environment tag (default: Production)

.EXAMPLE
    .\Create-DevOpsVM.ps1 -CustomerName "CanadaComputing" -VMName "DEVOPS1" -LocationName "CanadaCentral" -VMAdminUser "devadmin" -NotificationEmail "admin@company.com"

.EXAMPLE
    [string]$SecurePassword = ConvertTo-SecureString "MyP@ssw0rd123!" -AsPlainText -Force
    .\Create-DevOpsVM.ps1 -CustomerName "TechCompany" -VMName "DevStation" -LocationName "EastUS" -VMAdminUser "developer" -VMAdminPassword $SecurePassword -NotificationEmail "dev-team@techcompany.com" -VMSize "Standard_D8s_v3"

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
    [string]$VMSize = "Standard_D4s_v3",

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
    [string]$Environment = "Production"
)
    [string]$ErrorActionPreference = 'Stop'

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    [string]$LogEntry = "$timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}

function Generate-Password {
    param([int]$Length = 16)
    [string]$characters = 'abcdefghkmnprstuvwxyzABCDEFGHKMNPRSTUVWXYZ23456789!@#$%&*'
    [string]$password = ""
    for ($i = 0; $i -lt $Length; $i++) {
    [string]$password += $characters[(Get-Random -Maximum $characters.Length)]
    }
    return $password
}

try {
    Write-LogMessage "Starting Windows 10 DevOps VM creation..." -Level "INFO"
    Write-LogMessage "Customer: $CustomerName" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Location: $LocationName" -Level "INFO"
    Write-LogMessage "VM Size: $VMSize (optimized for development)" -Level "INFO"
    Write-LogMessage "Windows Version: $WindowsVersion" -Level "INFO"
    Write-LogMessage "Environment: $Environment" -Level "INFO"
    Write-LogMessage "Azure AD Authentication: $EnableAzureAD" -Level "INFO"
    [string]$context = Get-AzContext
    if (-not $context) {
        throw "No Azure context found. Please run Connect-AzAccount first."
    }

    Write-LogMessage "Using Azure subscription: $($context.Subscription.Name)" -Level "INFO"
    [string]$ResourceGroupName = "${CustomerName}_${VMName}_RG"
    [string]$datetime = [System.DateTime]::Now.ToString("yyyy_MM_dd_HH_mm_ss")

    [hashtable]$Tags = @{
        "Autoshutdown"    = 'ON'
        "Createdby"       = $context.Account.Id
        "CustomerName"    = $CustomerName
        "DateTimeCreated" = $datetime
        "Environment"     = $Environment
        "Application"     = 'Visual Studio'
        "Purpose"         = 'Internal Dev Team'
        "Uptime"          = '16/7 on Weekends'
        "Workload"        = 'Visual Studio/IDE'
        "RebootCaution"   = 'Schedule a window first before rebooting'
        "VMSize"          = $VMSize
        "Location"        = $LocationName
        "ApprovedBy"      = $context.Account.Id
        "ApprovedOn"      = (Get-Date).ToString("yyyy-MM-dd")
        "WindowsVersion"  = $WindowsVersion
        "AzureAD"         = $EnableAzureAD.ToString()
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
    [string]$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $Vnet

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

    Write-LogMessage "Creating VM configuration with system-assigned managed identity" -Level "INFO"
    $NewAzVMConfigSplat = @{
        VMName       = $VMName
        VMSize       = $VMSize
        Tags         = $Tags
        IdentityType = 'SystemAssigned'
    }
    [string]$VirtualMachine = New-AzVMConfig @newAzVMConfigSplat
    $SetAzVMOperatingSystemSplat = @{
        VM               = $VirtualMachine
        Windows          = $true
        ComputerName     = $ComputerName
        Credential       = $Credential
        ProvisionVMAgent = $true
    }
    [string]$VirtualMachine = Set-AzVMOperatingSystem @setAzVMOperatingSystemSplat
    [string]$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id

    Write-LogMessage "Configuring VM source image (Windows 10 with Office 365: $WindowsVersion)" -Level "INFO"
    $SetAzVMSourceImageSplat = @{
        VM            = $VirtualMachine
        PublisherName = "MicrosoftWindowsDesktop"
        Offer         = "office-365"
        Skus          = $WindowsVersion
        Version       = "latest"
    }
    [string]$VirtualMachine = Set-AzVMSourceImage @setAzVMSourceImageSplat
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

    if ($EnableAzureAD) {
        Write-LogMessage "Installing Azure AD login extension..." -Level "INFO"
        try {
    $SetAzVMExtensionSplat = @{
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

            Write-LogMessage "Configuring Azure AD group role assignments..." -Level "INFO"
    [string]$VmDetails = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
    [string]$VmType = $VmDetails.Type

            try {
    [string]$StandardUsersGroup = Get-AzADGroup -SearchString $StandardUsersGroupName -ErrorAction SilentlyContinue
                if ($StandardUsersGroup) {
                    New-AzRoleAssignment -ObjectId $StandardUsersGroup.Id -RoleDefinitionName 'Virtual Machine User Login' -ResourceGroupName $ResourceGroupName -ResourceName $VMName -ResourceType $VmType -ErrorAction SilentlyContinue
                    Write-LogMessage "Assigned 'Virtual Machine User Login' role to '$StandardUsersGroupName'" -Level "SUCCESS"
                } else {
                    Write-LogMessage "Azure AD group '$StandardUsersGroupName' not found - skipping standard user role assignment" -Level "WARN"
                }
            }
            catch {
                Write-LogMessage "Failed to assign standard user role: $($_.Exception.Message)" -Level "WARN"
            }

            try {
    [string]$AdminUsersGroup = Get-AzADGroup -SearchString $AdminUsersGroupName -ErrorAction SilentlyContinue
                if ($AdminUsersGroup) {
                    New-AzRoleAssignment -ObjectId $AdminUsersGroup.Id -RoleDefinitionName 'Virtual Machine Administrator Login' -ResourceGroupName $ResourceGroupName -ResourceName $VMName -ResourceType $VmType -ErrorAction SilentlyContinue
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
    Write-LogMessage "VM Size: $VMSize (optimized for development)" -Level "INFO"
    Write-LogMessage "Operating System: Windows 10 with Office 365 ($WindowsVersion)" -Level "INFO"
    Write-LogMessage "Local Username: $VMAdminUser" -Level "INFO"
    Write-LogMessage "Azure AD Authentication: $EnableAzureAD" -Level "INFO"
    Write-LogMessage "Environment: $Environment" -Level "INFO"
    [string]$fqdn = "${DNSNameLabel}.${LocationName}.cloudapp.azure.com"
    Write-LogMessage "FQDN: $fqdn" -Level "INFO"
    Write-LogMessage "Public IP: Static allocation" -Level "INFO"
    Write-LogMessage "RDP Connection: mstsc /v:$fqdn" -Level "INFO"

    Write-LogMessage "Virtual Network: $NetworkName" -Level "INFO"
    Write-LogMessage "VNet Address Space: $VnetAddressPrefix" -Level "INFO"
    Write-LogMessage "Subnet: $SubnetName ($SubnetAddressPrefix)" -Level "INFO"
    Write-LogMessage "Auto-shutdown: $AutoShutdownTime Central Standard Time" -Level "INFO"
    Write-LogMessage "Notification email: $NotificationEmail" -Level "INFO"

    if ($EnableAzureAD) {
        Write-Output ""
        Write-LogMessage "Azure AD Authentication Details:" -Level "INFO"
        Write-LogMessage "Standard Users Group: $StandardUsersGroupName" -Level "INFO"
        Write-LogMessage "Admin Users Group: $AdminUsersGroupName" -Level "INFO"
        Write-LogMessage "Users in these groups can login with: AzureAD\\username@domain.com" -Level "INFO"
    }

    Write-Output ""
    Write-LogMessage "Next Steps for Development Workload:" -Level "INFO"
    Write-LogMessage "1. Wait 3-5 minutes for VM to fully boot and configure" -Level "INFO"
    Write-LogMessage "2. Connect via RDP using local or Azure AD credentials" -Level "INFO"
    Write-LogMessage "3. Office 365 applications are pre-installed and ready" -Level "INFO"
    Write-LogMessage "4. Install Visual Studio or preferred IDE" -Level "INFO"
    Write-LogMessage "5. Configure development tools and environments" -Level "INFO"
    Write-LogMessage "6. Set up source control (Git, Azure DevOps, etc.)" -Level "INFO"
    Write-LogMessage "7. Test Azure AD authentication (if enabled)" -Level "INFO"
    Write-LogMessage "8. Schedule maintenance windows before rebooting" -Level "INFO"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw`n}
