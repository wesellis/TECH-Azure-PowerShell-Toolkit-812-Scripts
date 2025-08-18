# Azure Resource Move Validator
# Validates if resources can be moved between resource groups or subscriptions
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string[]]$ResourceNames,
    
    [Parameter(Mandatory=$false)]
    [string]$TargetSubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Resource Move Validator" -Version "1.0" -Description "Validate resource move operations"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection validation failed" }

    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    $resources = if ($ResourceNames) { 
        $ResourceNames | ForEach-Object { Get-AzResource -ResourceGroupName $SourceResourceGroupName -Name $_ }
    } else { 
        Get-AzResource -ResourceGroupName $SourceResourceGroupName 
    }

    Write-Information "Validating move for $($resources.Count) resources..."
    
    $targetResourceId = "/subscriptions/$(if($TargetSubscriptionId){$TargetSubscriptionId}else{(Get-AzContext).Subscription.Id})/resourceGroups/$TargetResourceGroupName"
    
    $validation = Invoke-AzResourceAction -ResourceId $sourceRG.ResourceId -Action "validateMoveResources" -Parameters @{
        resources = $resources.ResourceId
        targetResourceGroup = $targetResourceId
    } -Force

    if ($validation) {
        Write-Information "✅ All resources can be moved successfully!"
    } else {
        Write-Information "❌ Some resources cannot be moved. Check Azure portal for details."
    }

} catch {
    Write-Log "❌ Resource move validation failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
