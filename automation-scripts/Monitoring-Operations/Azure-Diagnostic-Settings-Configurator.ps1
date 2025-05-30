# ============================================================================
# Script Name: Azure Diagnostic Settings Configurator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Configures diagnostic settings for Azure resources
# ============================================================================

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

Write-Host "Configuring diagnostic settings for resource: $($ResourceId.Split('/')[-1])"

# Build diagnostic setting parameters
$DiagnosticParams = @{
    ResourceId = $ResourceId
    Name = $DiagnosticSettingName
}

# Configure destinations
if ($WorkspaceId) {
    $DiagnosticParams.WorkspaceId = $WorkspaceId
    Write-Host "  Log Analytics Workspace: $($WorkspaceId.Split('/')[-1])"
}

if ($StorageAccountId) {
    $DiagnosticParams.StorageAccountId = $StorageAccountId
    Write-Host "  Storage Account: $($StorageAccountId.Split('/')[-1])"
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
$DiagnosticSetting = Set-AzDiagnosticSetting @DiagnosticParams

Write-Host "✅ Diagnostic settings configured successfully:"
Write-Host "  Name: $DiagnosticSettingName"
Write-Host "  Resource: $($ResourceId.Split('/')[-1])"
Write-Host "  Log Categories: $($LogCategories -join ', ')"
Write-Host "  Metric Categories: $($MetricCategories -join ', ')"

Write-Host "`nDiagnostic Data Destinations:"
if ($WorkspaceId) {
    Write-Host "  • Log Analytics Workspace (for queries and alerts)"
}
if ($StorageAccountId) {
    Write-Host "  • Storage Account (for long-term archival)"
}

Write-Host "`nDiagnostic Benefits:"
Write-Host "• Centralized logging and monitoring"
Write-Host "• Compliance and audit trails"
Write-Host "• Performance troubleshooting"
Write-Host "• Security event tracking"
Write-Host "• Cost optimization insights"
