<#
.SYNOPSIS
    Azure Bastion Creator

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

<#
.SYNOPSIS
    We Enhanced Azure Bastion Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEBastionName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVNetName,
    
    [Parameter(Mandatory=$true)]
    [string]$WELocation
)

Write-WELog " Creating Azure Bastion: $WEBastionName" " INFO"


$WEVNet = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name $WEVNetName


$WEBastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $WEVNet -Name " AzureBastionSubnet" -ErrorAction SilentlyContinue
if (-not $WEBastionSubnet) {
    Write-WELog " Creating AzureBastionSubnet..." " INFO"
    Add-AzVirtualNetworkSubnetConfig -Name " AzureBastionSubnet" -VirtualNetwork $WEVNet -AddressPrefix " 10.0.1.0/24"
    Set-AzVirtualNetwork -VirtualNetwork $WEVNet
    $WEVNet = Get-AzVirtualNetwork -ResourceGroupName $WEResourceGroupName -Name $WEVNetName
    $WEBastionSubnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $WEVNet -Name " AzureBastionSubnet"
}


$WEBastionIpName = " $WEBastionName-pip"; 
$WEBastionIp = New-AzPublicIpAddress -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEBastionIpName `
    -Location $WELocation `
    -AllocationMethod Static `
    -Sku Standard


Write-WELog " Creating Bastion host (this may take 10-15 minutes)..." " INFO" ; 
$WEBastion = New-AzBastion -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEBastionName `
    -PublicIpAddress $WEBastionIp `
    -VirtualNetwork $WEVNet

Write-WELog " ✅ Azure Bastion created successfully:" " INFO"
Write-WELog "  Name: $($WEBastion.Name)" " INFO"
Write-WELog "  Location: $($WEBastion.Location)" " INFO"
Write-WELog "  Public IP: $($WEBastionIp.IpAddress)" " INFO"
Write-WELog "  DNS Name: $($WEBastionIp.DnsSettings.Fqdn)" " INFO"

Write-WELog " `nBastion Usage:" " INFO"
Write-WELog " • Connect to VMs via Azure Portal" " INFO"
Write-WELog " • No need for public IPs on VMs" " INFO"
Write-WELog " • Secure RDP/SSH access" " INFO"
Write-WELog " • No VPN client required" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
