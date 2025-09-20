#Requires -Version 7.0

<#`n.SYNOPSIS
    Hvhostsetup

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[cmdletbinding()
try {
    # Main script execution
]
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$NIC1IPAddress,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$NIC2IPAddress,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GhostedSubnetPrefix,
    [string]$VirtualNetworkPrefix
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module Subnet -Force
New-VMSwitch -Name "NestedSwitch" -SwitchType Internal
$NIC1IP = Get-NetIPAddress -ErrorAction Stop | Where-Object -Property AddressFamily -EQ IPv4 | Where-Object -Property IPAddress -EQ $NIC1IPAddress
$NIC2IP = Get-NetIPAddress -ErrorAction Stop | Where-Object -Property AddressFamily -EQ IPv4 | Where-Object -Property IPAddress -EQ $NIC2IPAddress
$NATSubnet = Get-Subnet -IP $NIC1IP.IPAddress -MaskBits $NIC1IP.PrefixLength
$HyperVSubnet = Get-Subnet -IP $NIC2IP.IPAddress -MaskBits $NIC2IP.PrefixLength;
$NestedSubnet = Get-Subnet -ErrorAction Stop $GhostedSubnetPrefix;
$VirtualNetwork = Get-Subnet -ErrorAction Stop $VirtualNetworkPrefix
New-NetIPAddress -IPAddress $NestedSubnet.HostAddresses[0] -PrefixLength $NestedSubnet.MaskBits -InterfaceAlias " vEthernet (NestedSwitch)"
New-NetNat -Name "NestedSwitch" -InternalIPInterfaceAddressPrefix " $GhostedSubnetPrefix"
Add-DhcpServerv4Scope -Name "Nested VMs" -StartRange $NestedSubnet.HostAddresses[1] -EndRange $NestedSubnet.HostAddresses[-1] -SubnetMask $NestedSubnet.SubnetMask
Set-DhcpServerv4OptionValue -DnsServer 168.63.129.16 -Router $NestedSubnet.HostAddresses[0]
Install-RemoteAccess -VpnType RoutingOnly
cmd.exe /c " netsh routing ip nat install"
cmd.exe /c " netsh routing ip nat add interface "" $($NIC1IP.InterfaceAlias)"""
cmd.exe /c " netsh routing ip add persistentroute dest=$($NatSubnet.NetworkAddress) mask=$($NATSubnet.SubnetMask) name="" $($NIC1IP.InterfaceAlias)"" nhop=$($NATSubnet.HostAddresses[0])"
cmd.exe /c " netsh routing ip add persistentroute dest=$($VirtualNetwork.NetworkAddress) mask=$($VirtualNetwork.SubnetMask) name="" $($NIC2IP.InterfaceAlias)"" nhop=$($HyperVSubnet.HostAddresses[0])"
Get-Disk -ErrorAction Stop | Where-Object -Property PartitionStyle -EQ "RAW" | Initialize-Disk -PartitionStyle GPT -PassThru | New-Volume -FileSystem NTFS -AllocationUnitSize 65536 -DriveLetter F -FriendlyName "Hyper-V"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
