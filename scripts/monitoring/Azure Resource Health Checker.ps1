#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute
#Requires -Modules Az.Storage

<#
.SYNOPSIS
    Azure Resource Health Checker

.DESCRIPTION
    Azure automation for checking resource health status

.AUTHOR
    Wesley Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Write-Log {
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }
    $LogEntry = "$timestamp [Health-Check] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $ColorMap[$Level]
}

try {
    Write-Log "Checking health status for resources in: $ResourceGroupName" "INFO"

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

    Write-Log "`nResource Health Status:" "INFO"
    Write-Log ("=" * 60) "INFO"

    foreach ($Health in $HealthStatus) {
        $StatusColor = switch ($Health.Status) {
            { $_ -in @("VM running", "Running", "Succeeded", "Active") } { "Green" }
            { $_ -in @("VM stopped", "Stopped") } { "Yellow" }
            { $_ -eq "Error" } { "Red" }
            default { "Cyan" }
        }

        Write-Host "$($Health.ResourceName) ($($Health.ResourceType)): $($Health.Status)" -ForegroundColor $StatusColor

        if ($Health.Details -ne "Unable to determine") {
            Write-Host "  Details: $($Health.Details)" -ForegroundColor Gray
        }
    }

    # Summary
    $TotalResources = $HealthStatus.Count
    $HealthyResources = ($HealthStatus | Where-Object { $_.Status -in @("VM running", "Running", "Succeeded", "Active") }).Count
    $WarningResources = ($HealthStatus | Where-Object { $_.Status -in @("VM stopped", "Stopped") }).Count
    $ErrorResources = ($HealthStatus | Where-Object { $_.Status -eq "Error" }).Count

    Write-Log "`nSummary:" "INFO"
    Write-Log "Total Resources: $TotalResources" "INFO"
    Write-Log "Healthy: $HealthyResources" "SUCCESS"
    Write-Log "Warning: $WarningResources" "WARN"
    Write-Log "Error: $ErrorResources" "ERROR"

} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}