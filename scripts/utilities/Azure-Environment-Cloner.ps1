#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
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
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, HelpMessage="Source resource group name")]
    [ValidateNotNullOrEmpty()]
    $SourceResourceGroup,
    [Parameter(Mandatory, HelpMessage="Target resource group name")]
    [ValidateNotNullOrEmpty()]
    $TargetResourceGroup,
    [Parameter(HelpMessage="Target Azure region")]
    [ValidateNotNullOrEmpty()]
    $TargetLocation,
    [Parameter(HelpMessage="Resource types to exclude from cloning")]
    [string[]]$ExcludeResourceTypes = @(),
    [Parameter(HelpMessage="Tags to apply to cloned resources")]
    [hashtable]$TagOverrides = @{},
    [Parameter(HelpMessage="Naming pattern for cloned resources")]
    [ValidateNotNullOrEmpty()]
    $NamingConvention = '{OriginalName}',
    [Parameter(HelpMessage="Include Key Vault secrets in cloning")]
    [switch]$IncludeSecrets,
    [Parameter(HelpMessage="Preview operations without changes")]
    [switch]$WhatIf,
    [Parameter(HelpMessage="Suppress confirmation prompts")]
    [switch]$Force
)
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
try {
    Write-Verbose "Importing required Azure modules..."
            }
