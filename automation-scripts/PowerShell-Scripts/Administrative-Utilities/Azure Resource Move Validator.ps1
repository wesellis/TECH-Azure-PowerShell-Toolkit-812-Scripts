<#
.SYNOPSIS
    We Enhanced Azure Resource Move Validator

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESourceResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETargetResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string[]]$WEResourceNames,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETargetSubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEValidateOnly
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName " Azure Resource Move Validator" -Version " 1.0" -Description " Validate resource move operations"

try {
    if (-not (Test-AzureConnection)) { throw " Azure connection validation failed" }

    $sourceRG = Get-AzResourceGroup -Name $WESourceResourceGroupName
    $resources = if ($WEResourceNames) { 
        $WEResourceNames | ForEach-Object { Get-AzResource -ResourceGroupName $WESourceResourceGroupName -Name $_ }
    } else { 
        Get-AzResource -ResourceGroupName $WESourceResourceGroupName 
    }

    Write-WELog " Validating move for $($resources.Count) resources..." " INFO" -ForegroundColor Cyan
    
    $targetResourceId = " /subscriptions/$(if($WETargetSubscriptionId){$WETargetSubscriptionId}else{(Get-AzContext).Subscription.Id})/resourceGroups/$WETargetResourceGroupName"
    
   ;  $validation = Invoke-AzResourceAction -ResourceId $sourceRG.ResourceId -Action " validateMoveResources" -Parameters @{
        resources = $resources.ResourceId
        targetResourceGroup = $targetResourceId
    } -Force

    if ($validation) {
        Write-WELog " ✅ All resources can be moved successfully!" " INFO" -ForegroundColor Green
    } else {
        Write-WELog " ❌ Some resources cannot be moved. Check Azure portal for details." " INFO" -ForegroundColor Red
    }

} catch {
    Write-Log " ❌ Resource move validation failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================