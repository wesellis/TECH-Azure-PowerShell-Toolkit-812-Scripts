#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName
)

#region Functions

Write-Information "Retrieving network information for VM: $VmName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

Write-Information "`nNetwork Interfaces:"
foreach ($NicRef in $VM.NetworkProfile.NetworkInterfaces) {
    $NicId = $NicRef.Id
    $Nic = Get-AzNetworkInterface -ResourceId $NicId
    
    Write-Information "  NIC: $($Nic.Name)"
    Write-Information "  Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
    Write-Information "  Subnet: $($Nic.IpConfigurations[0].Subnet.Id.Split('/')[-1])"
    
    if ($Nic.IpConfigurations[0].PublicIpAddress) {
        $PipId = $Nic.IpConfigurations[0].PublicIpAddress.Id
        $Pip = Get-AzPublicIpAddress -ResourceId $PipId
        Write-Information "  Public IP: $($Pip.IpAddress)"
    }
}


#endregion
