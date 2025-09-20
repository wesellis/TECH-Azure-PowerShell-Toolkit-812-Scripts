#Requires -Module Az.Monitor
#Requires -Version 5.1
<#
.SYNOPSIS
    configure diagnostic settings
.DESCRIPTION
    configure diagnostic settings operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Configures diagnostic settings for Azure resources

    Manages diagnostic settings across resources, enabling logging and metrics
    collection to Log Analytics, Storage Accounts, or Event Hubs
.PARAMETER ResourceId
    Resource ID to configure diagnostics for
.PARAMETER WorkspaceId
    Log Analytics workspace resource ID
.PARAMETER StorageAccountId
    Storage account resource ID for archival
.PARAMETER EventHubAuthorizationRuleId
    Event Hub authorization rule ID for streaming
.PARAMETER EnableAllLogs
    Enable all available log categories
.PARAMETER EnableAllMetrics
    Enable all available metrics

    .\configure-diagnostic-settings.ps1 -ResourceId "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.Web/sites/app" -WorkspaceId "/subscriptions/xxx/.../workspace"

    Author: Azure PowerShell Toolkit#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceId,

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $false)]
    [string]$StorageAccountId,

    [Parameter(Mandatory = $false)]
    [string]$EventHubAuthorizationRuleId,

    [Parameter(Mandatory = $false)]
    [string]$DiagnosticSettingName = "DefaultDiagnostics",

    [Parameter(Mandatory = $false)]
    [switch]$EnableAllLogs,

    [Parameter(Mandatory = $false)]
    [switch]$EnableAllMetrics,

    [Parameter(Mandatory = $false)]
    [string[]]$LogCategories,

    [Parameter(Mandatory = $false)]
    [string[]]$MetricCategories,

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 30,

    [Parameter(Mandatory = $false)]
    [switch]$ApplyToResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [switch]$RemoveExisting
)

#region Functions
function Get-ResourceDiagnosticCategories {
    param([string]$ResourceId)

    try {
        $categories = Get-AzDiagnosticSettingCategory -ResourceId $ResourceId
        return @{
            Logs = $categories | Where-Object { $_.CategoryType -eq 'Logs' }
            Metrics = $categories | Where-Object { $_.CategoryType -eq 'Metrics' }
        
} catch {
        Write-Error "Failed to get diagnostic categories: $_"
        return $null
    }
}

function New-DiagnosticSetting {
    param(
        [string]$ResourceId,
        [string]$Name,
        [object]$Categories,
        [hashtable]$Destinations
    )

    $logs = @()
    $metrics = @()

    if ($EnableAllLogs -or $LogCategories) {
        $logCats = if ($EnableAllLogs) { $Categories.Logs } else {
            $Categories.Logs | Where-Object { $_.Name -in $LogCategories }
        }

        foreach ($cat in $logCats) {
            $logs += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category $cat.Name -RetentionPolicyDay $RetentionDays -RetentionPolicyEnabled ($RetentionDays -gt 0)
        }
    }

    if ($EnableAllMetrics -or $MetricCategories) {
        $metricCats = if ($EnableAllMetrics) { $Categories.Metrics } else {
            $Categories.Metrics | Where-Object { $_.Name -in $MetricCategories }
        }

        foreach ($cat in $metricCats) {
            $metrics += New-AzDiagnosticSettingMetricSettingsObject -Enabled $true -Category $cat.Name -RetentionPolicyDay $RetentionDays -RetentionPolicyEnabled ($RetentionDays -gt 0)
        }
    }

    $params = @{
        ResourceId = $ResourceId
        Name = $Name
        Log = $logs
        Metric = $metrics
    }

    if ($Destinations.WorkspaceId) { $params['WorkspaceId'] = $Destinations.WorkspaceId }
    if ($Destinations.StorageAccountId) { $params['StorageAccountId'] = $Destinations.StorageAccountId }
    if ($Destinations.EventHubAuthorizationRuleId) { $params['EventHubAuthorizationRuleId'] = $Destinations.EventHubAuthorizationRuleId }

    if ($PSCmdlet.ShouldProcess($ResourceId, "Configure diagnostic settings")) {
        New-AzDiagnosticSetting @params
    }
}

#endregion

#region Main
try {
    if (-not (Get-AzContext)) {
        Connect-AzAccount
    }

    $destinations = @{}
    if ($WorkspaceId) { $destinations['WorkspaceId'] = $WorkspaceId }
    if ($StorageAccountId) { $destinations['StorageAccountId'] = $StorageAccountId }
    if ($EventHubAuthorizationRuleId) { $destinations['EventHubAuthorizationRuleId'] = $EventHubAuthorizationRuleId }

    if (-not $destinations.Count) {
        throw "At least one destination must be specified"
    }

    $resources = @()
    if ($ApplyToResourceGroup -and $ResourceGroupName) {
        $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    }
    elseif ($ResourceId) {
        $resources = @(Get-AzResource -ResourceId $ResourceId)
    }
    else {
        throw "Either ResourceId or ResourceGroupName must be specified"
    }

    foreach ($resource in $resources) {
        Write-Host "Configuring diagnostics for: $($resource.Name)" -ForegroundColor Yellow

        if ($RemoveExisting) {
            $existing = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId
            foreach ($setting in $existing) {
                Remove-AzDiagnosticSetting -ResourceId $resource.ResourceId -Name $setting.Name
            }
        }

        $categories = Get-ResourceDiagnosticCategories -ResourceId $resource.ResourceId
        if ($categories) {
            New-DiagnosticSetting -ResourceId $resource.ResourceId -Name $DiagnosticSettingName -Categories $categories -Destinations $destinations
            Write-Host "Successfully configured diagnostics for: $($resource.Name)" -ForegroundColor Green
        }
    }

    Write-Host "`nDiagnostic settings configuration completed!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to configure diagnostic settings: $_"
    throw
}

#endregion\n