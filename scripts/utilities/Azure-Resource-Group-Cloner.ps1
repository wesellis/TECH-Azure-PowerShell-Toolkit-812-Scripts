#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage resource groups

.DESCRIPTION
    Manage resource groups


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    $SourceResourceGroupName,
    [Parameter(Mandatory)]
    $TargetResourceGroupName,
    [Parameter()]
    $TargetLocation,
    [Parameter()]
    [switch]$ExportOnly,
    [Parameter()]
    $ExportPath = ".\rg-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
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
        if ($deployment.ProvisioningState -eq "Succeeded") {
            Write-Output "Deployment completed successfully" # Color: $2
        } else {
            Write-Output "Deployment failed" # Color: $2
        }
    }
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
