#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Get VM network details

.DESCRIPTION
    Get VM network details


    Author: Wes Ellis (wes@wesellis.com)
#>
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName
)
Write-Output "Retrieving network information for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
Write-Output "`nNetwork Interfaces:"
foreach ($NicRef in $VM.NetworkProfile.NetworkInterfaces) {
    $NicId = $NicRef.Id
    $Nic = Get-AzNetworkInterface -ResourceId $NicId
    Write-Output "NIC: $($Nic.Name)"
    Write-Output "Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
    Write-Output "Subnet: $($Nic.IpConfigurations[0].Subnet.Id.Split('/')[-1])"
    if ($Nic.IpConfigurations[0].PublicIpAddress) {
        $PipId = $Nic.IpConfigurations[0].PublicIpAddress.Id
        $Pip = Get-AzPublicIpAddress -ResourceId $PipId
        Write-Output "Public IP: $($Pip.IpAddress)"
    }
`n}
