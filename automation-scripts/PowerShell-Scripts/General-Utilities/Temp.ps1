#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Temp

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Temp

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

$WEHelpers = " $WEPsScriptRoot\Helpers\"

Get-ChildItem -Path $WEHelpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }



$WELocationName = 'CanadaCentral'

$WECustomerName = 'CCI'
$WEVMName = 'TeamViewer'
$WECustomerName = 'CanadaComputing'
$WEResourceGroupName = -join (" $WECustomerName" , " _$WEVMName" , " _RG" )




$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"     = 'ON'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"    = " $WECustomerName"
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Production'
    " Application"     = 'TeamViewer'  
    " Purpose"         = 'TeamViewer'
    " Uptime"          = '24/7'
    " Workload"        = 'WinSCP'
    " RebootCaution"   = 'Schedule a window first before rebooting'
    " VMSize"          = 'B2MS'
    " Location"        = " $WELocationName"
    " Approved By"     = " Abdullah Ollivierre"
    " Approved On"     = ""

}














$WEComputerName = $WEVMName



$WEVMSize = " Standard_B2MS"
$WEOSDiskCaching = " ReadWrite"
$WEOSCreateOption = " FromImage"


$WEGUID = [guid]::NewGuid()
$WEOSDiskName = -join (" $WEVMName" , " _OSDisk" , " _1" , " _$WEGUID" )


$WEDNSNameLabel = -join (" $WEVMName" , " DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com


$WENetworkName = -join (" $WEVMName" , " _group-vnet" )


$WENICPrefix = 'NIC1'
$WENICName = -join (" $WEVMName" , " _$WENICPrefix" ).ToLower()
$WEIPConfigName = -join (" $WEVMName" , " $WENICName" , " _IPConfig1" ).ToLower()


$WEPublicIPAddressName = -join (" $WEVMName" , " -ip" )


$WESubnetName = -join (" $WEVMName" , " -subnet" )
$WESubnetAddressPrefix = " 10.0.0.0/24"
$WEVnetAddressPrefix = " 10.0.0.0/16"


$WENSGName = -join (" $WEVMName" , " -nsg" )



    # IpTagType = " FirstPartyUsage"
    # Tag       = " /Sql"







$WESourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip" ).Content #Gets the public IP of the current machine; 
$WESourceAddressPrefixCIDR = -join (" $WESourceAddressPrefix" , " /32" )




; 
$setAzVMAutoShutdownSplat = @{
    # ResourceGroupName = 'RG-WE-001'
    ResourceGroupName = $WEResourceGroupName
    # Name              = 'MYVM001'
    Name              = $WEVMName
    Enable            = $true
    Time              = '23:59'
    # TimeZone = " W. Europe Standard Time"
    TimeZone          = " Central Standard Time"
    Email             = " abdullah@canadacomputing.ca"
}

Set-AzVMAutoShutdown -ErrorAction Stop @setAzVMAutoShutdownSplat





Write-Information \'The VM is now ready.... here is your login details\'
Write-Information \'username:\' $WEVMLocalAdminUser
Write-Information \'Password:\' $WEVMLocalAdminPassword
Write-Information \'DNSName:\' $WEDNSNameLabel



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
