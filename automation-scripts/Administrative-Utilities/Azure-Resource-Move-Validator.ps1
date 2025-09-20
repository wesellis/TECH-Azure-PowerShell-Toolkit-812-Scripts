<#
.SYNOPSIS
    Validate resource moves

.DESCRIPTION
    Validate resource moves
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Resource Move Validator
# Validates if resources can be moved between resource groups or subscriptions
param(
    [Parameter(Mandatory)]
    [string]$SourceResourceGroupName,
    [Parameter(Mandatory)]
    [string]$TargetResourceGroupName,
    [Parameter()]
    [string[]]$ResourceNames,
    [Parameter()]
    [string]$TargetSubscriptionId,
    [Parameter()]
    [switch]$ValidateOnly
)
try {
    if (-not (Get-AzContext)) { throw "Not connected to Azure" }
    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    $resources = if ($ResourceNames) {
        $ResourceNames | ForEach-Object { Get-AzResource -ResourceGroupName $SourceResourceGroupName -Name $_ }
    } else {
        Get-AzResource -ResourceGroupName $SourceResourceGroupName
    }
    Write-Host "Validating move for $($resources.Count) resources..."
    $targetResourceId = "/subscriptions/$(if($TargetSubscriptionId){$TargetSubscriptionId}else{(Get-AzContext).Subscription.Id})/resourceGroups/$TargetResourceGroupName"
    $validation = Invoke-AzResourceAction -ResourceId $sourceRG.ResourceId -Action "validateMoveResources" -Parameters @{
        resources = $resources.ResourceId
        targetResourceGroup = $targetResourceId
    } -Force
    if ($validation) {
        Write-Host "All resources can be moved successfully!"
    } else {
        Write-Host "Some resources cannot be moved. Check Azure portal for details."
    }
} catch { throw }

