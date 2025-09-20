#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Diagnostic Settings Configurator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
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
Write-Host "Configuring diagnostic settings for resource: $($ResourceId.Split('/')[-1])" "INFO"
$DiagnosticParams = @{
    ResourceId = $ResourceId
    Name = $DiagnosticSettingName
}
if ($WorkspaceId) {
    $DiagnosticParams.WorkspaceId = $WorkspaceId
    Write-Host "Log Analytics Workspace: $($WorkspaceId.Split('/')[-1])" "INFO"
}
if ($StorageAccountId) {
    $DiagnosticParams.StorageAccountId = $StorageAccountId
    Write-Host "Storage Account: $($StorageAccountId.Split('/')[-1])" "INFO"
}
$LogSettings = @()
foreach ($Category in $LogCategories) {
    $LogSettings = $LogSettings + @{
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
$MetricSettings = $MetricSettings + @{
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
Write-Host "Diagnostic settings configured successfully:" "INFO"
Write-Host "Setting ID: $($DiagnosticSetting.Id)" "INFO"
Write-Host "Name: $DiagnosticSettingName" "INFO"
Write-Host "Resource: $($ResourceId.Split('/')[-1])" "INFO"
Write-Host "Log Categories: $($LogCategories -join ', ')" "INFO"
Write-Host "Metric Categories: $($MetricCategories -join ', ')" "INFO"
Write-Host " `nDiagnostic Data Destinations:" "INFO"
if ($WorkspaceId) {
    Write-Host "   Log Analytics Workspace (for queries and alerts)" "INFO"
}
if ($StorageAccountId) {
    Write-Host "   Storage Account (for long-term archival)" "INFO"
}
Write-Host " `nDiagnostic Benefits:" "INFO"
Write-Host "Centralized logging and monitoring" "INFO"
Write-Host "Compliance and audit trails" "INFO"
Write-Host "Performance troubleshooting" "INFO"
Write-Host "Security event tracking" "INFO"
Write-Host "Cost optimization insights" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


