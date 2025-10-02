#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Resource Move Validator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $SourceResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $TargetResourceGroupName,
    [Parameter()]
    [string[]]$ResourceNames,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $TargetSubscriptionId,
    [Parameter()]
    [switch]$ValidateOnly
)
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $SourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    $resources = if ($ResourceNames) {
    $ResourceNames | ForEach-Object { Get-AzResource -ResourceGroupName $SourceResourceGroupName -Name $_ }
    } else {
        Get-AzResource -ResourceGroupName $SourceResourceGroupName
    }
    Write-Output "Validating move for $($resources.Count) resources..." # Color: $2
    $TargetResourceId = "/subscriptions/$(if($TargetSubscriptionId){$TargetSubscriptionId}else{(Get-AzContext).Subscription.Id})/resourceGroups/$TargetResourceGroupName"
    $validation = Invoke-AzResourceAction -ResourceId $SourceRG.ResourceId -Action " validateMoveResources" -Parameters @{
        resources = $resources.ResourceId
        targetResourceGroup = $TargetResourceId
    } -Force
    if ($validation) {
        Write-Output "All resources can be moved successfully!" # Color: $2
    } else {
        Write-Output "Some resources cannot be moved. Check Azure portal for details." # Color: $2
    }
} catch { throw`n}
