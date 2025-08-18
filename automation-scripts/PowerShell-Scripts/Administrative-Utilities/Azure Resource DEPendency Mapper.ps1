<#
.SYNOPSIS
    We Enhanced Azure Resource Dependency Mapper

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEExportDiagram,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " .\resource-dependencies.json"
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName " Azure Resource Dependency Mapper" -Version " 1.0" -Description " Map resource dependencies"

try {
    if (-not (Test-AzureConnection)) { throw " Azure connection validation failed" }

    $resources = Get-AzResource -ResourceGroupName $WEResourceGroupName
    $dependencies = @()

    foreach ($resource in $resources) {
        $dependsOn = @()
        
        # Check for common dependency patterns
        switch ($resource.ResourceType) {
            " Microsoft.Compute/virtualMachines" {
                $vm = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $resource.Name
                $dependsOn = $dependsOn + $vm.NetworkProfile.NetworkInterfaces.Id
                $dependsOn = $dependsOn + $vm.StorageProfile.OsDisk.ManagedDisk.Id
            }
            " Microsoft.Network/networkInterfaces" {
               ;  $nic = Get-AzNetworkInterface -ResourceGroupName $WEResourceGroupName -Name $resource.Name
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

    Write-WELog " Resource Dependencies Found: $($dependencies.Count)" " INFO" -ForegroundColor Cyan
    $dependencies | Format-Table ResourceName, ResourceType

    if ($WEExportDiagram) {
        $dependencies | ConvertTo-Json -Depth 3 | Out-File -FilePath $WEOutputPath
        Write-Log " ✓ Dependencies exported to: $WEOutputPath" -Level SUCCESS
    }

} catch {
    Write-Log " ❌ Dependency mapping failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================