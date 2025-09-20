<#
.SYNOPSIS
    Azure Resource Health Checker

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName
)
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
$HealthStatus = $HealthStatus + [PSCustomObject]@{
        ResourceName = $Resource.Name
        ResourceType = $Resource.ResourceType.Split('/')[-1]
        Status = $Status
        Details = $Details
    }
}
Write-Information -Object " `nResource Health Status:"
Write-Information -Object (" =" * 60)
foreach ($Health in $HealthStatus) {
$StatusColor = switch ($Health.Status) {
        { $_ -in @("VM running" , "Running" , "Succeeded" , "Active" ) } { " " }
        { $_ -in @("VM stopped" , "Stopped" ) } { " " }
        "Error" { " " }
        default { " [WARN]" }
    }
    Write-Information -Object " $StatusColor $($Health.ResourceName) ($($Health.ResourceType)): $($Health.Status)"
}\n