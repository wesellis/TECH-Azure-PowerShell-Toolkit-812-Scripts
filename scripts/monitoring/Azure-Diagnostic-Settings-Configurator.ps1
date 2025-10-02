#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceId,
    [Parameter(Mandatory)]
    [string]$DiagnosticSettingName,
    [Parameter()]
    [string]$WorkspaceId,
    [Parameter()]
    [string]$StorageAccountId,
    [Parameter()]
    [array]$LogCategories = @("Administrative", "Security", "ServiceHealth", "Alert"),
    [Parameter()]
    [array]$MetricCategories = @("AllMetrics")
)
Write-Output "Configuring diagnostic settings for resource: $($ResourceId.Split('/')[-1])"
$DiagnosticParams = @{
    ResourceId = $ResourceId
    Name = $DiagnosticSettingName
}
if ($WorkspaceId) {
    $DiagnosticParams.WorkspaceId = $WorkspaceId
    Write-Output "Log Analytics Workspace: $($WorkspaceId.Split('/')[-1])"
}
if ($StorageAccountId) {
    $DiagnosticParams.StorageAccountId = $StorageAccountId
    Write-Output "Storage Account: $($StorageAccountId.Split('/')[-1])"
}
$LogSettings = @()
foreach ($Category in $LogCategories) {
    $LogSettings += @{
        Category = $Category
        Enabled = $true
        RetentionPolicy = @{
            Enabled = $true
            Days = 30
        }
    }
}
$MetricSettings = @()
foreach ($Category in $MetricCategories) {
    $MetricSettings += @{
        Category = $Category
        Enabled = $true
        RetentionPolicy = @{
            Enabled = $true
            Days = 30
        }
    }
}
$DiagnosticParams.Log = $LogSettings
$DiagnosticParams.Metric = $MetricSettings
$DiagnosticSetting = Set-AzDiagnosticSetting -ErrorAction Stop @DiagnosticParams
Write-Output "Diagnostic settings configured successfully:"
Write-Output "Setting ID: $($DiagnosticSetting.Id)"
Write-Output "Name: $DiagnosticSettingName"
Write-Output "Resource: $($ResourceId.Split('/')[-1])"
Write-Output "Log Categories: $($LogCategories -join ', ')"
Write-Output "Metric Categories: $($MetricCategories -join ', ')"
Write-Output "`nDiagnostic Data Destinations:"
if ($WorkspaceId) {
    Write-Output "   Log Analytics Workspace (for queries and alerts)"
}
if ($StorageAccountId) {
    Write-Output "   Storage Account (for long-term archival)"
}
Write-Output "`nDiagnostic Benefits:"
Write-Output "Centralized logging and monitoring"
Write-Output "Compliance and audit trails"
Write-Output "Performance troubleshooting"
Write-Output "Security event tracking"
Write-Output "Cost optimization insights"



