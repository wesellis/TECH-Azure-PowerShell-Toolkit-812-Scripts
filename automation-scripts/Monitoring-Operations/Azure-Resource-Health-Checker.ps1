# ============================================================================
# Script Name: Azure Resource Health Checker
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Checks health status of Azure resources in a Resource Group
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName
)

Write-Host "Checking health status for resources in: $ResourceGroupName"

$Resources = Get-AzResource -ResourceGroupName $ResourceGroupName
$HealthStatus = @()

foreach ($Resource in $Resources) {
    $Status = "Unknown"
    $Details = "Unable to determine"
    
    try {
        switch ($Resource.ResourceType) {
            "Microsoft.Compute/virtualMachines" {
                $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $Resource.Name -Status
                $Status = $VM.Statuses | Where-Object { $_.Code -like "PowerState*" } | Select-Object -ExpandProperty DisplayStatus
            }
            "Microsoft.Web/sites" {
                $WebApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $Resource.Name
                $Status = $WebApp.State
            }
            "Microsoft.Storage/storageAccounts" {
                $Storage = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $Resource.Name
                $Status = $Storage.ProvisioningState
            }
            default {
                $Status = "Active"
            }
        }
    } catch {
        $Status = "Error"
        $Details = $_.Exception.Message
    }
    
    $HealthStatus += [PSCustomObject]@{
        ResourceName = $Resource.Name
        ResourceType = $Resource.ResourceType.Split('/')[-1]
        Status = $Status
        Details = $Details
    }
}

Write-Host "`nResource Health Status:"
Write-Host "=" * 60

foreach ($Health in $HealthStatus) {
    $StatusColor = switch ($Health.Status) {
        { $_ -in @("VM running", "Running", "Succeeded", "Active") } { "✅" }
        { $_ -in @("VM stopped", "Stopped") } { "⏹️" }
        "Error" { "❌" }
        default { "⚠️" }
    }
    
    Write-Host "$StatusColor $($Health.ResourceName) ($($Health.ResourceType)): $($Health.Status)"
}
