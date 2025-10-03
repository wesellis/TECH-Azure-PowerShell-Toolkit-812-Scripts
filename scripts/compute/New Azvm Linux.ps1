#Requires -Version 7.4
#Requires -Modules Az.Compute
#Requires -Modules Az.Network
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create Linux VM for Splunk

.DESCRIPTION
    Creates an Ubuntu Linux Virtual Machine optimized for Splunk workloads
    Configures networking, security groups, and auto-shutdown
    Designed for Splunk forwarding and monitoring services
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER CustomerName
    Name of the customer/organization

.PARAMETER VMName
    Name for the virtual machine

.PARAMETER LocationName
    Azure region where resources will be created

.PARAMETER VMSize
    Size of the virtual machine (default: Standard_D2ds_v4 for Splunk workloads)

.PARAMETER VMAdminUser
    Administrator username for the VM

.PARAMETER VMAdminPassword
    Administrator password for the VM (secure string) - for password authentication

.PARAMETER SSHPublicKey
    SSH public key for key-based authentication (recommended)

.PARAMETER AuthenticationType
    Authentication type: Password or SSH (default: SSH)

.PARAMETER AutoShutdownTime
    Time for auto-shutdown in 24-hour format (default: 23:59)

.PARAMETER NotificationEmail
    Email address for shutdown notifications

.PARAMETER VnetAddressPrefix
    Address prefix for the new VNet (default: 10.0.0.0/16)

.PARAMETER SubnetAddressPrefix
    Address prefix for the subnet (default: 10.0.0.0/24)

.PARAMETER UbuntuVersion
    Ubuntu version to deploy (default: 20_04-lts-gen2)

.PARAMETER Environment
    Environment tag (default: Dev)

.PARAMETER DiskSizeGB
    OS disk size in GB (default: 64)

.EXAMPLE
    .\Create-SplunkVM.ps1 -CustomerName "CanadaComputing" -VMName "Splunk01" -LocationName "CanadaCentral" -VMAdminUser "splunkadmin" -SSHPublicKey "ssh-rsa AAAAB3..." -NotificationEmail "admin@company.com"

