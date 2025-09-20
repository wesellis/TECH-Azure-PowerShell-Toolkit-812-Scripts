#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.KeyVault

<#
.SYNOPSIS
    Clones Azure resource groups and their resources to new environments

.DESCRIPTION
    This script creates a complete copy of an Azure resource group, including all
    resources, configurations, and optionally secrets. It uses ARM templates to
    ensure consistent deployments and maintains resource dependencies.
.PARAMETER SourceResourceGroup
    Name of the source resource group to clone
.PARAMETER TargetResourceGroup
    Name of the target resource group to create
.PARAMETER TargetLocation
    Azure region for the target resource group. Defaults to source location.
.PARAMETER ExcludeResourceTypes
    Array of resource types to exclude from cloning
.PARAMETER TagOverrides
    Hashtable of tags to apply or override on cloned resources
.PARAMETER NamingConvention
    Naming pattern for cloned resources. Use {OriginalName} as placeholder.
.PARAMETER IncludeSecrets
    Include Key Vault secrets in the cloning process
.PARAMETER WhatIf
    Preview operations without making changes
.PARAMETER Force
    Suppress confirmation prompts
    .\Azure-Environment-Cloner.ps1 -SourceResourceGroup "Prod-RG" -TargetResourceGroup "Test-RG"
    .\Azure-Environment-Cloner.ps1 -SourceResourceGroup "Prod-RG" -TargetResourceGroup "Dev-RG" -TargetLocation "West US 2" -WhatIf
    .\Azure-Environment-Cloner.ps1 -SourceResourceGroup "Prod-RG" -TargetResourceGroup "Staging-RG" -NamingConvention "stg-{OriginalName}" -IncludeSecrets
    Author: Wes Ellis (wes@wesellis.com)Prerequisites:
    - Az PowerShell modules
    - Contributor role on source and target subscriptions
    - Key Vault access if using -IncludeSecrets
.LINK
    https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory, HelpMessage="Source resource group name")]
    [ValidateNotNullOrEmpty()]
    [string]$SourceResourceGroup,
    [Parameter(Mandatory, HelpMessage="Target resource group name")]
    [ValidateNotNullOrEmpty()]
    [string]$TargetResourceGroup,
    [Parameter(HelpMessage="Target Azure region")]
    [ValidateNotNullOrEmpty()]
    [string]$TargetLocation,
    [Parameter(HelpMessage="Resource types to exclude from cloning")]
    [string[]]$ExcludeResourceTypes = @(),
    [Parameter(HelpMessage="Tags to apply to cloned resources")]
    [hashtable]$TagOverrides = @{},
    [Parameter(HelpMessage="Naming pattern for cloned resources")]
    [ValidateNotNullOrEmpty()]
    [string]$NamingConvention = '{OriginalName}',
    [Parameter(HelpMessage="Include Key Vault secrets in cloning")]
    [switch]$IncludeSecrets,
    [Parameter(HelpMessage="Preview operations without changes")]
    [switch]$WhatIf,
    [Parameter(HelpMessage="Suppress confirmation prompts")]
    [switch]$Force
)
#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Import required modules
try {
    Write-Verbose "Importing required Azure modules..."
            }
catch {
    Write-Error "Failed to import required modules. Please install Az PowerShell module: Install-Module Az"
    throw
}
#endregion
[OutputType([bool])]
 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}
if (-not (Get-AzContext)) { throw "Not connected to Azure" }
    [CmdletBinding()]
    try {
        $context = Get-AzContext -ErrorAction Stop
        if (-not $context) {
            Write-Warning "Not connected to Azure. Please run Connect-AzAccount first."
            return $false
        }
        Write-Verbose "Connected to Azure as: $($context.Account.Id)"
        return $true
    }
    catch {
        Write-Warning "Azure connection test failed: $($_.Exception.Message)"
        return $false
    }
}
function Export-ResourceGroupTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        [Parameter(Mandatory)]
        [string[]]$ResourceIds,
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    try {
        Export-AzResourceGroup -ResourceGroupName $ResourceGroupName -Resource $ResourceIds -Path $OutputPath -Force
        return $true
    }
    catch {
        Write-Log "Failed to export template: $($_.Exception.Message)" -Level WARNING
        return $false
    }
}
function Copy-KeyVaultSecrets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceKeyVaultName,
        [Parameter(Mandatory)]
        [string]$TargetKeyVaultName
    )
    try {
        $secrets = Get-AzKeyVaultSecret -VaultName $SourceKeyVaultName
        $copiedCount = 0
        foreach ($secret in $secrets) {
            $secretValue = Get-AzKeyVaultSecret -VaultName $SourceKeyVaultName -Name $secret.Name -AsPlainText
            Set-AzKeyVaultSecret -VaultName $TargetKeyVaultName -Name $secret.Name -SecretValue (ConvertTo-SecureString $secretValue -AsPlainText -Force)
            $copiedCount++
        }
        Write-Log "Copied $copiedCount secrets from $SourceKeyVaultName to $TargetKeyVaultName" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Failed to copy Key Vault secrets: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}
