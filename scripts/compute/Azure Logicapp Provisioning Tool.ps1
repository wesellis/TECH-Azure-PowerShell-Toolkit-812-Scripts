#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Logicapp Provisioning Tool

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
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
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
Write-Output "Provisioning Logic App: $AppName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
if ($PlanName) {
    Write-Output "App Service Plan: $PlanName"
$Plan = Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $PlanName -ErrorAction SilentlyContinue
    if (-not $Plan) {
        Write-Output "Creating App Service Plan for Logic App..."
$params = @{
            ResourceGroupName = $ResourceGroupName
            Tier = "WorkflowStandard"
            WorkerSize = "WS1"  Write-Output "App Service Plan created: $($Plan.Name)" "INFO" } else { Write-Output "Using existing App Service Plan: $($Plan.Name)" }"
            Location = $Location
            ErrorAction = "Stop"
            Name = $PlanName
        }
    [string]$Plan @params
}
Write-Output " `nCreating Logic App..."
if ($PlanName) {
$params = @{
       AppServicePlan = $PlanName
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $AppName
       Location = $Location
   }
   ; @params
} else {
$params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $ResourceGroupName
       Name = $AppName
       Location = $Location
   }
   ; @params
}
if ($Tags.Count -gt 0) {
    Write-Output " `nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Output "  $($Tag.Key): $($Tag.Value)"
    }
    Set-AzResource -ResourceId $LogicApp.Id -Tag $Tags -Force
}
Write-Output " `nLogic App $AppName provisioned successfully"
Write-Output "Logic App ID: $($LogicApp.Id)"
Write-Output "State: $($LogicApp.State)"
Write-Output "Definition: $($LogicApp.Definition)"
if ($PlanName) {
    Write-Output "Plan Type: Standard (Dedicated)"
    Write-Output "Plan Name: $PlanName"
} else {
    Write-Output "Plan Type: Consumption"
}
Write-Output " `nLogic App Designer:"
Write-Output "Portal URL: https://portal.azure.com/#@/resource$($LogicApp.Id)/designer"
Write-Output " `nNext Steps:"
Write-Output " 1. Open Logic App Designer in Azure Portal"
Write-Output " 2. Add triggers (HTTP, Schedule, Event Grid, etc.)"
Write-Output " 3. Add actions (Send email, call APIs, data operations)"
Write-Output " 4. Configure connectors for external services"
Write-Output " 5. Test and enable the Logic App workflow"
Write-Output " `nCommon Triggers:"
Write-Output "   HTTP Request (webhook)"
Write-Output "   Recurrence (scheduled)"
Write-Output "   Event Grid events"
Write-Output "   Service Bus messages"
Write-Output "   File system changes"
Write-Output " `nCommon Actions:"
Write-Output "   HTTP requests to APIs"
Write-Output "   Send emails (Office 365, Outlook)"
Write-Output "   Database operations (SQL, Cosmos DB)"
Write-Output "   File operations (SharePoint, OneDrive)"
Write-Output "   Conditional logic and loops"
Write-Output " `nLogic App provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
