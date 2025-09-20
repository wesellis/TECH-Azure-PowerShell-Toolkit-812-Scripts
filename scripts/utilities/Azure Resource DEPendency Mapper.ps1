#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Resource Dependency Mapper

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [switch]$ExportDiagram,
    [Parameter(ValueFromPipeline)]`n    [string]$OutputPath = " .\resource-dependencies.json"
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
                $dependsOn = $dependsOn + $vm.NetworkProfile.NetworkInterfaces.Id
$dependsOn = $dependsOn + $vm.StorageProfile.OsDisk.ManagedDisk.Id
            }
            "Microsoft.Network/networkInterfaces" {
$nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $resource.Name
                $dependsOn = $dependsOn + $nic.IpConfigurations.Subnet.Id
                if ($nic.IpConfigurations.PublicIpAddress) {
                    $dependsOn = $dependsOn + $nic.IpConfigurations.PublicIpAddress.Id
                }
            }
        }
        if ($dependsOn.Count -gt 0) {
$dependencies = $dependencies + [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                DependsOn = $dependsOn
            }
        }
    }
    Write-Host "Resource Dependencies Found: $($dependencies.Count)" -ForegroundColor Cyan
    $dependencies | Format-Table ResourceName, ResourceType
    if ($ExportDiagram) {
        $dependencies | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputPath

    }
} catch { throw }


