<#
.SYNOPSIS
    We Enhanced Create Resourcegroupassignment

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
    Use this script to create a resourceGroup and assign a principal access to that group


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [string][Parameter(mandatory=$true)] $WEResourceGroupName,
    [string][Parameter(mandatory=$true)] $WELocation,
    [string][Parameter(mandatory=$true)] $appId
)


if ($null -eq (Get-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -ErrorAction SilentlyContinue)) {
    $rg = New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -Force
}


if ($null -eq (Get-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -ErrorAction SilentlyContinue)) {
    Start-Sleep 10
}

; 
$ra = New-AzRoleAssignment -ObjectId $(Get-AzADServicePrincipal -ApplicationId $appId).Id `
                           -RoleDefinitionName Owner `
                           -Scope $rg.ResourceId -Verbose





$ra | out-string

& "$WEPSScriptRoot\Wait-ForResource.ps1" -resourceId " $($ra.RoleAssignmentId)" -apiVersion " 2022-04-01"


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
