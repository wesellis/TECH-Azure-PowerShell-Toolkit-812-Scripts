<#
.SYNOPSIS
    Azure Loganalytics Workspace Creator

.DESCRIPTION
    Azure automation
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
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkspaceName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [string]$Sku = "PerGB2018" ,
    [Parameter()]
    [int]$RetentionInDays = 30
)
Write-Host "Creating Log Analytics Workspace: $WorkspaceName"
$params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    Location = $Location
    RetentionInDays = $RetentionInDays
    ErrorAction = "Stop"
    Name = $WorkspaceName
}
$Workspace @params
Write-Host "Log Analytics Workspace created successfully:"
Write-Host "Name: $($Workspace.Name)"
Write-Host "Location: $($Workspace.Location)"
Write-Host "SKU: $($Workspace.Sku)"
Write-Host "Retention: $RetentionInDays days"
Write-Host "Workspace ID: $($Workspace.CustomerId)"
$Keys = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
Write-Host " `nWorkspace Keys:"
Write-Host "Primary Key: $($Keys.PrimarySharedKey.Substring(0,8))..."
Write-Host "Secondary Key: $($Keys.SecondarySharedKey.Substring(0,8))..."
Write-Host " `nLog Analytics Features:"
Write-Host "Centralized log collection"
Write-Host "KQL (Kusto Query Language)"
Write-Host "Custom dashboards and workbooks"
Write-Host "Integration with Azure Monitor"
Write-Host "Machine learning insights"
Write-Host "Security and compliance monitoring"
Write-Host " `nNext Steps:"
Write-Host " 1. Configure data sources"
Write-Host " 2. Install agents on VMs"
Write-Host " 3. Create custom queries"
Write-Host " 4. Set up dashboards"
Write-Host " 5. Configure alerts"
Write-Host " `nCommon Data Sources:"
Write-Host "Azure Activity Logs"
Write-Host "VM Performance Counters"
Write-Host "Application Insights"
Write-Host "Security Events"
Write-Host "Custom Applications"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

