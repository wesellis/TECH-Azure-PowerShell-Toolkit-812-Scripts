# ============================================================================
# Script Name: Azure VM Network Info Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Displays network interface and IP information for a Virtual Machine
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName
)

Write-Host "Retrieving network information for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

Write-Host "`nNetwork Interfaces:"
foreach ($NicRef in $VM.NetworkProfile.NetworkInterfaces) {
    $NicId = $NicRef.Id
    $Nic = Get-AzNetworkInterface -ResourceId $NicId
    
    Write-Host "  NIC: $($Nic.Name)"
    Write-Host "  Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
    Write-Host "  Subnet: $($Nic.IpConfigurations[0].Subnet.Id.Split('/')[-1])"
    
    if ($Nic.IpConfigurations[0].PublicIpAddress) {
        $PipId = $Nic.IpConfigurations[0].PublicIpAddress.Id
        $Pip = Get-AzPublicIpAddress -ResourceId $PipId
        Write-Host "  Public IP: $($Pip.IpAddress)"
    }
}
