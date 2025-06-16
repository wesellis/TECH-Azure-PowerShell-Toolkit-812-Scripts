# Enhanced Azure Environment Cloner
param (
    [Parameter(Mandatory=$true)][string]$SourceResourceGroup,
    [Parameter(Mandatory=$true)][string]$TargetResourceGroup,
    [Parameter(Mandatory=$false)][string]$TargetLocation,
    [Parameter(Mandatory=$false)][string[]]$ExcludeResourceTypes = @(),
    [Parameter(Mandatory=$false)][hashtable]$TagOverrides = @{},
    [Parameter(Mandatory=$false)][string]$NamingConvention = "{OriginalName}",
    [Parameter(Mandatory=$false)][switch]$IncludeSecrets,
    [Parameter(Mandatory=$false)][switch]$WhatIf,
    [Parameter(Mandatory=$false)][switch]$Force
)

$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".." -AdditionalChildPath ".." -AdditionalChildPath "modules" -AdditionalChildPath "AzureAutomationCommon"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

Show-Banner -ScriptName "Azure Environment Cloner" -Description "Clone entire Azure environments with intelligent mapping"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection required" }
    
    Write-ProgressStep -StepNumber 1 -TotalSteps 8 -StepName "Validation" -Status "Validating source environment..."
    
    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroup -ErrorAction Stop
    Write-Log "✓ Source RG found: $($sourceRG.ResourceGroupName) in $($sourceRG.Location)" -Level SUCCESS
    
    # Get target location (default to source location)
    $targetLoc = $TargetLocation ?? $sourceRG.Location
    
    Write-ProgressStep -StepNumber 2 -TotalSteps 8 -StepName "Discovery" -Status "Analyzing source resources..."
    
    $sourceResources = Get-AzResource -ResourceGroupName $SourceResourceGroup
    $filteredResources = $sourceResources | Where-Object { $_.ResourceType -notin $ExcludeResourceTypes }
    
    Write-Log "Found $($sourceResources.Count) total resources, $($filteredResources.Count) will be cloned" -Level INFO
    
    Write-ProgressStep -StepNumber 3 -TotalSteps 8 -StepName "Dependencies" -Status "Mapping dependencies..."
    
    # Map resource dependencies
    $dependencyMap = @{}
    
    foreach ($resource in $filteredResources) {
        $newName = $NamingConvention.Replace("{OriginalName}", $resource.Name)
        $dependencyMap[$resource.ResourceId] = @{
            OriginalResource = $resource
            NewName = $newName
            Dependencies = @()
            Created = $false
        }
    }
    
    Write-ProgressStep -StepNumber 4 -TotalSteps 8 -StepName "Target Setup" -Status "Creating target resource group..."
    
    if ($WhatIf) {
        Write-Log "[WHAT-IF] Would create resource group: $TargetResourceGroup in $targetLoc" -Level INFO
    } else {
        $targetRG = Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction SilentlyContinue
        if (-not $targetRG) {
            $targetRG = New-AzResourceGroup -Name $TargetResourceGroup -Location $targetLoc
            Write-Log "✓ Created target resource group: $($targetRG.ResourceGroupName)" -Level SUCCESS
        }
    }
    
    Write-ProgressStep -StepNumber 5 -TotalSteps 8 -StepName "ARM Templates" -Status "Generating deployment templates..."
    
    # Export ARM templates for each resource type
    $resourceTypes = $filteredResources | Group-Object ResourceType
    $templates = @{}
    
    foreach ($resourceType in $resourceTypes) {
        if ($WhatIf) {
            Write-Log "[WHAT-IF] Would export template for $($resourceType.Name)" -Level INFO
        } else {
            try {
                $templatePath = "temp_template_$($resourceType.Name.Replace('/', '_')).json"
                $resourceIds = $resourceType.Group.ResourceId
                
                # Export ARM template
                Export-AzResourceGroup -ResourceGroupName $SourceResourceGroup -Resource $resourceIds -Path $templatePath -Force
                $templates[$resourceType.Name] = $templatePath
                
                Write-Log "✓ Exported template for $($resourceType.Name)" -Level SUCCESS
            } catch {
                Write-Log "⚠ Failed to export template for $($resourceType.Name): $($_.Exception.Message)" -Level WARN
            }
        }
    }
    
    Write-ProgressStep -StepNumber 6 -TotalSteps 8 -StepName "Secrets" -Status "Handling secrets and configurations..."
    
    if ($IncludeSecrets) {
        # Handle Key Vault secrets
        $keyVaults = $filteredResources | Where-Object { $_.ResourceType -eq "Microsoft.KeyVault/vaults" }
        foreach ($kv in $keyVaults) {
            if ($WhatIf) {
                Write-Log "[WHAT-IF] Would copy secrets from Key Vault: $($kv.Name)" -Level INFO
            } else {
                Write-Log "Processing Key Vault secrets: $($kv.Name)" -Level INFO
                # Implementation would copy secrets here
            }
        }
    }
    
    Write-ProgressStep -StepNumber 7 -TotalSteps 8 -StepName "Deployment" -Status "Deploying cloned resources..."
    
    $deployedResources = @()
    $deploymentErrors = @()
    
    foreach ($template in $templates.GetEnumerator()) {
        if ($WhatIf) {
            Write-Log "[WHAT-IF] Would deploy template: $($template.Key)" -Level INFO
        } else {
            try {
                $deploymentName = "Clone-$($template.Key.Replace('/', '-'))-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                
                $deployment = Invoke-AzureOperation -Operation {
                    New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroup -TemplateFile $template.Value -Name $deploymentName
                } -OperationName "Deploy $($template.Key)"
                
                $deployedResources += $deployment
                Write-Log "✓ Deployed: $($template.Key)" -Level SUCCESS
                
            } catch {
                $deploymentErrors += "Failed to deploy $($template.Key): $($_.Exception.Message)"
                Write-Log "✗ Failed to deploy $($template.Key): $($_.Exception.Message)" -Level ERROR
            }
        }
    }
    
    Write-ProgressStep -StepNumber 8 -TotalSteps 8 -StepName "Post-Processing" -Status "Applying tags and final configurations..."
    
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
                Write-Log "⚠ Failed to apply tags to $($resource.Name): $($_.Exception.Message)" -Level WARN
            }
        }
    }
    
    # Cleanup temporary files
    $templates.Values | ForEach-Object {
        if (Test-Path $_) { Remove-Item $_ -Force }
    }
    
    Write-Progress -Activity "Environment Cloning" -Completed
    
    if ($WhatIf) {
        Write-Log "[WHAT-IF] Environment cloning simulation completed" -Level INFO
    } else {
        Write-Log "Environment cloning completed!" -Level SUCCESS
        Write-Log "  Source: $SourceResourceGroup ($($sourceResources.Count) resources)" -Level INFO
        Write-Log "  Target: $TargetResourceGroup ($($deployedResources.Count) deployed)" -Level INFO
        Write-Log "  Errors: $($deploymentErrors.Count)" -Level $(if ($deploymentErrors.Count -gt 0) { "WARN" } else { "SUCCESS" })
        
        if ($deploymentErrors.Count -gt 0) {
            Write-Log "Deployment errors:" -Level WARN
            $deploymentErrors | ForEach-Object { Write-Log "  $_" -Level ERROR }
        }
    }
    
} catch {
    Write-Progress -Activity "Environment Cloning" -Completed
    Write-Log "Environment cloning failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    throw
}
