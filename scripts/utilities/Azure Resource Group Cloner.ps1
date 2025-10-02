#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Resource Group Cloner

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
    [ValidateNotNullOrEmpty()]
    $TargetLocation,
    [Parameter()]
    [switch]$ExportOnly,
    [Parameter()]
    $ExportPath = " .\rg-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)
Write-Output "Script Started" # Color: $2
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $SourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    if (-not $TargetLocation) { $TargetLocation = $SourceRG.Location }
    $null = Export-AzResourceGroup -ResourceGroupName $SourceResourceGroupName -Path $ExportPath

    if (-not $ExportOnly) {
    $ResourcegroupSplat = @{
    Name = $TargetResourceGroupName
    Location = $TargetLocation
    Tag = $SourceRG.Tags
}
New-AzResourceGroup @resourcegroupSplat
    $deployment = New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroupName -TemplateFile $ExportPath
        if ($deployment.ProvisioningState -eq "Succeeded" ) {

        } else {

        }
    }
} catch { throw`n}
