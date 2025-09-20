#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Logicapp Provisioning Tool

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AppName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PlanName,
    [string]$PlanSku = "WS1" ,
    [hashtable]$Tags = @{}
)
Write-Host "Provisioning Logic App: $AppName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
if ($PlanName) {
    Write-Host "App Service Plan: $PlanName"
    # Check if plan exists
    $Plan = Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $PlanName -ErrorAction SilentlyContinue
    if (-not $Plan) {
        Write-Host "Creating App Service Plan for Logic App..."
        $params = @{
            ResourceGroupName = $ResourceGroupName
            Tier = "WorkflowStandard"
            WorkerSize = "WS1"  Write-Host "App Service Plan created: $($Plan.Name)" "INFO" } else { Write-Host "Using existing App Service Plan: $($Plan.Name)" }"
            Location = $Location
            ErrorAction = "Stop"
            Name = $PlanName
        }
        $Plan @params
}
Write-Host " `nCreating Logic App..."
if ($PlanName) {
    # Logic App with dedicated plan (Standard tier)
   $params = @{
       AppServicePlan = $PlanName
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $AppName
       Location = $Location
   }
   ; @params
} else {
    # Consumption-based Logic App
   $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $AppName
       Location = $Location
   }
   ; @params
}
if ($Tags.Count -gt 0) {
    Write-Host " `nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Host "  $($Tag.Key): $($Tag.Value)"
    }
    Set-AzResource -ResourceId $LogicApp.Id -Tag $Tags -Force
}
Write-Host " `nLogic App $AppName provisioned successfully"
Write-Host "Logic App ID: $($LogicApp.Id)"
Write-Host "State: $($LogicApp.State)"
Write-Host "Definition: $($LogicApp.Definition)"
if ($PlanName) {
    Write-Host "Plan Type: Standard (Dedicated)"
    Write-Host "Plan Name: $PlanName"
} else {
    Write-Host "Plan Type: Consumption"
}
Write-Host " `nLogic App Designer:"
Write-Host "Portal URL: https://portal.azure.com/#@/resource$($LogicApp.Id)/designer"
Write-Host " `nNext Steps:"
Write-Host " 1. Open Logic App Designer in Azure Portal"
Write-Host " 2. Add triggers (HTTP, Schedule, Event Grid, etc.)"
Write-Host " 3. Add actions (Send email, call APIs, data operations)"
Write-Host " 4. Configure connectors for external services"
Write-Host " 5. Test and enable the Logic App workflow"
Write-Host " `nCommon Triggers:"
Write-Host "   HTTP Request (webhook)"
Write-Host "   Recurrence (scheduled)"
Write-Host "   Event Grid events"
Write-Host "   Service Bus messages"
Write-Host "   File system changes"
Write-Host " `nCommon Actions:"
Write-Host "   HTTP requests to APIs"
Write-Host "   Send emails (Office 365, Outlook)"
Write-Host "   Database operations (SQL, Cosmos DB)"
Write-Host "   File operations (SharePoint, OneDrive)"
Write-Host "   Conditional logic and loops"
Write-Host " `nLogic App provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


