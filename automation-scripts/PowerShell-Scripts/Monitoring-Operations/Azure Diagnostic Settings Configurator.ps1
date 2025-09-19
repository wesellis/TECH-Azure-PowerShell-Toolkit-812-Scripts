#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Diagnostic Settings Configurator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Diagnostic Settings Configurator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceId,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEDiagnosticSettingName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEWorkspaceId,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEStorageAccountId,
    
    [Parameter(Mandatory=$false)]
    [array]$WELogCategories = @(" Administrative" , " Security" , " ServiceHealth" , " Alert" ),
    
    [Parameter(Mandatory=$false)]
    [array]$WEMetricCategories = @(" AllMetrics" )
)

#region Functions

Write-WELog " Configuring diagnostic settings for resource: $($WEResourceId.Split('/')[-1])" " INFO"


$WEDiagnosticParams = @{
    ResourceId = $WEResourceId
    Name = $WEDiagnosticSettingName
}


if ($WEWorkspaceId) {
    $WEDiagnosticParams.WorkspaceId = $WEWorkspaceId
    Write-WELog "  Log Analytics Workspace: $($WEWorkspaceId.Split('/')[-1])" " INFO"
}

if ($WEStorageAccountId) {
    $WEDiagnosticParams.StorageAccountId = $WEStorageAccountId
    Write-WELog "  Storage Account: $($WEStorageAccountId.Split('/')[-1])" " INFO"
}


$WELogSettings = @()
foreach ($WECategory in $WELogCategories) {
    $WELogSettings = $WELogSettings + @{
        Category = $WECategory
        Enabled = $true
        RetentionPolicy = @{
            Enabled = $true
            Days = 30
        }
    }
}


$WEMetricSettings = @()
foreach ($WECategory in $WEMetricCategories) {
   ;  $WEMetricSettings = $WEMetricSettings + @{
        Category = $WECategory
        Enabled = $true
        RetentionPolicy = @{
            Enabled = $true
            Days = 30
        }
    }
}

$WEDiagnosticParams.Log = $WELogSettings
$WEDiagnosticParams.Metric = $WEMetricSettings

; 
$WEDiagnosticSetting = Set-AzDiagnosticSetting -ErrorAction Stop @DiagnosticParams

Write-WELog "  Diagnostic settings configured successfully:" " INFO"
Write-WELog "  Setting ID: $($WEDiagnosticSetting.Id)" " INFO"
Write-WELog "  Name: $WEDiagnosticSettingName" " INFO"
Write-WELog "  Resource: $($WEResourceId.Split('/')[-1])" " INFO"
Write-WELog "  Log Categories: $($WELogCategories -join ', ')" " INFO"
Write-WELog "  Metric Categories: $($WEMetricCategories -join ', ')" " INFO"

Write-WELog " `nDiagnostic Data Destinations:" " INFO"
if ($WEWorkspaceId) {
    Write-WELog "  • Log Analytics Workspace (for queries and alerts)" " INFO"
}
if ($WEStorageAccountId) {
    Write-WELog "  • Storage Account (for long-term archival)" " INFO"
}

Write-WELog " `nDiagnostic Benefits:" " INFO"
Write-WELog " • Centralized logging and monitoring" " INFO"
Write-WELog " • Compliance and audit trails" " INFO"
Write-WELog " • Performance troubleshooting" " INFO"
Write-WELog " • Security event tracking" " INFO"
Write-WELog " • Cost optimization insights" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
