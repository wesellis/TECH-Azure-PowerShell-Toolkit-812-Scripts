#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Create VWAN

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
Create Azure Virtual WAN and optionally a hub
.PARAMETER ResourceGroup
Resource group name
.PARAMETER Name
Virtual WAN name
.PARAMETER Location
Azure region
.PARAMETER HubName
Virtual hub name
.PARAMETER HubPrefix
Hub address prefix (e.g. 10.0.0.0/24)
.EXAMPLE
.
ew-VirtualWAN.ps1 -ResourceGroup rg-network -Name corp-wan -Location "East US" -HubName hub-east -HubPrefix "10.0.0.0/24"
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroup,
    [Parameter(Mandatory)]
    [string]$Name,
    [Parameter(Mandatory)]
    [string]$Location,
    [string]$HubName,
    [string]$HubPrefix
)
Write-Output "Creating Virtual WAN $Name" # Color: $2
$wan = New-AzVirtualWan -ResourceGroupName $ResourceGroup -Name $Name -Location $Location -VirtualWANType Standard
if ($HubName -and $HubPrefix) {
    Write-Output "Creating Virtual Hub $HubName" # Color: $2
    $hub = New-AzVirtualHub -ResourceGroupName $ResourceGroup -Name $HubName -Location $Location -VirtualWan $wan -AddressPrefix $HubPrefix
    Write-Output "Virtual WAN and Hub created successfully" # Color: $2
    return @{WAN = $wan; Hub = $hub}
} else {
    Write-Output "Virtual WAN created successfully" # Color: $2
    return $wan`n}
