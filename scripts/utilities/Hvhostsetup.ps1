#Requires -Version 7.4

<#
.SYNOPSIS
    Hyper-V Host Setup

.DESCRIPTION
    Azure automation script for setting up Hyper-V host configuration

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

.PARAMETER NIC1IPAddress
    Network interface 1 IP address

.PARAMETER NIC2IPAddress
    Network interface 2 IP address

.PARAMETER GhostedSubnetPrefix
    Ghosted subnet prefix

.PARAMETER VirtualNetworkPrefix
    Virtual network prefix

.EXAMPLE
    .\Hvhostsetup.ps1 -NIC1IPAddress "192.168.1.10" -NIC2IPAddress "10.0.0.10" -GhostedSubnetPrefix "192.168.100.0/24" -VirtualNetworkPrefix "10.0.0.0/16"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $NIC1IPAddress,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $NIC2IPAddress,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $GhostedSubnetPrefix,

    [Parameter()]
    $VirtualNetworkPrefix
)

$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module Subnet -Force
    New-VMSwitch -Name "NestedSwitch" -SwitchType Internal

    $NIC1IP = Get-NetIPAddress -ErrorAction Stop | Where-Object -Property AddressFamily -EQ IPv4 | Where-Object -Property IPAddress -EQ $NIC1IPAddress
    $NIC2IP = Get-NetIPAddress -ErrorAction Stop | Where-Object -Property AddressFamily -EQ IPv4 | Where-Object -Property IPAddress -EQ $NIC2IPAddress
    $NATSubnet = Get-Subnet -IP $NIC1IP.IPAddress -MaskBits $NIC1IP.PrefixLength
    $HyperVSubnet = Get-Subnet -IP $NIC2IP.IPAddress -MaskBits $NIC2IP.PrefixLength
    $NestedSubnet = Get-Subnet -ErrorAction Stop $GhostedSubnetPrefix
    $VirtualNetwork = Get-Subnet -ErrorAction Stop $VirtualNetworkPrefix

    New-NetIPAddress -IPAddress $NestedSubnet.HostAddresses[0] -PrefixLength $NestedSubnet.MaskBits -InterfaceAlias "vEthernet (NestedSwitch)"
    New-NetNat -Name "NestedSwitch" -InternalIPInterfaceAddressPrefix "$GhostedSubnetPrefix"
    Add-DhcpServerv4Scope -Name "Nested VMs" -StartRange $NestedSubnet.HostAddresses[1] -EndRange $NestedSubnet.HostAddresses[-1] -SubnetMask $NestedSubnet.SubnetMask
    Set-DhcpServerv4OptionValue -DnsServer 168.63.129.16 -Router $NestedSubnet.HostAddresses[0]
    Install-RemoteAccess -VpnType RoutingOnly

    cmd.exe /c "netsh routing ip nat install"
    cmd.exe /c "netsh routing ip nat add interface `"$($NIC1IP.InterfaceAlias)`""
    cmd.exe /c "netsh routing ip add persistentroute dest=$($NatSubnet.NetworkAddress) mask=$($NATSubnet.SubnetMask) name=`"$($NIC1IP.InterfaceAlias)`" nhop=$($NATSubnet.HostAddresses[0])"
    cmd.exe /c "netsh routing ip add persistentroute dest=$($VirtualNetwork.NetworkAddress) mask=$($VirtualNetwork.SubnetMask) name=`"$($NIC2IP.InterfaceAlias)`" nhop=$($HyperVSubnet.HostAddresses[0])"

    Get-Disk -ErrorAction Stop | Where-Object -Property PartitionStyle -EQ "RAW" | Initialize-Disk -PartitionStyle GPT -PassThru | New-Volume -FileSystem NTFS -AllocationUnitSize 65536 -DriveLetter F -FriendlyName "Hyper-V"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
