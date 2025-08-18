<#
.SYNOPSIS
    We Enhanced Killall Azresourcegroup

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

<# 

This script recursively calls the Kill-AzResourceGroup.ps1 script to remove any resourceGroups that failed deletion previous.
Some resource cannot be deleted until hours after they are created

$x = Get-AzResourceGroup | Select ResourceGroupName
foreach($rg in $x)
try {
    # Main script execution
{
$o = "'" + $rg.ResourceGroupName + " ',"
Write-Host $o
}

$rgs = @( ... )



[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] $WETTKPath = " .",
    [long] $WESleepTime = 600,
    [string] $WEResourceGroupName, # if a single name is passed, use it
    [array] $WEResourceGroupNames, # if an array is passed, use it
    [string] $WEPattern = " azdo-*" # else use the default pattern
)

$azdoResourceGroups = @()


Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings " true"

if ($WEResourceGroupNames.count -ne 0) {
    foreach ($rgName in $WEResourceGroupNames) {
        $azdoResourceGroups = $azdoResourceGroups + @{" ResourceGroupName" = $rgName }
    }
    $WESecondErrorAction = " SilentlyContinue"
}
elseif (![string]::IsNullOrWhiteSpace($WEResourceGroupName)) {
    $azdoResourceGroups = $azdoResourceGroups + @{" ResourceGroupName" = $WEResourceGroupName }
    $WESecondErrorAction = " Continue"
}
else {
    #if a RG name was not passed remove all with the CI pattern
    $azdoResourceGroups = get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like $WEPattern }
    $WESecondErrorAction = " SilentlyContinue"
}

foreach ($rg in $azdoResourceGroups) {
    
    Write-WELog " ***********************" " INFO"
    Write-WELog "  $(Get-Date)" " INFO"
    Write-WELog " ***********************" " INFO"

    # remove the resource group
   ;  $bypassTag = $(Get-AzTag -ResourceId $rg.ResourceId).properties.tagsproperty.bypass
    # skip resourece groups that have been tagged due to some bug and can't be deleted
    # this enables getting to the other resourceGroups instead of timing out
    if (!$bypassTag) {
        Write-WELog " First attempt on ResourceGroup: $($rg.ResourceGroupName)" " INFO"
        Write-WELog " --------------------------------------------------------------------------" " INFO"
        & $WETTKPath/ci-scripts/Kill-AzResourceGroup.ps1 -ResourceGroupName ($rg.ResourceGroupName) -Verbose -ErrorAction SilentlyContinue

        # if the resource group still exists after the first attempt, try again after a few minutes
        Write-WELog " Checking for ResourceGroup: $($rg.ResourceGroupName)" " INFO"
        if ($null -ne (Get-AzResourceGroup -Name $rg.ResourceGroupName -verbose -ErrorAction SilentlyContinue)) {
            Write-WELog " Found the resource group - sleeping..." " INFO" 
            Start-Sleep $WESleepTime
            Write-WELog " Second Attempt on ResourceGroup: $($rg.ResourceGroupName)" " INFO"
            Write-WELog " --------------------------------------------------------------------------" " INFO"
            & $WETTKPath/ci-scripts/Kill-AzResourceGroup.ps1 -ResourceGroupName ($rg.ResourceGroupName) -verbose -ErrorAction $WESecondErrorAction
            if ($null -ne (Get-AzResourceGroup -Name $rg.ResourceGroupName -verbose -ErrorAction SilentlyContinue)) {
                Write-WELog " ==================================================================" " INFO"
                Write-WELog " Failed to delete: $($rg.ResourceGroupName) " " INFO"
                Write-WELog " ==================================================================" " INFO"
            }
        }
        else {
            Write-WELog " ResourceGroup Not found (delete success)" " INFO"
        }
    }
    else {
        # Write to the log that we skipped an RG due to the tag
        Write-WELog " `nSkipping $($rg.ResourceGroupName) due to bypass tag...`n" " INFO"
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
