<#
.SYNOPSIS
    Create Resourcegroupassignment

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Use this script to create a resourceGroup and assign a principal access to that group
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string][Parameter(mandatory=$true)] $ResourceGroupName,
    [string][Parameter(mandatory=$true)] $Location,
    [string][Parameter(mandatory=$true)] $appId
)
if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -ErrorAction SilentlyContinue)) {
$rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -Force
}
if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -ErrorAction SilentlyContinue)) {
    Start-Sleep 10
}
$params = @{
    ApplicationId = $appId).Id
    RoleDefinitionName = "Owner"
    ObjectId = $(Get-AzADServicePrincipal
    Scope = $rg.ResourceId
}
$ra @params
$ra | out-string
& " $PSScriptRoot\Wait-ForResource.ps1" -resourceId " $($ra.RoleAssignmentId)" -apiVersion " 2022-04-01"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n