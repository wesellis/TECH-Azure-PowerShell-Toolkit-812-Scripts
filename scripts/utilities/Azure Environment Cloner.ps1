#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Environment Cloner

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)][Parameter()]
    [ValidateNotNullOrEmpty()]
    $SourceResourceGroup,
    [Parameter(Mandatory)][Parameter()]
    [ValidateNotNullOrEmpty()]
    $TargetResourceGroup,
    [Parameter()][Parameter()]
    [ValidateNotNullOrEmpty()]
    $TargetLocation,
    [Parameter()][string[]]$ExcludeResourceTypes = @(),
    [Parameter()][hashtable]$TagOverrides = @{},
    [Parameter()]$NamingConvention = " {OriginalName}" ,
    [Parameter()][switch]$IncludeSecrets,
    [Parameter()][switch]$WhatIf,
    [Parameter()][switch]$Force
)
    $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath " .." -AdditionalChildPath " .." -AdditionalChildPath " modules" -AdditionalChildPath "AzureAutomationCommon"
if (Test-Path $ModulePath) { Write-Output "Azure Script Started" # Color: $2 "Azure Environment Cloner" -Description "Clone entire Azure environments with intelligent mapping"
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $SourceRG = Get-AzResourceGroup -Name $SourceResourceGroup -ErrorAction Stop
    $TargetLoc = $TargetLocation ?? $SourceRG.Location
    $SourceResources = Get-AzResource -ResourceGroupName $SourceResourceGroup
    $FilteredResources = $SourceResources | Where-Object { $_.ResourceType -notin $ExcludeResourceTypes }
    $DependencyMap = @{}
    foreach ($resource in $FilteredResources) {
    $NewName = $NamingConvention.Replace(" {OriginalName}" , $resource.Name)
    $DependencyMap[$resource.ResourceId] = @{
            OriginalResource = $resource
            NewName = $NewName
            Dependencies = @()
            Created = $false
        }
    }
    if ($WhatIf) {

    } else {
    $TargetRG = Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction SilentlyContinue
        if (-not $TargetRG) {
    $TargetRG = New-AzResourceGroup -Name $TargetResourceGroup -Location $TargetLoc

        }
    }
    $ResourceTypes = $FilteredResources | Group-Object ResourceType
    $templates = @{}
    foreach ($ResourceType in $ResourceTypes) {
        if ($WhatIf) {

        } else {
            try {
    $TemplatePath = " temp_template_$($ResourceType.Name.Replace('/', '_')).json"
    $ResourceIds = $ResourceType.Group.ResourceId
                Export-AzResourceGroup -ResourceGroupName $SourceResourceGroup -Resource $ResourceIds -Path $TemplatePath -Force
    $templates[$ResourceType.Name] = $TemplatePath

            } catch {

            }
        }
    }
    if ($IncludeSecrets) {
    $KeyVaults = $FilteredResources | Where-Object { $_.ResourceType -eq "Microsoft.KeyVault/vaults" }
        foreach ($kv in $KeyVaults) {
            if ($WhatIf) {

            } else {

            }
        }
    }
    $DeployedResources = @()
    $DeploymentErrors = @()
    foreach ($template in $templates.GetEnumerator()) {
        if ($WhatIf) {

        } else {
            try {
    $DeploymentName = "Clone-$($template.Key.Replace('/', '-'))-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $deployment = Invoke-AzureOperation -Operation {
                    New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroup -TemplateFile $template.Value -Name $DeploymentName
                } -OperationName "Deploy $($template.Key)"
    $DeployedResources = $DeployedResources + $deployment

            } catch {
    $DeploymentErrors = $DeploymentErrors + "Failed to deploy $($template.Key): $($_.Exception.Message)"

            }
        }
    }
    if ($TagOverrides.Count -gt 0 -and -not $WhatIf) {
    $NewResources = Get-AzResource -ResourceGroupName $TargetResourceGroup
        foreach ($resource in $NewResources) {
            try {
    $CurrentTags = $resource.Tags ?? @{}
                foreach ($tag in $TagOverrides.GetEnumerator()) {
    $CurrentTags[$tag.Key] = $tag.Value
                }
                Set-AzResource -ResourceId $resource.ResourceId -Tag $CurrentTags -Force
            } catch {

            }
        }
    }
    $templates.Values | ForEach-Object {
        if (Test-Path $_) { Remove-Item -ErrorAction Stop $ -Force_ -Force }
    }
        if ($WhatIf) {

    } else {

        Write-Log "  Errors: $($DeploymentErrors.Count)" -Level $(if ($DeploymentErrors.Count -gt 0) { "WARN" } else { "SUCCESS" })
        if ($DeploymentErrors.Count -gt 0) {
    $DeploymentErrors | ForEach-Object {
        }
    }
} catch {
        throw`n}
