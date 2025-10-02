#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Network

<#`n.SYNOPSIS
    Azure Bastion Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$BastionName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VNetName,
    [Parameter(Mandatory)]
    [string]$Location
)
Write-Output "Creating Azure Bastion: $BastionName"
    [string]$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    [string]$BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet" -ErrorAction SilentlyContinue
if (-not $BastionSubnet) {
    Write-Output "Creating AzureBastionSubnet..."
    Add-AzVirtualNetworkSubnetConfig -Name "AzureBastionSubnet" -VirtualNetwork $VNet -AddressPrefix " 10.0.1.0/24"
    Set-AzVirtualNetwork -VirtualNetwork $VNet
    [string]$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    [string]$BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet"
}
    [string]$BastionIpName = " $BastionName-pip";
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $BastionIpName
}
    [string]$BastionIp @params
Write-Output "Creating Bastion host (this may take 10-15 minutes)..." ;
    $params = @{
    ErrorAction = "Stop"
    PublicIpAddress = $BastionIp
    VirtualNetwork = $VNet
    ResourceGroupName = $ResourceGroupName
    Name = $BastionName
}
    [string]$Bastion @params
Write-Output "Azure Bastion created successfully:"
Write-Output "Name: $($Bastion.Name)"
Write-Output "Location: $($Bastion.Location)"
Write-Output "Public IP: $($BastionIp.IpAddress)"
Write-Output "DNS Name: $($BastionIp.DnsSettings.Fqdn)"
Write-Output " `nBastion Usage:"
Write-Output "Connect to VMs via Azure Portal"
Write-Output "No need for public IPs on VMs"
Write-Output "Secure RDP/SSH access"
Write-Output "No VPN client required"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
