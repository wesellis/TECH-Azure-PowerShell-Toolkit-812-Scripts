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
    [string]$ResourceId,
    
    [Parameter(Mandatory=$true)]
    [string]$DiagnosticSettingName,
    
    [Parameter(Mandatory=$false)]
    [string]$WorkspaceId,
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountId,
    
    [Parameter(Mandatory=$false)]
    [array]$LogCategories = @("Administrative", "Security", "ServiceHealth", "Alert"),
    
    [Parameter(Mandatory=$false)]
    [array]$MetricCategories = @("AllMetrics")
)

#region Functions

Write-Information "Configuring diagnostic settings for resource: $($ResourceId.Split('/')[-1])"

# Build diagnostic setting parameters
$DiagnosticParams = @{
    ResourceId = $ResourceId
    Name = $DiagnosticSettingName
}

# Configure destinations
if ($WorkspaceId) {
    $DiagnosticParams.WorkspaceId = $WorkspaceId
    Write-Information "  Log Analytics Workspace: $($WorkspaceId.Split('/')[-1])"
}

if ($StorageAccountId) {
    $DiagnosticParams.StorageAccountId = $StorageAccountId
    Write-Information "  Storage Account: $($StorageAccountId.Split('/')[-1])"
}

# Configure log categories
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

# Configure metric categories
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

# Create diagnostic setting
$DiagnosticSetting = Set-AzDiagnosticSetting -ErrorAction Stop @DiagnosticParams

Write-Information " Diagnostic settings configured successfully:"
Write-Information "  Setting ID: $($DiagnosticSetting.Id)"
Write-Information "  Name: $DiagnosticSettingName"
Write-Information "  Resource: $($ResourceId.Split('/')[-1])"
Write-Information "  Log Categories: $($LogCategories -join ', ')"
Write-Information "  Metric Categories: $($MetricCategories -join ', ')"

Write-Information "`nDiagnostic Data Destinations:"
if ($WorkspaceId) {
    Write-Information "  • Log Analytics Workspace (for queries and alerts)"
}
if ($StorageAccountId) {
    Write-Information "  • Storage Account (for long-term archival)"
}

Write-Information "`nDiagnostic Benefits:"
Write-Information "• Centralized logging and monitoring"
Write-Information "• Compliance and audit trails"
Write-Information "• Performance troubleshooting"
Write-Information "• Security event tracking"
Write-Information "• Cost optimization insights"


#endregion
