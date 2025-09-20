<#
.SYNOPSIS
    Map resource dependencies

.DESCRIPTION
    Map resource dependencies
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Resource Dependency Mapper
# Map dependencies between Azure resources
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter()]
    [switch]$ExportDiagram,
    [Parameter()]
    [string]$OutputPath = ".\resource-dependencies.json"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    $dependencies = @()
    foreach ($resource in $resources) {
        $dependsOn = @()
        # Check for common dependency patterns
        switch ($resource.ResourceType) {
            "Microsoft.Compute/virtualMachines" {
                $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $resource.Name
                $dependsOn += $vm.NetworkProfile.NetworkInterfaces.Id
                $dependsOn += $vm.StorageProfile.OsDisk.ManagedDisk.Id
            }
            "Microsoft.Network/networkInterfaces" {
                $nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $resource.Name
                $dependsOn += $nic.IpConfigurations.Subnet.Id
                if ($nic.IpConfigurations.PublicIpAddress) {
                    $dependsOn += $nic.IpConfigurations.PublicIpAddress.Id
                }
            }
        }
        if ($dependsOn.Count -gt 0) {
            $dependencies += [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                DependsOn = $dependsOn
            }
        }
    }
    Write-Host "Resource Dependencies Found: $($dependencies.Count)"
    $dependencies | Format-Table ResourceName, ResourceType
    if ($ExportDiagram) {
        $dependencies | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputPath
        
    }
} catch { throw }

