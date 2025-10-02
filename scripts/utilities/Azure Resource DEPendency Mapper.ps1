#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Resource Dependency Mapper

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter()]
    [switch]$ExportDiagram,
    [Parameter(ValueFromPipeline)]`n    $OutputPath = " .\resource-dependencies.json"
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
    $DependsOn = $DependsOn + $vm.NetworkProfile.NetworkInterfaces.Id
    $DependsOn = $DependsOn + $vm.StorageProfile.OsDisk.ManagedDisk.Id
            }
            "Microsoft.Network/networkInterfaces" {
    $nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $resource.Name
    $DependsOn = $DependsOn + $nic.IpConfigurations.Subnet.Id
                if ($nic.IpConfigurations.PublicIpAddress) {
    $DependsOn = $DependsOn + $nic.IpConfigurations.PublicIpAddress.Id
                }
            }
        }
        if ($DependsOn.Count -gt 0) {
    $dependencies = $dependencies + [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                DependsOn = $DependsOn
            }
        }
    }
    Write-Output "Resource Dependencies Found: $($dependencies.Count)" # Color: $2
    $dependencies | Format-Table ResourceName, ResourceType
    if ($ExportDiagram) {
    $dependencies | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputPath

    }
} catch { throw`n}
