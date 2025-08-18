# Azure Resource Dependency Mapper
# Map dependencies between Azure resources
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportDiagram,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\resource-dependencies.json"
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Resource Dependency Mapper" -Version "1.0" -Description "Map resource dependencies"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection validation failed" }

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

    Write-Information "Resource Dependencies Found: $($dependencies.Count)"
    $dependencies | Format-Table ResourceName, ResourceType

    if ($ExportDiagram) {
        $dependencies | ConvertTo-Json -Depth 3 | Out-File -FilePath $OutputPath
        Write-Log "✓ Dependencies exported to: $OutputPath" -Level SUCCESS
    }

} catch {
    Write-Log "❌ Dependency mapping failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
