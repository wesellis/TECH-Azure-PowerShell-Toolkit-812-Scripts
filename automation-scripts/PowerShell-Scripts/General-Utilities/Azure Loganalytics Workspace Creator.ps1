<#
.SYNOPSIS
    Azure Loganalytics Workspace Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Loganalytics Workspace Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEWorkspaceName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [string]$WESku = " PerGB2018" ,
    
    [Parameter(Mandatory=$false)]
    [int]$WERetentionInDays = 30
)

Write-WELog " Creating Log Analytics Workspace: $WEWorkspaceName" " INFO"
; 
$WEWorkspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEWorkspaceName `
    -Location $WELocation `
    -Sku $WESku `
    -RetentionInDays $WERetentionInDays

Write-WELog " ✅ Log Analytics Workspace created successfully:" " INFO"
Write-WELog "  Name: $($WEWorkspace.Name)" " INFO"
Write-WELog "  Location: $($WEWorkspace.Location)" " INFO"
Write-WELog "  SKU: $($WEWorkspace.Sku)" " INFO"
Write-WELog "  Retention: $WERetentionInDays days" " INFO"
Write-WELog "  Workspace ID: $($WEWorkspace.CustomerId)" " INFO"

; 
$WEKeys = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $WEResourceGroupName -Name $WEWorkspaceName

Write-WELog " `nWorkspace Keys:" " INFO"
Write-WELog "  Primary Key: $($WEKeys.PrimarySharedKey.Substring(0,8))..." " INFO"
Write-WELog "  Secondary Key: $($WEKeys.SecondarySharedKey.Substring(0,8))..." " INFO"

Write-WELog " `nLog Analytics Features:" " INFO"
Write-WELog " • Centralized log collection" " INFO"
Write-WELog " • KQL (Kusto Query Language)" " INFO"
Write-WELog " • Custom dashboards and workbooks" " INFO"
Write-WELog " • Integration with Azure Monitor" " INFO"
Write-WELog " • Machine learning insights" " INFO"
Write-WELog " • Security and compliance monitoring" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Configure data sources" " INFO"
Write-WELog " 2. Install agents on VMs" " INFO"
Write-WELog " 3. Create custom queries" " INFO"
Write-WELog " 4. Set up dashboards" " INFO"
Write-WELog " 5. Configure alerts" " INFO"

Write-WELog " `nCommon Data Sources:" " INFO"
Write-WELog " • Azure Activity Logs" " INFO"
Write-WELog " • VM Performance Counters" " INFO"
Write-WELog " • Application Insights" " INFO"
Write-WELog " • Security Events" " INFO"
Write-WELog " • Custom Applications" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
