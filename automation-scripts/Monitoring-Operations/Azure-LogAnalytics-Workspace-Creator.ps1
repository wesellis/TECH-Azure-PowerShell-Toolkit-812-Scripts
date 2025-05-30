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

Write-Host "Creating Log Analytics Workspace: $WorkspaceName"

$Workspace = New-AzOperationalInsightsWorkspace `
    -ResourceGroupName $ResourceGroupName `
    -Name $WorkspaceName `
    -Location $Location `
    -Sku $Sku `
    -RetentionInDays $RetentionInDays

Write-Host "✅ Log Analytics Workspace created successfully:"
Write-Host "  Name: $($Workspace.Name)"
Write-Host "  Location: $($Workspace.Location)"
Write-Host "  SKU: $($Workspace.Sku)"
Write-Host "  Retention: $RetentionInDays days"
Write-Host "  Workspace ID: $($Workspace.CustomerId)"

# Get workspace keys
$Keys = Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $ResourceGroupName -Name $WorkspaceName

Write-Host "`nWorkspace Keys:"
Write-Host "  Primary Key: $($Keys.PrimarySharedKey.Substring(0,8))..."
Write-Host "  Secondary Key: $($Keys.SecondarySharedKey.Substring(0,8))..."

Write-Host "`nLog Analytics Features:"
Write-Host "• Centralized log collection"
Write-Host "• KQL (Kusto Query Language)"
Write-Host "• Custom dashboards and workbooks"
Write-Host "• Integration with Azure Monitor"
Write-Host "• Machine learning insights"
Write-Host "• Security and compliance monitoring"

Write-Host "`nNext Steps:"
Write-Host "1. Configure data sources"
Write-Host "2. Install agents on VMs"
Write-Host "3. Create custom queries"
Write-Host "4. Set up dashboards"
Write-Host "5. Configure alerts"

Write-Host "`nCommon Data Sources:"
Write-Host "• Azure Activity Logs"
Write-Host "• VM Performance Counters"
Write-Host "• Application Insights"
Write-Host "• Security Events"
Write-Host "• Custom Applications"
