<#
.SYNOPSIS
    Azure Bastion Creator

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
Write-Host "Creating Azure Bastion: $BastionName"
$VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
$BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet" -ErrorAction SilentlyContinue
if (-not $BastionSubnet) {
    Write-Host "Creating AzureBastionSubnet..."
    Add-AzVirtualNetworkSubnetConfig -Name "AzureBastionSubnet" -VirtualNetwork $VNet -AddressPrefix " 10.0.1.0/24"
    Set-AzVirtualNetwork -VirtualNetwork $VNet
    $VNet = Get-AzVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $VNetName
    $BastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet -Name "AzureBastionSubnet"
}
$BastionIpName = " $BastionName-pip";
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = "Standard"
    Location = $Location
    AllocationMethod = "Static"
    ErrorAction = "Stop"
    Name = $BastionIpName
}
$BastionIp @params
Write-Host "Creating Bastion host (this may take 10-15 minutes)..." ;
$params = @{
    ErrorAction = "Stop"
    PublicIpAddress = $BastionIp
    VirtualNetwork = $VNet
    ResourceGroupName = $ResourceGroupName
    Name = $BastionName
}
$Bastion @params
Write-Host "Azure Bastion created successfully:"
Write-Host "Name: $($Bastion.Name)"
Write-Host "Location: $($Bastion.Location)"
Write-Host "Public IP: $($BastionIp.IpAddress)"
Write-Host "DNS Name: $($BastionIp.DnsSettings.Fqdn)"
Write-Host " `nBastion Usage:"
Write-Host "Connect to VMs via Azure Portal"
Write-Host "No need for public IPs on VMs"
Write-Host "Secure RDP/SSH access"
Write-Host "No VPN client required"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

