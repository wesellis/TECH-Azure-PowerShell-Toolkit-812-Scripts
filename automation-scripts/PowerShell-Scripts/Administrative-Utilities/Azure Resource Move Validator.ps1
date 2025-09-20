<#
.SYNOPSIS
    Azure Resource Move Validator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetResourceGroupName,
    [Parameter()]
    [string[]]$ResourceNames,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TargetSubscriptionId,
    [Parameter()]
    [switch]$ValidateOnly
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    $resources = if ($ResourceNames) {
        $ResourceNames | ForEach-Object { Get-AzResource -ResourceGroupName $SourceResourceGroupName -Name $_ }
    } else {
        Get-AzResource -ResourceGroupName $SourceResourceGroupName
    }
    Write-Host "Validating move for $($resources.Count) resources..." -ForegroundColor Cyan
$targetResourceId = " /subscriptions/$(if($TargetSubscriptionId){$TargetSubscriptionId}else{(Get-AzContext).Subscription.Id})/resourceGroups/$TargetResourceGroupName"
$validation = Invoke-AzResourceAction -ResourceId $sourceRG.ResourceId -Action " validateMoveResources" -Parameters @{
        resources = $resources.ResourceId
        targetResourceGroup = $targetResourceId
    } -Force
    if ($validation) {
        Write-Host "All resources can be moved successfully!" -ForegroundColor Green
    } else {
        Write-Host "Some resources cannot be moved. Check Azure portal for details." -ForegroundColor Red
    }
} catch { throw }\n