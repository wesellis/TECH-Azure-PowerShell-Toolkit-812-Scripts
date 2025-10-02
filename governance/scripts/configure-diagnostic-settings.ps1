#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    configure diagnostic settings
.DESCRIPTION
    configure diagnostic settings operation
    Author: Wes Ellis (wes@wesellis.com)

    Configures diagnostic settings for Azure resources

    Manages diagnostic settings across resources, enabling logging and metrics
    collection to Log Analytics, Storage Accounts, or Event Hubs
.parameter ResourceId
    Resource ID to configure diagnostics for
.parameter WorkspaceId
    Log Analytics workspace resource ID
.parameter StorageAccountId
    Storage account resource ID for archival
.parameter EventHubAuthorizationRuleId
    Event Hub authorization rule ID for streaming
.parameter EnableAllLogs
    Enable all available log categories
.parameter EnableAllMetrics
    Enable all available metrics

    .\configure-diagnostic-settings.ps1 -ResourceId "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.Web/sites/app" -WorkspaceId "/subscriptions/xxx/.../workspace"

    Author: Azure PowerShell Toolkit

[parameter(Mandatory = $false)]
    [string]$ResourceId,

    [parameter(Mandatory = $false)]
    [string]$WorkspaceId,

    [parameter(Mandatory = $false)]
    [string]$StorageAccountId,

    [parameter(Mandatory = $false)]
    [string]$EventHubAuthorizationRuleId,

    [parameter(Mandatory = $false)]
    [string]$DiagnosticSettingName = "DefaultDiagnostics",

    [parameter(Mandatory = $false)]
    [switch]$EnableAllLogs,

    [parameter(Mandatory = $false)]
    [switch]$EnableAllMetrics,

    [parameter(Mandatory = $false)]
    [string[]]$LogCategories,

    [parameter(Mandatory = $false)]
    [string[]]$MetricCategories,

    [parameter(Mandatory = $false)]
    [int]$RetentionDays = 30,

    [parameter(Mandatory = $false)]
    [switch]$ApplyToResourceGroup,

    [parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [parameter(Mandatory = $false)]
    [switch]$RemoveExisting
)

[OutputType([PSCustomObject])] 
 {
    [string]$ResourceId)

    try {
        $categories = Get-AzDiagnosticSettingCategory -ResourceId $ResourceId
        return @{
            Logs = $categories | Where-Object { $_.CategoryType -eq 'Logs' }
            Metrics = $categories | Where-Object { $_.CategoryType -eq 'Metrics' }

} catch {
        write-Error "Failed to get diagnostic categories: $_"
        return $null
    }
}

function New-DiagnosticSetting {
    [string]$ResourceId,
        [string]$Name,
        [object]$Categories,
        [hashtable]$Destinations
    )

    $logs = @()
    $metrics = @()

    if ($EnableAllLogs -or $LogCategories) {
        $LogCats = if ($EnableAllLogs) { $Categories.Logs } else {
            $Categories.Logs | Where-Object { $_.Name -in $LogCategories }
        }

        foreach ($cat in $LogCats) {
            $logs += New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category $cat.Name -RetentionPolicyDay $RetentionDays -RetentionPolicyEnabled ($RetentionDays -gt 0)
        }
    }

    if ($EnableAllMetrics -or $MetricCategories) {
        $MetricCats = if ($EnableAllMetrics) { $Categories.Metrics } else {
            $Categories.Metrics | Where-Object { $_.Name -in $MetricCategories }
        }

        foreach ($cat in $MetricCats) {
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
        Write-Host "Configuring diagnostics for: $($resource.Name)" -ForegroundColor Green

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
    write-Error "Failed to configure diagnostic settings: $_"
    throw}
