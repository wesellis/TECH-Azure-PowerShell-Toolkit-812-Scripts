#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Killall Azresourcegroup

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
This script recursively calls the Kill-AzResourceGroup.ps1 script to remove any resourceGroups that failed deletion previous.
Some resource cannot be deleted until hours after they are created
$x = Get-AzResourceGroup -ErrorAction Stop | Select ResourceGroupName
foreach($rg in $x)
try {
{
$o = "'" + $rg.ResourceGroupName + " ',"
Write-Output $o
}
    $rgs = @( ... )
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [string] $TTKPath = " ." ,
    [long] $SleepTime = 600,
    [string] $ResourceGroupName,
    [array] $ResourceGroupNames,
    [string] $Pattern = " azdo-*" # else use the default pattern
)
    $AzdoResourceGroups = @()
Set-Item -ErrorAction Stop Env:\SuppressAzurePowerShellBreakingChangeWarnings " true"
if ($ResourceGroupNames.count -ne 0) {
    foreach ($RgName in $ResourceGroupNames) {
    $AzdoResourceGroups = $AzdoResourceGroups + @{"ResourceGroupName" = $RgName }
    }
    $SecondErrorAction = "SilentlyContinue"
}
elseif (![string]::IsNullOrWhiteSpace($ResourceGroupName)) {
    $AzdoResourceGroups = $AzdoResourceGroups + @{"ResourceGroupName" = $ResourceGroupName }
    $SecondErrorAction = "Continue"
}
else {
    $AzdoResourceGroups = get-AzResourceGroup -ErrorAction Stop | Where-Object { $_.ResourceGroupName -like $Pattern }
    $SecondErrorAction = "SilentlyContinue"
}
foreach ($rg in $AzdoResourceGroups) {
    Write-Output " ***********************"
    Write-Output "  $(Get-Date)"
    Write-Output " ***********************"
    $BypassTag = $(Get-AzTag -ResourceId $rg.ResourceId).properties.tagsproperty.bypass
    if (!$BypassTag) {
        Write-Output "First attempt on ResourceGroup: $($rg.ResourceGroupName)"
        Write-Output " --------------------------------------------------------------------------"
        & $TTKPath/ci-scripts/Kill-AzResourceGroup.ps1 -ResourceGroupName ($rg.ResourceGroupName) -Verbose -ErrorAction SilentlyContinue
        Write-Output "Checking for ResourceGroup: $($rg.ResourceGroupName)"
        if ($null -ne (Get-AzResourceGroup -Name $rg.ResourceGroupName -verbose -ErrorAction SilentlyContinue)) {
            Write-Output "Found the resource group - sleeping..."
            Start-Sleep $SleepTime
            Write-Output "Second Attempt on ResourceGroup: $($rg.ResourceGroupName)"
            Write-Output " --------------------------------------------------------------------------"
            & $TTKPath/ci-scripts/Kill-AzResourceGroup.ps1 -ResourceGroupName ($rg.ResourceGroupName) -verbose -ErrorAction $SecondErrorAction
            if ($null -ne (Get-AzResourceGroup -Name $rg.ResourceGroupName -verbose -ErrorAction SilentlyContinue)) {
                Write-Output " =================================================================="
                Write-Output "Failed to delete: $($rg.ResourceGroupName) "
                Write-Output " =================================================================="
            }
        }
        else {
            Write-Output "ResourceGroup Not found (delete success)"
        }
    }
    else {
        Write-Output " `nSkipping $($rg.ResourceGroupName) due to bypass tag...`n"
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