catch {
    Write-Error "Failed to import required modules. Please install Az PowerShell module: Install-Module Az"
    throw
}
function Write-Log {
    param(
        [Parameter(Mandatory)]
        $Message,
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        $Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
    }
    Write-Output "[$timestamp] [$Level] $Message" -ForegroundColor $color
}
if (-not (Get-AzContext)) { throw "Not connected to Azure" }
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
    param(
        [Parameter(Mandatory)]
        $ResourceGroupName,
        [Parameter(Mandatory)]
        [string[]]$ResourceIds,
        [Parameter(Mandatory)]
        $OutputPath
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
    param(
        [Parameter(Mandatory)]
        $SourceKeyVaultName,
        [Parameter(Mandatory)]
        $TargetKeyVaultName
    )
    try {
    $secrets = Get-AzKeyVaultSecret -VaultName $SourceKeyVaultName
    $CopiedCount = 0
        foreach ($secret in $secrets) {
    $SecretValue = Get-AzKeyVaultSecret -VaultName $SourceKeyVaultName -Name $secret.Name -AsPlainText
            Set-AzKeyVaultSecret -VaultName $TargetKeyVaultName -Name $secret.Name -SecretValue (Read-Host -Prompt "Enter secure value" -AsSecureString)
    $CopiedCount++
        }
        Write-Log "Copied $CopiedCount secrets from $SourceKeyVaultName to $TargetKeyVaultName" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Failed to copy Key Vault secrets: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}
try {
    Write-Output "Azure Environment Cloner" # Color: $2
    Write-Output "========================" # Color: $2
    Write-Output "Source: $SourceResourceGroup" # Color: $2
    Write-Output "Target: $TargetResourceGroup" # Color: $2
    Write-Output "What-If Mode: $WhatIf" # Color: $2
    Write-Output ""
    if (-not (Get-AzContext)) { throw "Not connected to Azure" }
        throw "Azure connection required. Please run Connect-AzAccount first."
    }
    Write-Progress -Activity "Environment Cloning" -Status "Validating source environment..." -PercentComplete 10
    try {
    $SourceRG = Get-AzResourceGroup -Name $SourceResourceGroup
        Write-Log "Source resource group validated: $($SourceRG.ResourceGroupName) in $($SourceRG.Location)" -Level SUCCESS
    }
    catch {
        throw "Source resource group '$SourceResourceGroup' not found or inaccessible"
    }
    if (-not $TargetLocation) {
    $TargetLocation = $SourceRG.Location
        Write-Log "Using source location for target: $TargetLocation" -Level INFO
    }
    Write-Progress -Activity "Environment Cloning" -Status "Discovering resources..." -PercentComplete 20
    $SourceResources = Get-AzResource -ResourceGroupName $SourceResourceGroup
    $FilteredResources = if ($ExcludeResourceTypes.Count -gt 0) {
    $SourceResources | Where-Object { $_.ResourceType -notin $ExcludeResourceTypes }
    } else {
    $SourceResources
    }
    Write-Log "Found $($SourceResources.Count) total resources, $($FilteredResources.Count) will be cloned" -Level INFO
    if ($FilteredResources.Count -eq 0) {
        throw "No resources found to clone after applying filters"
    }
    Write-Progress -Activity "Environment Cloning" -Status "Mapping resource dependencies..." -PercentComplete 30
    $ResourceMap = @{}
    foreach ($resource in $FilteredResources) {
    $NewName = $NamingConvention.Replace('{OriginalName}', $resource.Name)
    $ResourceMap[$resource.ResourceId] = @{
            OriginalResource = $resource
            NewName = $NewName
            ResourceType = $resource.ResourceType
            Status = 'Pending'
        }
    }
    Write-Progress -Activity "Environment Cloning" -Status "Setting up target environment..." -PercentComplete 40
    if ($WhatIf) {
        Write-Log "[WHAT-IF] Would create resource group: $TargetResourceGroup in $TargetLocation" -Level INFO
    } else {
    $TargetRG = Get-AzResourceGroup -Name $TargetResourceGroup -ErrorAction SilentlyContinue
        if (-not $TargetRG) {
            if ($PSCmdlet.ShouldProcess($TargetResourceGroup, 'Create Resource Group')) {
    $TargetRG = New-AzResourceGroup -Name $TargetResourceGroup -Location $TargetLocation
                Write-Log "Created target resource group: $($TargetRG.ResourceGroupName)" -Level SUCCESS
            }
        } else {
            Write-Log "Target resource group already exists: $($TargetRG.ResourceGroupName)" -Level INFO
            if (-not $Force -and -not $WhatIf) {
    $confirmation = Read-Host "Target resource group exists. Continue? (y/N)"
                if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
                    throw "Operation cancelled by user"
                }
            }
        }
    }
    Write-Progress -Activity "Environment Cloning" -Status "Generating ARM templates..." -PercentComplete 50
    $ResourceTypes = $FilteredResources | Group-Object ResourceType
    $templates = @{}
    $ExportErrors = @()
    Write-Log "Exporting ARM templates for $($ResourceTypes.Count) resource types" -Level INFO
    foreach ($ResourceType in $ResourceTypes) {
    $SafeTypeName = $ResourceType.Name.Replace('/', '_').Replace('\', '_')
    $TemplatePath = "temp_template_$SafeTypeName.json"
        if ($WhatIf) {
            Write-Log "[WHAT-IF] Would export template for $($ResourceType.Name)" -Level INFO
    $templates[$ResourceType.Name] = $TemplatePath
        } else {
    $ResourceIds = $ResourceType.Group.ResourceId
            if (Export-ResourceGroupTemplate -ResourceGroupName $SourceResourceGroup -ResourceIds $ResourceIds -OutputPath $TemplatePath) {
    $templates[$ResourceType.Name] = $TemplatePath
                Write-Log "Exported template for $($ResourceType.Name)" -Level SUCCESS
            } else {
    $ExportErrors += "Failed to export template for $($ResourceType.Name)"
            }
        }
    }
    if ($ExportErrors.Count -gt 0 -and -not $WhatIf) {
        Write-Log "$($ExportErrors.Count) template export errors occurred" -Level WARNING
    }
    Write-Progress -Activity "Environment Cloning" -Status "Processing secrets and configurations..." -PercentComplete 60
    if ($IncludeSecrets) {
    $KeyVaults = $FilteredResources | Where-Object { $_.ResourceType -eq 'Microsoft.KeyVault/vaults' }
        if ($KeyVaults.Count -gt 0) {
            Write-Log "Found $($KeyVaults.Count) Key Vault(s) for secret processing" -Level INFO
            foreach ($kv in $KeyVaults) {
    $TargetKVName = $NamingConvention.Replace('{OriginalName}', $kv.Name)
                if ($WhatIf) {
                    Write-Log "[WHAT-IF] Would copy secrets from $($kv.Name) to $TargetKVName" -Level INFO
                } else {
                    Write-Log "Processing Key Vault secrets: $($kv.Name)" -Level INFO
                }
            }
        }
    } else {
        Write-Log "Skipping Key Vault secrets (IncludeSecrets not specified)" -Level INFO
    }
    Write-Progress -Activity "Environment Cloning" -Status "Deploying resources..." -PercentComplete 70
    $DeploymentResults = @()
    $DeploymentErrors = @()
    Write-Log "Starting deployment of $($templates.Count) resource templates" -Level INFO
    foreach ($template in $templates.GetEnumerator()) {
    $SafeTypeName = $template.Key.Replace('/', '-').Replace('\', '-')
    $DeploymentName = "Clone-$SafeTypeName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        if ($WhatIf) {
            Write-Log "[WHAT-IF] Would deploy template: $($template.Key)" -Level INFO
        } else {
            try {
                if ($PSCmdlet.ShouldProcess($template.Key, 'Deploy ARM Template')) {
                    Write-Log "Deploying $($template.Key)..." -Level INFO
    $deployment = New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroup -TemplateFile $template.Value -Name $DeploymentName -ErrorAction Stop
    $DeploymentResults += @{
                        ResourceType = $template.Key
                        DeploymentName = $DeploymentName
                        Status = 'Succeeded'
                        Resources = $deployment.Outputs.Count
                    }
                    Write-Log "Successfully deployed: $($template.Key)" -Level SUCCESS
                }
            } catch {
    $ErrorMsg = "Failed to deploy $($template.Key): $($_.Exception.Message)"
    $DeploymentErrors += $ErrorMsg
                Write-Log $ErrorMsg -Level ERROR
    $DeploymentResults += @{
                    ResourceType = $template.Key
                    DeploymentName = $DeploymentName
                    Status = 'Failed'
                    Error = $_.Exception.Message
                }
            }
        }
    }
    Write-Progress -Activity "Environment Cloning" -Status "Applying final configurations..." -PercentComplete 85
    if ($TagOverrides.Count -gt 0 -and -not $WhatIf) {
        Write-Log "Applying tag overrides to cloned resources" -Level INFO
    $TargetResources = Get-AzResource -ResourceGroupName $TargetResourceGroup
    $TaggedCount = 0
        foreach ($resource in $TargetResources) {
            try {
    $CurrentTags = $resource.Tags ?? @{}
    $updated = $false
                foreach ($tag in $TagOverrides.GetEnumerator()) {
                    if ($CurrentTags[$tag.Key] -ne $tag.Value) {
    $CurrentTags[$tag.Key] = $tag.Value
    $updated = $true
                    }
                }
                if ($updated) {
                    Set-AzResource -ResourceId $resource.ResourceId -Tag $CurrentTags -Force
    $TaggedCount++
                }
            } catch {
                Write-Log "Failed to apply tags to $($resource.Name): $($_.Exception.Message)" -Level WARNING
            }
        }
        Write-Log "Applied tag overrides to $TaggedCount resources" -Level SUCCESS
    }
    if ($IncludeSecrets -and -not $WhatIf) {
    $SourceKeyVaults = $FilteredResources | Where-Object { $_.ResourceType -eq 'Microsoft.KeyVault/vaults' }
    $TargetKeyVaults = Get-AzResource -ResourceGroupName $TargetResourceGroup | Where-Object { $_.ResourceType -eq 'Microsoft.KeyVault/vaults' }
        foreach ($SourceKV in $SourceKeyVaults) {
    $TargetKVName = $NamingConvention.Replace('{OriginalName}', $SourceKV.Name)
    $TargetKV = $TargetKeyVaults | Where-Object { $_.Name -eq $TargetKVName }
            if ($TargetKV) {
                Copy-KeyVaultSecrets -SourceKeyVaultName $SourceKV.Name -TargetKeyVaultName $TargetKV.Name
            }
        }
    }
    if (-not $WhatIf) {
        foreach ($TemplatePath in $templates.Values) {
            if (Test-Path $TemplatePath) {
                try {
                    Remove-Item $TemplatePath -Force
                } catch {
                    Write-Log "Failed to remove temporary file $TemplatePath" -Level WARNING
                }
            }
        }
    }
    Write-Output ""
    if ($WhatIf) {
        Write-Output "Environment Cloning Simulation Results" # Color: $2
        Write-Output "======================================" # Color: $2
        Write-Output "Source: $SourceResourceGroup ($($SourceResources.Count) resources)" # Color: $2
        Write-Output "Target: $TargetResourceGroup (would be created)" # Color: $2
        Write-Output "Templates: $($templates.Count) would be deployed" # Color: $2
        Write-Log "What-If simulation completed successfully" -Level SUCCESS
    } else {
        Write-Output "Environment Cloning Results" # Color: $2
        Write-Output "===========================" # Color: $2
        Write-Output "Source: $SourceResourceGroup ($($SourceResources.Count) resources)" # Color: $2
        Write-Output "Target: $TargetResourceGroup" # Color: $2
        Write-Output "Successful Deployments: $(($DeploymentResults | Where-Object { $_.Status -eq 'Succeeded' }).Count)" # Color: $2
        Write-Output "Failed Deployments: $(($DeploymentResults | Where-Object { $_.Status -eq 'Failed' }).Count)" # Color: $2
        if ($DeploymentErrors.Count -gt 0) {
            Write-Output ""
            Write-Output "Deployment Errors:" # Color: $2
            foreach ($error in $DeploymentErrors) {
                Write-Output "   $error" # Color: $2
            }
        }
        Write-Output ""
        Write-Log "Environment cloning operation completed" -Level SUCCESS
    }
} catch {
        Write-Log "Environment cloning failed: $($_.Exception.Message)" -Level ERROR
    Write-Output ""
    Write-Output "Troubleshooting Tips:" # Color: $2
    Write-Output "- Verify Azure PowerShell modules are installed and up-to-date" # Color: $2
    Write-Output "- Check Azure authentication and subscription access" # Color: $2
    Write-Output "- Ensure Contributor role on both source and target subscriptions" # Color: $2
    Write-Output "- Validate resource group names and target location" # Color: $2
    Write-Output "- Check for resource-specific limitations or dependencies" # Color: $2
    Write-Output ""
    throw
} finally {
    Write-Log "Script execution completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level INFO`n}
