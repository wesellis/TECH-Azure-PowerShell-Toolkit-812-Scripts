#Requires -Version 7.0

<#`n.SYNOPSIS
    Azvm Windows Param

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$Helpers2 = " $PsScriptRoot\Helpers\"
Get-ChildItem -Path $Helpers2 -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }
$LocationName = 'CanadaCentral'
$CustomerName = 'CanadaComputing'
$VMName = 'client1'
$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
$ComputerName = $VMName
$VMSize = "Standard_B2MS"
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"
$GUID = [guid]::NewGuid()
$OSDiskName = -join (" $VMName" , "_OSDisk" , "_1" , "_$GUID" )
$ASGName = -join (" $VMName" , "_ASG1" )
$NSGName = -join (" $VMName" , "-nsg" )
$DNSNameLabel = -join (" $VMName" , "DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com
$VnetName = -join (" $VMName" , "_group-vnet" )
$NICPrefix = 'NIC1'
$NICName = -join (" $VMName" , "_$NICPrefix" ).ToLower()
$IPConfigName = -join (" $VMName" , "$NICName" , "_IPConfig1" ).ToLower()
$PublicIPAddressName = -join (" $VMName" , "-ip" )
$PublicIPAllocation = 'Dynamic'
$SubnetName = -join (" $VMName" , "-subnet" )
$SubnetAddressPrefix = " 10.0.0.0/24"
$VnetAddressPrefix = " 10.0.0.0/16"
$SourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip" ).Content #Gets the public IP of the current machine
$SourceAddressPrefixCIDR = -join (" $SourceAddressPrefix" , "/32" )
$publisherName = "MicrosoftWindowsDesktop"
$offer = " office-365"
$Skus = " 20h2-evd-o365pp"
$version = " latest"
$DiskSizeInGB = '128'
$ExtensionName = "AADLoginForWindows"
$ExtensionPublisher = "Microsoft.Azure.ActiveDirectory"
$ExtensionType = "AADLoginForWindows"
$TypeHandlerVersion = " 1.0"
$secretLength = '16'
$UsersGroupName = "Azure VM - Standard User"
$AdminsGroupName = "Azure VM - Admins"
$RoleDefinitionNameUsers = "Virtual Machine User Login"
$RoleDefinitionNameAdmins = "Virtual Machine Administrator Login"
$Time = '23:59'
$TimeZone = "Central Standard Time"
$Email = " abdullah@canadacomputing.ca"
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Autoshutown"     = 'ON'
    "Createdby"       = 'Abdullah Ollivierre'
    "CustomerName"    = " $CustomerName"
    "DateTimeCreated" = " $datetime"
    "Environment"     = 'Production'
    "Application"     = 'TeamViewer'
    "Purpose"         = 'TeamViewer'
    "Uptime"          = '24/7'
    "Workload"        = 'TeamViewer'
    "RebootCaution"   = 'Schedule a window first before rebooting'
    "VMSize"          = 'B2MS'
    "Location"        = " $LocationName"
    "Approved By"     = "Abdullah Ollivierre"
    "Approved On"     = ""
}
$NewIaaCAzVMWindowsSplat = @{
    LocationName             = $LocationName
    CustomerName             = $CustomerName
    VMName                   = $VMName
    ResourceGroupName        = $ResourceGroupName
    #Creating the Tag Hashtable for the VM
    datetime                 = $datetime
    Tags                     = $Tags
    ##VM
    ComputerName             = $ComputerName
    VMSize                   = $VMSize
    OSDiskCaching            = $OSDiskCaching
    OSCreateOption           = $OSCreateOption
    GUID                     = $GUID
    OSDiskName               = $OSDiskName
    #ASG
    ASGName                  = $ASGName
    #Defining the NSG name
    NSGName                  = $NSGName
    ## Networking
    DNSNameLabel             = $DNSNameLabel   # mydnsname.westus.cloudapp.azure.com
    NICPrefix                = $NICPrefix
    NICName                  = $NICName
    IPConfigName             = $IPConfigName
    PublicIPAddressName      = $PublicIPAddressName
    VnetName                 = $VnetName
    SubnetName               = $SubnetName
    PublicIPAllocation       = $PublicIPAllocation
    SubnetAddressPrefix      = $SubnetAddressPrefix
    VnetAddressPrefix        = $VnetAddressPrefix
    SourceAddressPrefix      = $SourceAddressPrefixCIDR
    # SourceAddressPrefixCIDR  = $SourceAddressPrefixCIDR
    ##Operating System
    PublisherName            = $PublisherName
    Offer                    = $Offer
    Skus                     = $Skus
    Version                  = $Version
    ##Disk
    DiskSizeInGB             = $DiskSizeInGB
    ##Extensions
    ExtensionName            = $ExtensionName
    ExtensionPublisher       = $ExtensionPublisher
    ExtensionType            = $ExtensionType
    TypeHandlerVersion       = $TypeHandlerVersion
    #RBAC
    secretLength             = $secretLength
    UsersGroupName           = $UsersGroupName
    AdminsGroupName          = $AdminsGroupName
    RoleDefinitionNameUsers  = $RoleDefinitionNameUsers
    RoleDefinitionNameAdmins = $RoleDefinitionNameAdmins
    #AutoShutdown
    Time                     = $Time
    TimeZone                 = $TimeZone
    Email                    = $Email
}
New-IaaCAzVMWindows -ErrorAction Stop @NewIaaCAzVMWindowsSplat
