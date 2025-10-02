#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Validate resource moves

.DESCRIPTION
    Validate resource moves
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    $SourceResourceGroupName,
    [Parameter(Mandatory)]
    $TargetResourceGroupName,
    [Parameter()]
    [string[]]$ResourceNames,
    [Parameter()]
    $TargetSubscriptionId,
    [Parameter()]
    [switch]$ValidateOnly
)
try {
    if (-not (Get-AzContext)) { throw "Not connected to Azure" }
    $SourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    $resources = if ($ResourceNames) {
        $ResourceNames | ForEach-Object { Get-AzResource -ResourceGroupName $SourceResourceGroupName -Name $_ }
    } else {
        Get-AzResource -ResourceGroupName $SourceResourceGroupName
    }
    Write-Output "Validating move for $($resources.Count) resources..."
    $TargetResourceId = "/subscriptions/$(if($TargetSubscriptionId){$TargetSubscriptionId}else{(Get-AzContext).Subscription.Id})/resourceGroups/$TargetResourceGroupName"
    $validation = Invoke-AzResourceAction -ResourceId $SourceRG.ResourceId -Action "validateMoveResources" -Parameters @{
        resources = $resources.ResourceId
        targetResourceGroup = $TargetResourceId
    } -Force
    if ($validation) {
        Write-Output "All resources can be moved successfully!"
    } else {
        Write-Output "Some resources cannot be moved. Check Azure portal for details."
    }
} catch { throw`n}
