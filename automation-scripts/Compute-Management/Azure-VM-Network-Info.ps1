<#
.SYNOPSIS
    Get VM network details

.DESCRIPTION
    Get VM network details
#>
param (
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName
)
Write-Host "Retrieving network information for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
Write-Host "`nNetwork Interfaces:"
foreach ($NicRef in $VM.NetworkProfile.NetworkInterfaces) {
    $NicId = $NicRef.Id
    $Nic = Get-AzNetworkInterface -ResourceId $NicId
    Write-Host "NIC: $($Nic.Name)"
    Write-Host "Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
    Write-Host "Subnet: $($Nic.IpConfigurations[0].Subnet.Id.Split('/')[-1])"
    if ($Nic.IpConfigurations[0].PublicIpAddress) {
        $PipId = $Nic.IpConfigurations[0].PublicIpAddress.Id
        $Pip = Get-AzPublicIpAddress -ResourceId $PipId
        Write-Host "Public IP: $($Pip.IpAddress)"
    }
}

