#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Environment Cloner

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SourceResourceGroup,
    [Parameter(Mandatory)][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TargetResourceGroup,
    [Parameter()][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TargetLocation,
    [Parameter()][string[]]$ExcludeResourceTypes = @(),
    [Parameter()][hashtable]$TagOverrides = @{},
    [Parameter()][string]$NamingConvention = " {OriginalName}" ,
    [Parameter()][switch]$IncludeSecrets,
    [Parameter()][switch]$WhatIf,
    [Parameter()][switch]$Force
)
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath " .." -AdditionalChildPath " .." -AdditionalChildPath " modules" -AdditionalChildPath "AzureAutomationCommon"
if (Test-Path $modulePath) { Write-Host "Azure Script Started" -ForegroundColor GreenName "Azure Environment Cloner" -Description "Clone entire Azure environments with intelligent mapping"
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    # Progress stepNumber 1 -TotalSteps 8 -StepName "Validation" -Status "Validating source environment..."
    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroup -ErrorAction Stop

    # Get target location (default to source location)
    $targetLoc = $TargetLocation ?? $sourceRG.Location
    # Progress stepNumber 2 -TotalSteps 8 -StepName "Discovery" -Status "Analyzing source resources..."
    $sourceResources = Get-AzResource -ResourceGroupName $SourceResourceGroup
    $filteredResources = $sourceResources | Where-Object { $_.ResourceType -notin $ExcludeResourceTypes }

    # Progress stepNumber 3 -TotalSteps 8 -StepName "Dependencies" -Status "Mapping dependencies..."
    # Map resource dependencies
    $dependencyMap = @{}
    foreach ($resource in $filteredResources) {
        $newName = $NamingConvention.Replace(" {OriginalName}" , $resource.Name)
        $dependencyMap[$resource.ResourceId] = @{
            OriginalResource = $resource
            NewName = $newName
            Dependencies = @()
            Created = $false
        }
    }
    # Progress stepNumber 4 -TotalSteps 8 -StepName "Target Setup" -Status "Creating target resource group..."
    if ($WhatIf) {

    } else {
        $targetRG = Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction SilentlyContinue
        if (-not $targetRG) {
            $targetRG = New-AzResourceGroup -Name $TargetResourceGroup -Location $targetLoc

        }
    }
    # Progress stepNumber 5 -TotalSteps 8 -StepName "ARM Templates" -Status "Generating deployment templates..."
    # Export ARM templates for each resource type
    $resourceTypes = $filteredResources | Group-Object ResourceType
    $templates = @{}
    foreach ($resourceType in $resourceTypes) {
        if ($WhatIf) {

        } else {
            try {
                $templatePath = " temp_template_$($resourceType.Name.Replace('/', '_')).json"
                $resourceIds = $resourceType.Group.ResourceId
                # Export ARM template
                Export-AzResourceGroup -ResourceGroupName $SourceResourceGroup -Resource $resourceIds -Path $templatePath -Force
                $templates[$resourceType.Name] = $templatePath

            } catch {

            }
        }
    }
    # Progress stepNumber 6 -TotalSteps 8 -StepName "Secrets" -Status "Handling secrets and configurations..."
    if ($IncludeSecrets) {
        # Handle Key Vault secrets
        $keyVaults = $filteredResources | Where-Object { $_.ResourceType -eq "Microsoft.KeyVault/vaults" }
        foreach ($kv in $keyVaults) {
            if ($WhatIf) {

            } else {

                # Implementation would copy secrets here
            }
        }
    }
    # Progress stepNumber 7 -TotalSteps 8 -StepName "Deployment" -Status "Deploying cloned resources..."
    $deployedResources = @()
    $deploymentErrors = @()
    foreach ($template in $templates.GetEnumerator()) {
        if ($WhatIf) {

        } else {
            try {
                $deploymentName = "Clone-$($template.Key.Replace('/', '-'))-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                $deployment = Invoke-AzureOperation -Operation {
                    New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroup -TemplateFile $template.Value -Name $deploymentName
                } -OperationName "Deploy $($template.Key)"
                $deployedResources = $deployedResources + $deployment

            } catch {
                $deploymentErrors = $deploymentErrors + "Failed to deploy $($template.Key): $($_.Exception.Message)"

            }
        }
    }
    # Progress stepNumber 8 -TotalSteps 8 -StepName "Post-Processing" -Status "Applying tags and final configurations..."
    # Apply tag overrides
    if ($TagOverrides.Count -gt 0 -and -not $WhatIf) {
$newResources = Get-AzResource -ResourceGroupName $TargetResourceGroup
        foreach ($resource in $newResources) {
            try {
$currentTags = $resource.Tags ?? @{}
                foreach ($tag in $TagOverrides.GetEnumerator()) {
                    $currentTags[$tag.Key] = $tag.Value
                }
                Set-AzResource -ResourceId $resource.ResourceId -Tag $currentTags -Force
            } catch {

            }
        }
    }
    # Cleanup temporary files
    $templates.Values | ForEach-Object {
        if (Test-Path $_) { Remove-Item -ErrorAction Stop $ -Force_ -Force }
    }
        if ($WhatIf) {

    } else {

        Write-Log "  Errors: $($deploymentErrors.Count)" -Level $(if ($deploymentErrors.Count -gt 0) { "WARN" } else { "SUCCESS" })
        if ($deploymentErrors.Count -gt 0) {

            $deploymentErrors | ForEach-Object {
        }
    }
} catch {
        throw
}\n

