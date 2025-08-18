<#
.SYNOPSIS
    We Enhanced Azure Resource Health Checker

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



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [string]$WEResourceGroupName
)

Write-Host -Object " Checking health status for resources in: $WEResourceGroupName"

$WEResources = Get-AzResource -ResourceGroupName $WEResourceGroupName
$WEHealthStatus = @()

foreach ($WEResource in $WEResources) {
    $WEStatus = " Unknown"
    $WEDetails = " Unable to determine"
    
    try {
        switch ($WEResource.ResourceType) {
            " Microsoft.Compute/virtualMachines" {
                $WEVM = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEResource.Name -Status
                $WEStatus = $WEVM.Statuses | Where-Object { $_.Code -like " PowerState*" } | Select-Object -ExpandProperty DisplayStatus
            }
            " Microsoft.Web/sites" {
                $WEWebApp = Get-AzWebApp -ResourceGroupName $WEResourceGroupName -Name $WEResource.Name
                $WEStatus = $WEWebApp.State
            }
            " Microsoft.Storage/storageAccounts" {
                $WEStorage = Get-AzStorageAccount -ResourceGroupName $WEResourceGroupName -Name $WEResource.Name
                $WEStatus = $WEStorage.ProvisioningState
            }
            default {
                $WEStatus = " Active"
            }
        }
    } catch {
        $WEStatus = " Error"
        $WEDetails = $_.Exception.Message
    }
    
    $WEHealthStatus = $WEHealthStatus + [PSCustomObject]@{
        ResourceName = $WEResource.Name
        ResourceType = $WEResource.ResourceType.Split('/')[-1]
        Status = $WEStatus
        Details = $WEDetails
    }
}

Write-Host -Object " `nResource Health Status:"
Write-Host -Object (" =" * 60)

foreach ($WEHealth in $WEHealthStatus) {
   ;  $WEStatusColor = switch ($WEHealth.Status) {
        { $_ -in @(" VM running", " Running", " Succeeded", " Active") } { " ✅" }
        { $_ -in @(" VM stopped", " Stopped") } { " ⏹️" }
        " Error" { " ❌" }
        default { " ⚠️" }
    }
    
    Write-Host -Object " $WEStatusColor $($WEHealth.ResourceName) ($($WEHealth.ResourceType)): $($WEHealth.Status)"
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================