#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Diagnostic Settings Configurator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceId,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DiagnosticSettingName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceId,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountId,
    [Parameter()]
    [array]$LogCategories = @("Administrative" , "Security" , "ServiceHealth" , "Alert" ),
    [Parameter()]
    [array]$MetricCategories = @("AllMetrics" )
)
Write-Output "Configuring diagnostic settings for resource: $($ResourceId.Split('/')[-1])" "INFO"
    $DiagnosticParams = @{
    ResourceId = $ResourceId
    Name = $DiagnosticSettingName
}
if ($WorkspaceId) {
    [string]$DiagnosticParams.WorkspaceId = $WorkspaceId
    Write-Output "Log Analytics Workspace: $($WorkspaceId.Split('/')[-1])" "INFO"
}
if ($StorageAccountId) {
    [string]$DiagnosticParams.StorageAccountId = $StorageAccountId
    Write-Output "Storage Account: $($StorageAccountId.Split('/')[-1])" "INFO"
}
    [string]$LogSettings = @()
foreach ($Category in $LogCategories) {
    [string]$LogSettings = $LogSettings + @{
        Category = $Category
        Enabled = $true
        RetentionPolicy = @{
            Enabled = $true
            Days = 30
        }
    }
}
    [string]$MetricSettings = @()
foreach ($Category in $MetricCategories) {
    [string]$MetricSettings = $MetricSettings + @{
        Category = $Category
        Enabled = $true
        RetentionPolicy = @{
            Enabled = $true
            Days = 30
        }
    }
}
    [string]$DiagnosticParams.Log = $LogSettings
    [string]$DiagnosticParams.Metric = $MetricSettings
    [string]$DiagnosticSetting = Set-AzDiagnosticSetting -ErrorAction Stop @DiagnosticParams
Write-Output "Diagnostic settings configured successfully:" "INFO"
Write-Output "Setting ID: $($DiagnosticSetting.Id)" "INFO"
Write-Output "Name: $DiagnosticSettingName" "INFO"
Write-Output "Resource: $($ResourceId.Split('/')[-1])" "INFO"
Write-Output "Log Categories: $($LogCategories -join ', ')" "INFO"
Write-Output "Metric Categories: $($MetricCategories -join ', ')" "INFO"
Write-Output " `nDiagnostic Data Destinations:" "INFO"
if ($WorkspaceId) {
    Write-Output "   Log Analytics Workspace (for queries and alerts)" "INFO"
}
if ($StorageAccountId) {
    Write-Output "   Storage Account (for long-term archival)" "INFO"
}
Write-Output " `nDiagnostic Benefits:" "INFO"
Write-Output "Centralized logging and monitoring" "INFO"
Write-Output "Compliance and audit trails" "INFO"
Write-Output "Performance troubleshooting" "INFO"
Write-Output "Security event tracking" "INFO"
Write-Output "Cost optimization insights" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
