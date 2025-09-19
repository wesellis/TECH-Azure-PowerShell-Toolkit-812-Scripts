#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Logicapp Provisioning Tool

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
    We Enhanced Azure Logicapp Provisioning Tool

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAppName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPlanName,
    [string]$WEPlanSku = " WS1" ,
    [hashtable]$WETags = @{}
)

#region Functions

Write-WELog " Provisioning Logic App: $WEAppName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"


if ($WEPlanName) {
    Write-WELog " App Service Plan: $WEPlanName" " INFO"
    
    # Check if plan exists
    $WEPlan = Get-AzAppServicePlan -ResourceGroupName $WEResourceGroupName -Name $WEPlanName -ErrorAction SilentlyContinue
    
    if (-not $WEPlan) {
        Write-WELog " Creating App Service Plan for Logic App..." " INFO"
        $params = @{
            ResourceGroupName = $WEResourceGroupName
            Tier = " WorkflowStandard"
            WorkerSize = " WS1"  Write-WELog " App Service Plan created: $($WEPlan.Name)" " INFO" } else { Write-WELog " Using existing App Service Plan: $($WEPlan.Name)" " INFO" }"
            Location = $WELocation
            ErrorAction = "Stop"
            Name = $WEPlanName
        }
        $WEPlan @params
}


Write-WELog " `nCreating Logic App..." " INFO"
if ($WEPlanName) {
    # Logic App with dedicated plan (Standard tier)
   $params = @{
       AppServicePlan = $WEPlanName
       ErrorAction = "Stop"
       ResourceGroupName = $WEResourceGroupName
       Name = $WEAppName
       Location = $WELocation
   }
   ; @params
} else {
    # Consumption-based Logic App
   $params = @{
       ErrorAction = "Stop"
       ResourceGroupName = $WEResourceGroupName
       Name = $WEAppName
       Location = $WELocation
   }
   ; @params
}


if ($WETags.Count -gt 0) {
    Write-WELog " `nApplying tags:" " INFO"
    foreach ($WETag in $WETags.GetEnumerator()) {
        Write-WELog "  $($WETag.Key): $($WETag.Value)" " INFO"
    }
    Set-AzResource -ResourceId $WELogicApp.Id -Tag $WETags -Force
}

Write-WELog " `nLogic App $WEAppName provisioned successfully" " INFO"
Write-WELog " Logic App ID: $($WELogicApp.Id)" " INFO"
Write-WELog " State: $($WELogicApp.State)" " INFO"
Write-WELog " Definition: $($WELogicApp.Definition)" " INFO"

if ($WEPlanName) {
    Write-WELog " Plan Type: Standard (Dedicated)" " INFO"
    Write-WELog " Plan Name: $WEPlanName" " INFO"
} else {
    Write-WELog " Plan Type: Consumption" " INFO"
}

Write-WELog " `nLogic App Designer:" " INFO"
Write-WELog " Portal URL: https://portal.azure.com/#@/resource$($WELogicApp.Id)/designer" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Open Logic App Designer in Azure Portal" " INFO"
Write-WELog " 2. Add triggers (HTTP, Schedule, Event Grid, etc.)" " INFO"
Write-WELog " 3. Add actions (Send email, call APIs, data operations)" " INFO"
Write-WELog " 4. Configure connectors for external services" " INFO"
Write-WELog " 5. Test and enable the Logic App workflow" " INFO"

Write-WELog " `nCommon Triggers:" " INFO"
Write-WELog "  • HTTP Request (webhook)" " INFO"
Write-WELog "  • Recurrence (scheduled)" " INFO"
Write-WELog "  • Event Grid events" " INFO"
Write-WELog "  • Service Bus messages" " INFO"
Write-WELog "  • File system changes" " INFO"

Write-WELog " `nCommon Actions:" " INFO"
Write-WELog "  • HTTP requests to APIs" " INFO"
Write-WELog "  • Send emails (Office 365, Outlook)" " INFO"
Write-WELog "  • Database operations (SQL, Cosmos DB)" " INFO"
Write-WELog "  • File operations (SharePoint, OneDrive)" " INFO"
Write-WELog "  • Conditional logic and loops" " INFO"

Write-WELog " `nLogic App provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
