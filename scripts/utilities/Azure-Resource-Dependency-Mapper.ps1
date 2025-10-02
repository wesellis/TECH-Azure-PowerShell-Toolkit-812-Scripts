#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Map resource dependencies

.DESCRIPTION
    Map resource dependencies
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    $ResourceGroupName,
    [Parameter()]
    [switch]$ExportDiagram,
    [Parameter()]
    $OutputPath = ".\resource-dependencies.json"
)
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    $dependencies = @()
    foreach ($resource in $resources) {
        $DependsOn = @()
        switch ($resource.ResourceType) {
            "Microsoft.Compute/virtualMachines" {
                $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $resource.Name
                $DependsOn += $vm.NetworkProfile.NetworkInterfaces.Id
                $DependsOn += $vm.StorageProfile.OsDisk.ManagedDisk.Id
            }
            "Microsoft.Network/networkInterfaces" {
                $nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $resource.Name
                $DependsOn += $nic.IpConfigurations.Subnet.Id
                if ($nic.IpConfigurations.PublicIpAddress) {
                    $DependsOn += $nic.IpConfigurations.PublicIpAddress.Id
                }
            }
        }
        if ($DependsOn.Count -gt 0) {
            $dependencies += [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                DependsOn = $DependsOn
            }
        }
    }
    Write-Output "Resource Dependencies Found: $($dependencies.Count)"
    $dependencies | Format-Table ResourceName, ResourceType
    if ($ExportDiagram) {
        $dependencies | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputPath

    }
} catch { throw`n}
