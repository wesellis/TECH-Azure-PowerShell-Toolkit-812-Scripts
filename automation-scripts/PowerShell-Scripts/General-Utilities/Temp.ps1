<#
.SYNOPSIS
    Temp

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$Helpers = " $PsScriptRoot\Helpers\"
Get-ChildItem -Path $Helpers -Recurse -Filter '*.ps1' | ForEach-Object { . $_.FullName }
$LocationName = 'CanadaCentral'
$CustomerName = 'CCI'
$VMName = 'TeamViewer'
$CustomerName = 'CanadaComputing'
$ResourceGroupName = -join (" $CustomerName" , "_$VMName" , "_RG" )
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
    "Workload"        = 'WinSCP'
    "RebootCaution"   = 'Schedule a window first before rebooting'
    "VMSize"          = 'B2MS'
    "Location"        = " $LocationName"
    "Approved By"     = "Abdullah Ollivierre"
    "Approved On"     = ""
}
$ComputerName = $VMName
$VMSize = "Standard_B2MS"
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"
$GUID = [guid]::NewGuid()
$OSDiskName = -join (" $VMName" , "_OSDisk" , "_1" , "_$GUID" )
$DNSNameLabel = -join (" $VMName" , "DNS" ).ToLower() # mydnsname.westus.cloudapp.azure.com
$NetworkName = -join (" $VMName" , "_group-vnet" )
$NICPrefix = 'NIC1'
$NICName = -join (" $VMName" , "_$NICPrefix" ).ToLower()
$IPConfigName = -join (" $VMName" , "$NICName" , "_IPConfig1" ).ToLower()
$PublicIPAddressName = -join (" $VMName" , "-ip" )
$SubnetName = -join (" $VMName" , "-subnet" )
$SubnetAddressPrefix = " 10.0.0.0/24"
$VnetAddressPrefix = " 10.0.0.0/16"
$NSGName = -join (" $VMName" , "-nsg" )
    # IpTagType = "FirstPartyUsage"
    # Tag       = " /Sql"
$SourceAddressPrefix = (Invoke-WebRequest -uri " http://ifconfig.me/ip" ).Content #Gets the public IP of the current machine;
$SourceAddressPrefixCIDR = -join (" $SourceAddressPrefix" , "/32" )
$setAzVMAutoShutdownSplat = @{
    # ResourceGroupName = 'RG-WE-001'
    ResourceGroupName = $ResourceGroupName
    # Name              = 'MYVM001'
    Name              = $VMName
    Enable            = $true
    Time              = '23:59'
    # TimeZone = "W. Europe Standard Time"
    TimeZone          = "Central Standard Time"
    Email             = " abdullah@canadacomputing.ca"
}
Set-AzVMAutoShutdown -ErrorAction Stop @setAzVMAutoShutdownSplat
Write-Information \'The VM is now ready.... here is your login details\'
Write-Information \'username:\' $VMLocalAdminUser
Write-Information \'Password:\' $VMLocalAdminPassword
Write-Information \'DNSName:\' $DNSNameLabel\n