#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create VWAN

.DESCRIPTION
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
.\New-VirtualWAN.ps1 -ResourceGroup rg-network -Name corp-wan -Location "East US" -HubName hub-east -HubPrefix "10.0.0.0/24"
#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroup,
    [Parameter(Mandatory)]
    [string]$Name,
    [Parameter(Mandatory)]
    [string]$Location,
    [string]$HubName,
    [string]$HubPrefix
)
# Create WAN
Write-Host "Creating Virtual WAN $Name" -ForegroundColor Green
$wan = New-AzVirtualWan -ResourceGroupName $ResourceGroup -Name $Name -Location $Location -VirtualWANType Standard
if ($HubName -and $HubPrefix) {
    Write-Host "Creating Virtual Hub $HubName" -ForegroundColor Green
    $hub = New-AzVirtualHub -ResourceGroupName $ResourceGroup -Name $HubName -Location $Location -VirtualWan $wan -AddressPrefix $HubPrefix
    Write-Host "Virtual WAN and Hub created successfully" -ForegroundColor Green
    return @{WAN = $wan; Hub = $hub}
} else {
    Write-Host "Virtual WAN created successfully" -ForegroundColor Green
    return $wan
}\n

