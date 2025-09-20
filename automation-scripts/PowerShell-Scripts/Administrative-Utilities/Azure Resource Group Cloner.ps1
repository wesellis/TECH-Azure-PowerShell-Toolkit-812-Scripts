<#
.SYNOPSIS
    Azure Resource Group Cloner

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
    [ValidateNotNullOrEmpty()]
    [string]$TargetLocation,
    [Parameter()]
    [switch]$ExportOnly,
    [Parameter()]
    [string]$ExportPath = " .\rg-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    if (-not $TargetLocation) { $TargetLocation = $sourceRG.Location }

    $null = Export-AzResourceGroup -ResourceGroupName $SourceResourceGroupName -Path $ExportPath

    if (-not $ExportOnly) {

$null = New-AzResourceGroup -Name $TargetResourceGroupName -Location $TargetLocation -Tag $sourceRG.Tags

$deployment = New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroupName -TemplateFile $ExportPath
        if ($deployment.ProvisioningState -eq "Succeeded" ) {

        } else {

        }
    }
} catch { throw }\n