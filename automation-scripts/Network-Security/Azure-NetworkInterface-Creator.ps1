# ============================================================================
# Script Name: Azure Network Interface Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates a new Azure Network Interface Card
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$NicName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$true)]
    [string]$SubnetId,
    
    [Parameter(Mandatory=$false)]
    [string]$PublicIpId
)

Write-Host "Creating Network Interface: $NicName"

if ($PublicIpId) {
    $Nic = New-AzNetworkInterface `
        -ResourceGroupName $ResourceGroupName `
        -Name $NicName `
        -Location $Location `
        -SubnetId $SubnetId `
        -PublicIpAddressId $PublicIpId
} else {
    $Nic = New-AzNetworkInterface `
        -ResourceGroupName $ResourceGroupName `
        -Name $NicName `
        -Location $Location `
        -SubnetId $SubnetId
}

Write-Host "Network Interface created successfully:"
Write-Host "  Name: $($Nic.Name)"
Write-Host "  Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
Write-Host "  Location: $($Nic.Location)"