#endregion
#region Main-Execution
try {
    Write-Host "Azure Environment Cloner" -ForegroundColor White
    Write-Host "========================" -ForegroundColor White
    Write-Host "Source: $SourceResourceGroup" -ForegroundColor Gray
    Write-Host "Target: $TargetResourceGroup" -ForegroundColor Gray
    Write-Host "What-If Mode: $WhatIf" -ForegroundColor Gray
    Write-Host ""
    # Test Azure connection
    if (-not (Get-AzContext)) { throw "Not connected to Azure" }
        throw "Azure connection required. Please run Connect-AzAccount first."
    }
    Write-Progress -Activity "Environment Cloning" -Status "Validating source environment..." -PercentComplete 10
    # Validate source resource group
    try {
        $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroup
        Write-Log "Source resource group validated: $($sourceRG.ResourceGroupName) in $($sourceRG.Location)" -Level SUCCESS
    }
    catch {
        throw "Source resource group '$SourceResourceGroup' not found or inaccessible"
    }
    # Set target location (default to source location)
    if (-not $TargetLocation) {
        $TargetLocation = $sourceRG.Location
        Write-Log "Using source location for target: $TargetLocation" -Level INFO
    }
    Write-Progress -Activity "Environment Cloning" -Status "Discovering resources..." -PercentComplete 20
    # Get source resources
    $sourceResources = Get-AzResource -ResourceGroupName $SourceResourceGroup
    $filteredResources = if ($ExcludeResourceTypes.Count -gt 0) {
        $sourceResources | Where-Object { $_.ResourceType -notin $ExcludeResourceTypes }
    } else {
        $sourceResources
    }
    Write-Log "Found $($sourceResources.Count) total resources, $($filteredResources.Count) will be cloned" -Level INFO
    if ($filteredResources.Count -eq 0) {
        throw "No resources found to clone after applying filters"
    }
    Write-Progress -Activity "Environment Cloning" -Status "Mapping resource dependencies..." -PercentComplete 30
    # Create resource mapping
    $resourceMap = @{}
    foreach ($resource in $filteredResources) {
        $newName = $NamingConvention.Replace('{OriginalName}', $resource.Name)
        $resourceMap[$resource.ResourceId] = @{
            OriginalResource = $resource
            NewName = $newName
            ResourceType = $resource.ResourceType
            Status = 'Pending'
        }
    }
    Write-Progress -Activity "Environment Cloning" -Status "Setting up target environment..." -PercentComplete 40
    # Create target resource group
    if ($WhatIf) {
        Write-Log "[WHAT-IF] Would create resource group: $TargetResourceGroup in $TargetLocation" -Level INFO
    } else {
        $targetRG = Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction SilentlyContinue
        if (-not $targetRG) {
            if ($PSCmdlet.ShouldProcess($TargetResourceGroup, 'Create Resource Group')) {
                $targetRG = New-AzResourceGroup -Name $TargetResourceGroup -Location $TargetLocation
                Write-Log "Created target resource group: $($targetRG.ResourceGroupName)" -Level SUCCESS
            }
        } else {
            Write-Log "Target resource group already exists: $($targetRG.ResourceGroupName)" -Level INFO
            if (-not $Force -and -not $WhatIf) {
                $confirmation = Read-Host "Target resource group exists. Continue? (y/N)"
                if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
                    throw "Operation cancelled by user"
                }
            }
        }
    }
    Write-Progress -Activity "Environment Cloning" -Status "Generating ARM templates..." -PercentComplete 50
    # Group resources by type and export templates
    $resourceTypes = $filteredResources | Group-Object ResourceType
    $templates = @{}
    $exportErrors = @()
    Write-Log "Exporting ARM templates for $($resourceTypes.Count) resource types" -Level INFO
    foreach ($resourceType in $resourceTypes) {
        $safeTypeName = $resourceType.Name.Replace('/', '_').Replace('\', '_')
        $templatePath = "temp_template_$safeTypeName.json"
        if ($WhatIf) {
            Write-Log "[WHAT-IF] Would export template for $($resourceType.Name)" -Level INFO
            $templates[$resourceType.Name] = $templatePath
        } else {
            $resourceIds = $resourceType.Group.ResourceId
            if (Export-ResourceGroupTemplate -ResourceGroupName $SourceResourceGroup -ResourceIds $resourceIds -OutputPath $templatePath) {
                $templates[$resourceType.Name] = $templatePath
                Write-Log "Exported template for $($resourceType.Name)" -Level SUCCESS
            } else {
                $exportErrors += "Failed to export template for $($resourceType.Name)"
            }
        }
    }
    if ($exportErrors.Count -gt 0 -and -not $WhatIf) {
        Write-Log "$($exportErrors.Count) template export errors occurred" -Level WARNING
    }
    Write-Progress -Activity "Environment Cloning" -Status "Processing secrets and configurations..." -PercentComplete 60
    # Handle Key Vault secrets if requested
    if ($IncludeSecrets) {
        $keyVaults = $filteredResources | Where-Object { $_.ResourceType -eq 'Microsoft.KeyVault/vaults' }
        if ($keyVaults.Count -gt 0) {
            Write-Log "Found $($keyVaults.Count) Key Vault(s) for secret processing" -Level INFO
            foreach ($kv in $keyVaults) {
                $targetKVName = $NamingConvention.Replace('{OriginalName}', $kv.Name)
                if ($WhatIf) {
                    Write-Log "[WHAT-IF] Would copy secrets from $($kv.Name) to $targetKVName" -Level INFO
                } else {
                    Write-Log "Processing Key Vault secrets: $($kv.Name)" -Level INFO
                    # Note: Secret copying will occur after Key Vault is deployed
                }
            }
        }
    } else {
        Write-Log "Skipping Key Vault secrets (IncludeSecrets not specified)" -Level INFO
    }
    Write-Progress -Activity "Environment Cloning" -Status "Deploying resources..." -PercentComplete 70
    $deploymentResults = @()
    $deploymentErrors = @()
    Write-Log "Starting deployment of $($templates.Count) resource templates" -Level INFO
    foreach ($template in $templates.GetEnumerator()) {
        $safeTypeName = $template.Key.Replace('/', '-').Replace('\', '-')
        $deploymentName = "Clone-$safeTypeName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        if ($WhatIf) {
            Write-Log "[WHAT-IF] Would deploy template: $($template.Key)" -Level INFO
        } else {
            try {
                if ($PSCmdlet.ShouldProcess($template.Key, 'Deploy ARM Template')) {
                    Write-Log "Deploying $($template.Key)..." -Level INFO
                    $deployment = New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroup -TemplateFile $template.Value -Name $deploymentName -ErrorAction Stop
                    $deploymentResults += @{
                        ResourceType = $template.Key
                        DeploymentName = $deploymentName
                        Status = 'Succeeded'
                        Resources = $deployment.Outputs.Count
                    }
                    Write-Log "Successfully deployed: $($template.Key)" -Level SUCCESS
                }
            } catch {
                $errorMsg = "Failed to deploy $($template.Key): $($_.Exception.Message)"
                $deploymentErrors += $errorMsg
                Write-Log $errorMsg -Level ERROR
                $deploymentResults += @{
                    ResourceType = $template.Key
                    DeploymentName = $deploymentName
                    Status = 'Failed'
                    Error = $_.Exception.Message
                }
            }
        }
    }
    Write-Progress -Activity "Environment Cloning" -Status "Applying final configurations..." -PercentComplete 85
    # Apply tag overrides to cloned resources
    if ($TagOverrides.Count -gt 0 -and -not $WhatIf) {
        Write-Log "Applying tag overrides to cloned resources" -Level INFO
        $targetResources = Get-AzResource -ResourceGroupName $TargetResourceGroup
        $taggedCount = 0
        foreach ($resource in $targetResources) {
            try {
                $currentTags = $resource.Tags ?? @{}
                $updated = $false
                foreach ($tag in $TagOverrides.GetEnumerator()) {
                    if ($currentTags[$tag.Key] -ne $tag.Value) {
                        $currentTags[$tag.Key] = $tag.Value
                        $updated = $true
                    }
                }
                if ($updated) {
                    Set-AzResource -ResourceId $resource.ResourceId -Tag $currentTags -Force
                    $taggedCount++
                }
            } catch {
                Write-Log "Failed to apply tags to $($resource.Name): $($_.Exception.Message)" -Level WARNING
            }
        }
        Write-Log "Applied tag overrides to $taggedCount resources" -Level SUCCESS
    }
    # Process Key Vault secrets after deployment
    if ($IncludeSecrets -and -not $WhatIf) {
        $sourceKeyVaults = $filteredResources | Where-Object { $_.ResourceType -eq 'Microsoft.KeyVault/vaults' }
        $targetKeyVaults = Get-AzResource -ResourceGroupName $TargetResourceGroup | Where-Object { $_.ResourceType -eq 'Microsoft.KeyVault/vaults' }
        foreach ($sourceKV in $sourceKeyVaults) {
            $targetKVName = $NamingConvention.Replace('{OriginalName}', $sourceKV.Name)
            $targetKV = $targetKeyVaults | Where-Object { $_.Name -eq $targetKVName }
            if ($targetKV) {
                Copy-KeyVaultSecrets -SourceKeyVaultName $sourceKV.Name -TargetKeyVaultName $targetKV.Name
            }
        }
    }
    # Clean up temporary template files
    if (-not $WhatIf) {
        foreach ($templatePath in $templates.Values) {
            if (Test-Path $templatePath) {
                try {
                    Remove-Item $templatePath -Force
                } catch {
                    Write-Log "Failed to remove temporary file $templatePath" -Level WARNING
                }
            }
        }
    }
        # Display final results
    Write-Host ""
    if ($WhatIf) {
        Write-Host "Environment Cloning Simulation Results" -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        Write-Host "Source: $SourceResourceGroup ($($sourceResources.Count) resources)" -ForegroundColor White
        Write-Host "Target: $TargetResourceGroup (would be created)" -ForegroundColor White
        Write-Host "Templates: $($templates.Count) would be deployed" -ForegroundColor White
        Write-Log "What-If simulation completed successfully" -Level SUCCESS
    } else {
        Write-Host "Environment Cloning Results" -ForegroundColor Green
        Write-Host "===========================" -ForegroundColor Green
        Write-Host "Source: $SourceResourceGroup ($($sourceResources.Count) resources)" -ForegroundColor White
        Write-Host "Target: $TargetResourceGroup" -ForegroundColor White
        Write-Host "Successful Deployments: $(($deploymentResults | Where-Object { $_.Status -eq 'Succeeded' }).Count)" -ForegroundColor White
        Write-Host "Failed Deployments: $(($deploymentResults | Where-Object { $_.Status -eq 'Failed' }).Count)" -ForegroundColor White
        if ($deploymentErrors.Count -gt 0) {
            Write-Host ""
            Write-Host "Deployment Errors:" -ForegroundColor Yellow
            foreach ($error in $deploymentErrors) {
                Write-Host "   $error" -ForegroundColor Red
            }
        }
        Write-Host ""
        Write-Log "Environment cloning operation completed" -Level SUCCESS
    }
} catch {
        Write-Log "Environment cloning failed: $($_.Exception.Message)" -Level ERROR
    Write-Host ""
    Write-Host "Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "- Verify Azure PowerShell modules are installed and up-to-date" -ForegroundColor Gray
    Write-Host "- Check Azure authentication and subscription access" -ForegroundColor Gray
    Write-Host "- Ensure Contributor role on both source and target subscriptions" -ForegroundColor Gray
    Write-Host "- Validate resource group names and target location" -ForegroundColor Gray
    Write-Host "- Check for resource-specific limitations or dependencies" -ForegroundColor Gray
    Write-Host ""
    throw
} finally {
    Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO
}

