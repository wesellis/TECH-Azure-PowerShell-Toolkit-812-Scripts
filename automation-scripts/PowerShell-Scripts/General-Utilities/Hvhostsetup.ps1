#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Hvhostsetup

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
    We Enhanced Hvhostsetup

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[cmdletbinding()
try {
    # Main script execution
]
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WENIC1IPAddress,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WENIC2IPAddress,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGhostedSubnetPrefix,
    [string]$WEVirtualNetworkPrefix
)

#region Functions

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module Subnet -Force

New-VMSwitch -Name " NestedSwitch" -SwitchType Internal

$WENIC1IP = Get-NetIPAddress -ErrorAction Stop | Where-Object -Property AddressFamily -EQ IPv4 | Where-Object -Property IPAddress -EQ $WENIC1IPAddress
$WENIC2IP = Get-NetIPAddress -ErrorAction Stop | Where-Object -Property AddressFamily -EQ IPv4 | Where-Object -Property IPAddress -EQ $WENIC2IPAddress

$WENATSubnet = Get-Subnet -IP $WENIC1IP.IPAddress -MaskBits $WENIC1IP.PrefixLength
$WEHyperVSubnet = Get-Subnet -IP $WENIC2IP.IPAddress -MaskBits $WENIC2IP.PrefixLength; 
$WENestedSubnet = Get-Subnet -ErrorAction Stop $WEGhostedSubnetPrefix; 
$WEVirtualNetwork = Get-Subnet -ErrorAction Stop $WEVirtualNetworkPrefix

New-NetIPAddress -IPAddress $WENestedSubnet.HostAddresses[0] -PrefixLength $WENestedSubnet.MaskBits -InterfaceAlias " vEthernet (NestedSwitch)"
New-NetNat -Name " NestedSwitch" -InternalIPInterfaceAddressPrefix " $WEGhostedSubnetPrefix"

Add-DhcpServerv4Scope -Name " Nested VMs" -StartRange $WENestedSubnet.HostAddresses[1] -EndRange $WENestedSubnet.HostAddresses[-1] -SubnetMask $WENestedSubnet.SubnetMask
Set-DhcpServerv4OptionValue -DnsServer 168.63.129.16 -Router $WENestedSubnet.HostAddresses[0]

Install-RemoteAccess -VpnType RoutingOnly
cmd.exe /c " netsh routing ip nat install"
cmd.exe /c " netsh routing ip nat add interface "" $($WENIC1IP.InterfaceAlias)"""
cmd.exe /c " netsh routing ip add persistentroute dest=$($WENatSubnet.NetworkAddress) mask=$($WENATSubnet.SubnetMask) name="" $($WENIC1IP.InterfaceAlias)"" nhop=$($WENATSubnet.HostAddresses[0])"
cmd.exe /c " netsh routing ip add persistentroute dest=$($WEVirtualNetwork.NetworkAddress) mask=$($WEVirtualNetwork.SubnetMask) name="" $($WENIC2IP.InterfaceAlias)"" nhop=$($WEHyperVSubnet.HostAddresses[0])"

Get-Disk -ErrorAction Stop | Where-Object -Property PartitionStyle -EQ " RAW" | Initialize-Disk -PartitionStyle GPT -PassThru | New-Volume -FileSystem NTFS -AllocationUnitSize 65536 -DriveLetter F -FriendlyName " Hyper-V"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
