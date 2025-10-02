#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Loganalytics Workspace Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $WorkspaceName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $Location,
    [Parameter()]
    $Sku = "PerGB2018" ,
    [Parameter()]
    [int]$RetentionInDays = 30
)
Write-Output "Creating Log Analytics Workspace: $WorkspaceName"
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Sku = $Sku
    Location = $Location
    RetentionInDays = $RetentionInDays
    ErrorAction = "Stop"
    Name = $WorkspaceName
}
    $Workspace @params
Write-Output "Log Analytics Workspace created successfully:"
Write-Output "Name: $($Workspace.Name)"
Write-Output "Location: $($Workspace.Location)"
Write-Output "SKU: $($Workspace.Sku)"
Write-Output "Retention: $RetentionInDays days"
Write-Output "Workspace ID: $($Workspace.CustomerId)"
    $Keys = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $ResourceGroupName -Name $WorkspaceName
Write-Output " `nWorkspace Keys:"
Write-Output "Primary Key: $($Keys.PrimarySharedKey.Substring(0,8))..."
Write-Output "Secondary Key: $($Keys.SecondarySharedKey.Substring(0,8))..."
Write-Output " `nLog Analytics Features:"
Write-Output "Centralized log collection"
Write-Output "KQL (Kusto Query Language)"
Write-Output "Custom dashboards and workbooks"
Write-Output "Integration with Azure Monitor"
Write-Output "Machine learning insights"
Write-Output "Security and compliance monitoring"
Write-Output " `nNext Steps:"
Write-Output " 1. Configure data sources"
Write-Output " 2. Install agents on VMs"
Write-Output " 3. Create custom queries"
Write-Output " 4. Set up dashboards"
Write-Output " 5. Configure alerts"
Write-Output " `nCommon Data Sources:"
Write-Output "Azure Activity Logs"
Write-Output "VM Performance Counters"
Write-Output "Application Insights"
Write-Output "Security Events"
Write-Output "Custom Applications"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
