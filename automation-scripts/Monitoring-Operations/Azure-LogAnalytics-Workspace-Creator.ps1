# ============================================================================
# Script Name: Azure Log Analytics Workspace Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Log Analytics Workspace for centralized logging
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$Sku = "PerGB2018",
    
    [Parameter(Mandatory=$false)]
    [int]$RetentionInDays = 30
)

Write-Information "Creating Log Analytics Workspace: $WorkspaceName"

$Workspace = New-AzOperationalInsightsWorkspace -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $WorkspaceName `
    -Location $Location `
    -Sku $Sku `
    -RetentionInDays $RetentionInDays

Write-Information "✅ Log Analytics Workspace created successfully:"
Write-Information "  Name: $($Workspace.Name)"
Write-Information "  Location: $($Workspace.Location)"
Write-Information "  SKU: $($Workspace.Sku)"
Write-Information "  Retention: $RetentionInDays days"
Write-Information "  Workspace ID: $($Workspace.CustomerId)"

# Get workspace keys
$Keys = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $ResourceGroupName -Name $WorkspaceName

Write-Information "`nWorkspace Keys:"
Write-Information "  Primary Key: $($Keys.PrimarySharedKey.Substring(0,8))..."
Write-Information "  Secondary Key: $($Keys.SecondarySharedKey.Substring(0,8))..."

Write-Information "`nLog Analytics Features:"
Write-Information "• Centralized log collection"
Write-Information "• KQL (Kusto Query Language)"
Write-Information "• Custom dashboards and workbooks"
Write-Information "• Integration with Azure Monitor"
Write-Information "• Machine learning insights"
Write-Information "• Security and compliance monitoring"

Write-Information "`nNext Steps:"
Write-Information "1. Configure data sources"
Write-Information "2. Install agents on VMs"
Write-Information "3. Create custom queries"
Write-Information "4. Set up dashboards"
Write-Information "5. Configure alerts"

Write-Information "`nCommon Data Sources:"
Write-Information "• Azure Activity Logs"
Write-Information "• VM Performance Counters"
Write-Information "• Application Insights"
Write-Information "• Security Events"
Write-Information "• Custom Applications"
