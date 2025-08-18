# ============================================================================
# Script Name: Azure Logic App Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Logic Apps for workflow automation and integration
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$AppName,
    [string]$Location,
    [string]$PlanName,
    [string]$PlanSku = "WS1",
    [hashtable]$Tags = @{}
)

Write-Information "Provisioning Logic App: $AppName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"

# Check if App Service Plan is provided, create if needed
if ($PlanName) {
    Write-Information "App Service Plan: $PlanName"
    
    # Check if plan exists
    $Plan = Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $PlanName -ErrorAction SilentlyContinue
    
    if (-not $Plan) {
        Write-Information "Creating App Service Plan for Logic App..."
        $Plan = New-AzAppServicePlan -ErrorAction Stop `
            -ResourceGroupName $ResourceGroupName `
            -Name $PlanName `
            -Location $Location `
            -Tier "WorkflowStandard" `
            -WorkerSize "WS1"
        
        Write-Information "App Service Plan created: $($Plan.Name)"
    } else {
        Write-Information "Using existing App Service Plan: $($Plan.Name)"
    }
}

# Create the Logic App
Write-Information "`nCreating Logic App..."
if ($PlanName) {
    # Logic App with dedicated plan (Standard tier)
    $LogicApp = New-AzLogicApp -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppName `
        -Location $Location `
        -AppServicePlan $PlanName
} else {
    # Consumption-based Logic App
    $LogicApp = New-AzLogicApp -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppName `
        -Location $Location
}

# Apply tags if provided
if ($Tags.Count -gt 0) {
    Write-Information "`nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Information "  $($Tag.Key): $($Tag.Value)"
    }
    Set-AzResource -ResourceId $LogicApp.Id -Tag $Tags -Force
}

Write-Information "`nLogic App $AppName provisioned successfully"
Write-Information "Logic App ID: $($LogicApp.Id)"
Write-Information "State: $($LogicApp.State)"
Write-Information "Definition: $($LogicApp.Definition)"

if ($PlanName) {
    Write-Information "Plan Type: Standard (Dedicated)"
    Write-Information "Plan Name: $PlanName"
} else {
    Write-Information "Plan Type: Consumption"
}

Write-Information "`nLogic App Designer:"
Write-Information "Portal URL: https://portal.azure.com/#@/resource$($LogicApp.Id)/designer"

Write-Information "`nNext Steps:"
Write-Information "1. Open Logic App Designer in Azure Portal"
Write-Information "2. Add triggers (HTTP, Schedule, Event Grid, etc.)"
Write-Information "3. Add actions (Send email, call APIs, data operations)"
Write-Information "4. Configure connectors for external services"
Write-Information "5. Test and enable the Logic App workflow"

Write-Information "`nCommon Triggers:"
Write-Information "  • HTTP Request (webhook)"
Write-Information "  • Recurrence (scheduled)"
Write-Information "  • Event Grid events"
Write-Information "  • Service Bus messages"
Write-Information "  • File system changes"

Write-Information "`nCommon Actions:"
Write-Information "  • HTTP requests to APIs"
Write-Information "  • Send emails (Office 365, Outlook)"
Write-Information "  • Database operations (SQL, Cosmos DB)"
Write-Information "  • File operations (SharePoint, OneDrive)"
Write-Information "  • Conditional logic and loops"

Write-Information "`nLogic App provisioning completed at $(Get-Date)"
