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
    [string]$ResourceGroupName
)

#region Functions

Write-Information -Object "Checking health status for resources in: $ResourceGroupName"

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

Write-Information -Object "`nResource Health Status:"
Write-Information -Object ("=" * 60)

foreach ($Health in $HealthStatus) {
    $StatusColor = switch ($Health.Status) {
        { $_ -in @("VM running", "Running", "Succeeded", "Active") } { "" }
        { $_ -in @("VM stopped", "Stopped") } { "⏹️" }
        "Error" { "" }
        default { "[WARN]️" }
    }
    
    Write-Information -Object "$StatusColor $($Health.ResourceName) ($($Health.ResourceType)): $($Health.Status)"
}


#endregion