.EXAMPLE
    [string]$SecurePassword = ConvertTo-SecureString "MyP@ssw0rd123!" -AsPlainText -Force
    .\Create-SplunkVM.ps1 -CustomerName "MonitoringCorp" -VMName "SplunkForwarder" -LocationName "EastUS" -VMAdminUser "ubuntu" -VMAdminPassword $SecurePassword -AuthenticationType "Password" -NotificationEmail "ops@monitoringcorp.com"

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
    [string]$VMSize = "Standard_D2ds_v4",

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMAdminUser,

    [Parameter()]
    [SecureString]$VMAdminPassword,

    [Parameter()]
    [string]$SSHPublicKey,

    [Parameter()]
    [ValidateSet("Password", "SSH")]
    [string]$AuthenticationType = "SSH",

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
    [ValidateSet("18_04-lts-gen2", "20_04-lts-gen2", "22_04-lts-gen2")]
    [string]$UbuntuVersion = "20_04-lts-gen2",

    [Parameter()]
    [ValidateSet("Dev", "Test", "Staging", "Production")]
    [string]$Environment = "Dev",

    [Parameter()]
    [ValidateRange(30, 1024)]
    [int]$DiskSizeGB = 64
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
    if ($AuthenticationType -eq "SSH" -and [string]::IsNullOrEmpty($SSHPublicKey)) {
        throw "SSH public key is required when using SSH authentication"
    }
    if ($AuthenticationType -eq "Password" -and -not $VMAdminPassword) {
        throw "Password is required when using password authentication"
    }

    Write-LogMessage "Starting Linux Ubuntu VM creation for Splunk..." -Level "INFO"
    Write-LogMessage "Customer: $CustomerName" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"
    Write-LogMessage "Location: $LocationName" -Level "INFO"
    Write-LogMessage "VM Size: $VMSize (optimized for Splunk)" -Level "INFO"
    Write-LogMessage "Ubuntu Version: $UbuntuVersion" -Level "INFO"
    Write-LogMessage "Authentication: $AuthenticationType" -Level "INFO"
    Write-LogMessage "Environment: $Environment" -Level "INFO"
    $context = Get-AzContext
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
        "Application"     = 'Splunk'
        "Purpose"         = 'Splunk - Forwarding for monitoring'
        "Uptime"          = '24/7'
        "Workload"        = 'Splunk'
        "RebootCaution"   = 'Reboot any time'
        "VMSize"          = $VMSize
        "Location"        = $LocationName
        "ApprovedBy"      = $context.Account.Id
        "ApprovedOn"      = (Get-Date).ToString("yyyy-MM-dd")
        "Access"          = "SSH"
        "OS"              = "Ubuntu Linux"
        "UbuntuVersion"   = $UbuntuVersion
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

    Write-LogMessage "Creating network security group rules" -Level "INFO"
    [string]$SshRule = New-AzNetworkSecurityRuleConfig -Name 'SSH-rule' -Description 'Allow SSH' -Access 'Allow' -Protocol 'Tcp' -Direction 'Inbound' -Priority 100 -SourceAddressPrefix $SourceAddressPrefixCIDR -SourcePortRange '*' -DestinationPortRange '22' -DestinationApplicationSecurityGroup $ASG
    [string]$SplunkWebRule = New-AzNetworkSecurityRuleConfig -Name 'Splunk-Web-rule' -Description 'Allow Splunk Web' -Access 'Allow' -Protocol 'Tcp' -Direction 'Inbound' -Priority 110 -SourceAddressPrefix $SourceAddressPrefixCIDR -SourcePortRange '*' -DestinationPortRange '8000' -DestinationApplicationSecurityGroup $ASG
    [string]$SplunkForwarderRule = New-AzNetworkSecurityRuleConfig -Name 'Splunk-Forwarder-rule' -Description 'Allow Splunk Forwarder' -Access 'Allow' -Protocol 'Tcp' -Direction 'Inbound' -Priority 120 -SourceAddressPrefix $SubnetAddressPrefix -SourcePortRange '*' -DestinationPortRange '9997' -DestinationApplicationSecurityGroup $ASG

    Write-LogMessage "Creating network security group: $NSGName" -Level "INFO"
    $NewAzNetworkSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Location          = $LocationName
        Name              = $NSGName
        SecurityRules     = $SshRule, $SplunkWebRule, $SplunkForwarderRule
        Tag               = $Tags
    }
    [string]$NSG = New-AzNetworkSecurityGroup @newAzNetworkSecurityGroupSplat
    Write-LogMessage "Network security group created with SSH, Splunk Web (8000), and Forwarder (9997) rules" -Level "SUCCESS"

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

    if ($AuthenticationType -eq "Password") {
    [string]$Credential = New-Object PSCredential ($VMAdminUser, $VMAdminPassword)
        Write-LogMessage "Using password authentication" -Level "INFO"
    } else {
    [string]$DummyPassword = ConvertTo-SecureString "NotUsed" -AsPlainText -Force
    [string]$Credential = New-Object PSCredential ($VMAdminUser, $DummyPassword)
        Write-LogMessage "Using SSH key authentication" -Level "INFO"
    }

    Write-LogMessage "Creating VM configuration" -Level "INFO"
    $NewAzVMConfigSplat = @{
        VMName = $VMName
        VMSize = $VMSize
        Tags   = $Tags
    }
    [string]$VirtualMachine = New-AzVMConfig @newAzVMConfigSplat

    if ($AuthenticationType -eq "SSH") {
    $SetAzVMOperatingSystemSplat = @{
            VM           = $VirtualMachine
            Linux        = $true
            ComputerName = $ComputerName
            Credential   = $Credential
            DisablePasswordAuthentication = $true
        }
    } else {
    $SetAzVMOperatingSystemSplat = @{
            VM           = $VirtualMachine
            Linux        = $true
            ComputerName = $ComputerName
            Credential   = $Credential
        }
    }
    [string]$VirtualMachine = Set-AzVMOperatingSystem @setAzVMOperatingSystemSplat

    if ($AuthenticationType -eq "SSH") {
        Write-LogMessage "Adding SSH public key for authentication" -Level "INFO"
    [string]$SshKeyPath = "/home/$VMAdminUser/.ssh/authorized_keys"
    [string]$VirtualMachine = Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $SSHPublicKey -Path $SshKeyPath
    }
    [string]$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id

    Write-LogMessage "Configuring VM source image (Ubuntu $UbuntuVersion)" -Level "INFO"
    $SetAzVMSourceImageSplat = @{
        VM            = $VirtualMachine
        PublisherName = "Canonical"
        Offer         = "0001-com-ubuntu-server-focal"
        Skus          = $UbuntuVersion
        Version       = "latest"
    }
    [string]$VirtualMachine = Set-AzVMSourceImage @setAzVMSourceImageSplat
    $SetAzVMOSDiskSplat = @{
        VM           = $VirtualMachine
        Name         = $OSDiskName
        Caching      = $OSDiskCaching
        CreateOption = $OSCreateOption
        DiskSizeInGB = $DiskSizeGB
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
    Write-LogMessage "VM Size: $VMSize (optimized for Splunk)" -Level "INFO"
    Write-LogMessage "Operating System: Ubuntu Linux ($UbuntuVersion)" -Level "INFO"
    Write-LogMessage "Username: $VMAdminUser" -Level "INFO"
    Write-LogMessage "Authentication: $AuthenticationType" -Level "INFO"
    Write-LogMessage "Disk Size: ${DiskSizeGB}GB" -Level "INFO"
    [string]$fqdn = "${DNSNameLabel}.${LocationName}.cloudapp.azure.com"
    Write-LogMessage "FQDN: $fqdn" -Level "INFO"
    Write-LogMessage "Public IP: Static allocation" -Level "INFO"

    if ($AuthenticationType -eq "SSH") {
        Write-LogMessage "SSH Connection: ssh $VMAdminUser@$fqdn" -Level "INFO"
    } else {
        Write-LogMessage "SSH Connection: ssh $VMAdminUser@$fqdn (password authentication)" -Level "INFO"
    }

    Write-LogMessage "Virtual Network: $NetworkName" -Level "INFO"
    Write-LogMessage "VNet Address Space: $VnetAddressPrefix" -Level "INFO"
    Write-LogMessage "Subnet: $SubnetName ($SubnetAddressPrefix)" -Level "INFO"
    Write-LogMessage "Auto-shutdown: $AutoShutdownTime Central Standard Time" -Level "INFO"
    Write-LogMessage "Notification email: $NotificationEmail" -Level "INFO"

    Write-Output ""
    Write-LogMessage "Network Security Rules:" -Level "INFO"
    Write-LogMessage "  SSH (22): Allowed from $SourceAddressPrefixCIDR" -Level "INFO"
    Write-LogMessage "  Splunk Web (8000): Allowed from $SourceAddressPrefixCIDR" -Level "INFO"
    Write-LogMessage "  Splunk Forwarder (9997): Allowed from subnet ($SubnetAddressPrefix)" -Level "INFO"

    Write-Output ""
    Write-LogMessage "Next Steps for Splunk Configuration:" -Level "INFO"
    Write-LogMessage "1. Wait 2-3 minutes for VM to fully boot" -Level "INFO"
    Write-LogMessage "2. Connect via SSH using the connection details above" -Level "INFO"
    Write-LogMessage "3. Update the system: sudo apt update && sudo apt upgrade -y" -Level "INFO"
    Write-LogMessage "4. Download and install Splunk from splunk.com" -Level "INFO"
    Write-LogMessage "5. Configure Splunk for your monitoring needs" -Level "INFO"
    Write-LogMessage "6. Access Splunk Web interface at: http://$fqdn:8000" -Level "INFO"
    Write-LogMessage "7. Configure forwarders to send data to port 9997" -Level "INFO"
    Write-LogMessage "8. VM can be rebooted anytime for maintenance" -Level "INFO"

} catch {
    Write-LogMessage "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error $_.Exception.Message
    throw`n}
