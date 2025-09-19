#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Create Resourcegroupassignment

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
    We Enhanced Create Resourcegroupassignment

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
    Use this script to create a resourceGroup and assign a principal access to that group


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string][Parameter(mandatory=$true)] $WEResourceGroupName,
    [string][Parameter(mandatory=$true)] $WELocation,
    [string][Parameter(mandatory=$true)] $appId
)

#region Functions


if ($null -eq (Get-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -ErrorAction SilentlyContinue)) {
   ;  $rg = New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -Force
}


if ($null -eq (Get-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Verbose -ErrorAction SilentlyContinue)) {
    Start-Sleep 10
}

; 
$params = @{
    ApplicationId = $appId).Id
    RoleDefinitionName = "Owner"
    ObjectId = $(Get-AzADServicePrincipal
    Scope = $rg.ResourceId
}
$ra @params





$ra | out-string

& " $WEPSScriptRoot\Wait-ForResource.ps1" -resourceId " $($ra.RoleAssignmentId)" -apiVersion " 2022-04-01"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
