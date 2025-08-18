<#
.SYNOPSIS
    We Enhanced 20.4 Azvm Windows Param

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

$WEHelpers2 = "$WEPsScriptRoot\Helpers\"
New-IaaCAzVMWindows @NewIaaCAzVMWindowsSplat


$WEErrorActionPreference = " Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$WEHelpers2 = " $WEPsScriptRoot\Helpers\"

Get-ChildItem -Path $WEHelpers2 -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }


$WELocationName = 'CanadaCentral'
$WECustomerName = 'CanadaComputing'
$WEVMName = 'client1'
$WEResourceGroupName = -join (" $WECustomerName", " _$WEVMName", " _RG")



$WEComputerName = $WEVMName
$WEVMSize = " Standard_B2MS"
$WEOSDiskCaching = " ReadWrite"
$WEOSCreateOption = " FromImage"
$WEGUID = [guid]::NewGuid()
$WEOSDiskName = -join (" $WEVMName", " _OSDisk", " _1", " _$WEGUID")


$WEASGName = -join (" $WEVMName", " _ASG1")


$WENSGName = -join (" $WEVMName", " -nsg")


$WEDNSNameLabel = -join (" $WEVMName", " DNS").ToLower() # mydnsname.westus.cloudapp.azure.com
$WEVnetName = -join (" $WEVMName", " _group-vnet")
$WENICPrefix = 'NIC1'
$WENICName = -join (" $WEVMName", " _$WENICPrefix").ToLower()
$WEIPConfigName = -join (" $WEVMName", " $WENICName", " _IPConfig1").ToLower()
$WEPublicIPAddressName = -join (" $WEVMName", " -ip")
$WEPublicIPAllocation = 'Dynamic'
$WESubnetName = -join (" $WEVMName", " -subnet")
$WESubnetAddressPrefix = " 10.0.0.0/24"
$WEVnetAddressPrefix = " 10.0.0.0/16"
$WESourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip").Content #Gets the public IP of the current machine
$WESourceAddressPrefixCIDR = -join (" $WESourceAddressPrefix", " /32")



$publisherName = " MicrosoftWindowsDesktop"
$offer = " office-365"
$WESkus = " 20h2-evd-o365pp"
$version = " latest"


$WEDiskSizeInGB = '128'



$WEExtensionName = " AADLoginForWindows"
$WEExtensionPublisher = " Microsoft.Azure.ActiveDirectory"
$WEExtensionType = " AADLoginForWindows"
$WETypeHandlerVersion = " 1.0"


$secretLength = '16'
$WEUsersGroupName = " Azure VM - Standard User"
$WEAdminsGroupName = " Azure VM - Admins"
$WERoleDefinitionNameUsers = " Virtual Machine User Login"
$WERoleDefinitionNameAdmins = " Virtual Machine Administrator Login"



$WETime = '23:59'
$WETimeZone = " Central Standard Time"
$WEEmail = " abdullah@canadacomputing.ca"


$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss")
[hashtable]$WETags = @{

    " Autoshutown"     = 'ON'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"    = " $WECustomerName"
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Production'
    " Application"     = 'TeamViewer'  
    " Purpose"         = 'TeamViewer'
    " Uptime"          = '24/7'
    " Workload"        = 'TeamViewer'
    " RebootCaution"   = 'Schedule a window first before rebooting'
    " VMSize"          = 'B2MS'
    " Location"        = " $WELocationName"
    " Approved By"     = " Abdullah Ollivierre"
    " Approved On"     = ""

}

; 
$WENewIaaCAzVMWindowsSplat = @{

    LocationName             = $WELocationName
    CustomerName             = $WECustomerName 
    VMName                   = $WEVMName  
    ResourceGroupName        = $WEResourceGroupName
        
    #Creating the Tag Hashtable for the VM
    datetime                 = $datetime
    Tags                     = $WETags 
        
        
    ##VM
    ComputerName             = $WEComputerName
    VMSize                   = $WEVMSize
    OSDiskCaching            = $WEOSDiskCaching
    OSCreateOption           = $WEOSCreateOption
    GUID                     = $WEGUID
    OSDiskName               = $WEOSDiskName
        
    #ASG
    ASGName                  = $WEASGName 
        
    #Defining the NSG name
    NSGName                  = $WENSGName  
        
    ## Networking
    DNSNameLabel             = $WEDNSNameLabel   # mydnsname.westus.cloudapp.azure.com
    NICPrefix                = $WENICPrefix 
    NICName                  = $WENICName
    IPConfigName             = $WEIPConfigName 
    PublicIPAddressName      = $WEPublicIPAddressName
    VnetName                 = $WEVnetName
    SubnetName               = $WESubnetName
    PublicIPAllocation       = $WEPublicIPAllocation
    SubnetAddressPrefix      = $WESubnetAddressPrefix 
    VnetAddressPrefix        = $WEVnetAddressPrefix
    SourceAddressPrefix      = $WESourceAddressPrefixCIDR
    # SourceAddressPrefixCIDR  = $WESourceAddressPrefixCIDR
        
        
    ##Operating System
    PublisherName            = $WEPublisherName
    Offer                    = $WEOffer 
    Skus                     = $WESkus  
    Version                  = $WEVersion 
        
    ##Disk
    DiskSizeInGB             = $WEDiskSizeInGB

    ##Extensions
    ExtensionName            = $WEExtensionName  
    ExtensionPublisher       = $WEExtensionPublisher 
    ExtensionType            = $WEExtensionType 
    TypeHandlerVersion       = $WETypeHandlerVersion



    #RBAC
    secretLength             = $secretLength
    UsersGroupName           = $WEUsersGroupName
    AdminsGroupName          = $WEAdminsGroupName
    RoleDefinitionNameUsers  = $WERoleDefinitionNameUsers
    RoleDefinitionNameAdmins = $WERoleDefinitionNameAdmins


    #AutoShutdown
    Time                     = $WETime
    TimeZone                 = $WETimeZone
    Email                    = $WEEmail



}
New-IaaCAzVMWindows @NewIaaCAzVMWindowsSplat


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================