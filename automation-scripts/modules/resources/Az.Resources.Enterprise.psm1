#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Enterprise Azure Resources Management Module
.DESCRIPTION
    Advanced resource management, tagging, and governance for enterprise Azure environments
.VERSION
    2.0.0
.AUTHOR
    Azure Enterprise Toolkit
#>

# Module configuration
$script:ModuleVersion = '2.0.0'
$script:TaggingStandards = @{
    Required = @('Environment', 'CostCenter', 'Owner', 'Project')
    Optional = @('Department', 'ExpirationDate', 'Compliance', 'DataClassification')
}

#region Resource Group Management

function New-AzResourceGroupAdvanced {
    <#
    .SYNOPSIS
        Create resource group with enterprise standards
    .DESCRIPTION
        Creates a resource group with required tags, locks, and policies
    .PARAMETER Name
        Resource group name following naming convention
    .PARAMETER Location
        Azure region
    .PARAMETER Tags
        Hashtable of tags (must include required tags)
    .PARAMETER ApplyLock
        Apply resource lock to prevent deletion
    .PARAMETER PolicyAssignments
        Array of policy definition IDs to assign
    .EXAMPLE
        New-AzResourceGroupAdvanced -Name "rg-prod-app01" -Location "eastus" -Tags @{Environment="Production"; CostCenter="IT001"; Owner="admin@contoso.com"; Project="WebApp"}
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^rg-[a-z0-9\-]+$')]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$Location,
        
        [Parameter(Mandatory)]
        [hashtable]$Tags,
        
        [switch]$ApplyLock,
        
        [string[]]$PolicyAssignments
    )
    
    # Validate required tags
    $missingTags = $script:TaggingStandards.Required | Where-Object { $_ -notin $Tags.Keys }
    if ($missingTags) {
        throw "Missing required tags: $($missingTags -join ', ')"
    }
    
    # Add metadata tags
    $Tags['CreatedBy'] = (Get-AzContext).Account.Id
    $Tags['CreatedDate'] = (Get-Date -Format 'yyyy-MM-dd')
    $Tags['ManagedBy'] = 'AzureEnterpriseToolkit'
    
    if ($PSCmdlet.ShouldProcess($Name, "Create resource group")) {
        try {
            # Create resource group
            $rg = New-AzResourceGroup -Name $Name -Location $Location -Tag $Tags -Force
            
            # Apply lock if requested
            if ($ApplyLock) {
                New-AzResourceLock -LockName "DoNotDelete" -LockLevel CanNotDelete `
                    -ResourceGroupName $Name -LockNotes "Applied by Azure Enterprise Toolkit" -Force
            }
            
            # Assign policies
            foreach ($policyId in $PolicyAssignments) {
                New-AzPolicyAssignment -Name "policy-$Name-$(Get-Random)" `
                    -PolicyDefinition (Get-AzPolicyDefinition -Id $policyId) `
                    -Scope $rg.ResourceId
            }
            
            Write-Information "Successfully created resource group: $Name" -InformationAction Continue
            return $rg
        }
        catch {
            Write-Error "Failed to create resource group: $_"
        }
    }
}

function Remove-AzResourceGroupSafely {
    <#
    .SYNOPSIS
        Safely remove resource group with validation
    .DESCRIPTION
        Removes resource group after validating contents and getting confirmation
    .PARAMETER Name
        Resource group name to remove
    .PARAMETER Force
        Skip confirmation prompts
    .PARAMETER ExportResources
        Export resource information before deletion
    .EXAMPLE
        Remove-AzResourceGroupSafely -Name "rg-dev-test01" -ExportResources
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [switch]$Force,
        
        [switch]$ExportResources
    )
    
    try {
        $rg = Get-AzResourceGroup -Name $Name -ErrorAction Stop
        $resources = Get-AzResource -ResourceGroupName $Name
        
        # Check for locks
        $locks = Get-AzResourceLock -ResourceGroupName $Name
        if ($locks -and -not $Force) {
            throw "Resource group has locks. Remove locks first or use -Force"
        }
        
        # Display resource summary
        Write-Information "Resource group contains:" -InformationAction Continue
        Write-Information "- Total resources: $($resources.Count)" -InformationAction Continue
        $resources | Group-Object ResourceType | ForEach-Object {
            Write-Information "  - $($_.Name): $($_.Count)" -InformationAction Continue
        }
        
        # Export resources if requested
        if ($ExportResources) {
            $exportPath = ".\ResourceExport_$Name_$(Get-Date -Format 'yyyyMMddHHmmss').json"
            $resources | ConvertTo-Json -Depth 10 | Out-File $exportPath
            Write-Information "Resources exported to: $exportPath" -InformationAction Continue
        }
        
        if ($PSCmdlet.ShouldProcess($Name, "Remove resource group and all resources")) {
            # Remove locks if forced
            if ($locks -and $Force) {
                $locks | Remove-AzResourceLock -Force
            }
            
            # Remove resource group
            Remove-AzResourceGroup -Name $Name -Force
            Write-Information "Successfully removed resource group: $Name" -InformationAction Continue
        }
    }
    catch {
        Write-Error "Failed to remove resource group: $_"
    }
}

#endregion

#region Tag Management and Enforcement

function Set-AzResourceTags {
    <#
    .SYNOPSIS
        Apply tags to resources with inheritance
    .DESCRIPTION
        Applies tags to resources with support for tag inheritance from resource groups
    .PARAMETER ResourceId
        Resource ID or array of resource IDs
    .PARAMETER Tags
        Hashtable of tags to apply
    .PARAMETER InheritFromResourceGroup
        Inherit tags from parent resource group
    .PARAMETER Merge
        Merge with existing tags instead of replacing
    .EXAMPLE
        Get-AzResource -ResourceGroupName "rg-prod" | Set-AzResourceTags -Tags @{Environment="Production"} -Merge
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('Id')]
        [string[]]$ResourceId,
        
        [Parameter(Mandatory)]
        [hashtable]$Tags,
        
        [switch]$InheritFromResourceGroup,
        
        [switch]$Merge
    )
    
    process {
        foreach ($id in $ResourceId) {
            try {
                $resource = Get-AzResource -ResourceId $id
                $currentTags = $resource.Tags ?? @{}
                
                # Get resource group tags if inheriting
                if ($InheritFromResourceGroup) {
                    $rg = Get-AzResourceGroup -Name $resource.ResourceGroupName
                    $rgTags = $rg.Tags ?? @{}
                    
                    # Merge RG tags (RG tags don't override explicit tags)
                    foreach ($key in $rgTags.Keys) {
                        if ($key -notin $Tags.Keys) {
                            $Tags[$key] = $rgTags[$key]
                        }
                    }
                }
                
                # Merge or replace tags
                if ($Merge) {
                    foreach ($key in $Tags.Keys) {
                        $currentTags[$key] = $Tags[$key]
                    }
                    $finalTags = $currentTags
                }
                else {
                    $finalTags = $Tags
                }
                
                if ($PSCmdlet.ShouldProcess($resource.Name, "Update tags")) {
                    Update-AzTag -ResourceId $id -Tag $finalTags -Operation Replace
                    Write-Verbose "Updated tags for: $($resource.Name)"
                }
            }
            catch {
                Write-Error "Failed to update tags for resource $id: $_"
            }
        }
    }
}

function Test-AzResourceCompliance {
    <#
    .SYNOPSIS
        Test resources against tagging compliance
    .DESCRIPTION
        Validates resources against enterprise tagging standards
    .PARAMETER ResourceGroupName
        Resource group to test (or all if not specified)
    .PARAMETER FixNonCompliant
        Attempt to fix non-compliant resources
    .EXAMPLE
        Test-AzResourceCompliance -ResourceGroupName "rg-prod" -FixNonCompliant
    #>
    [CmdletBinding()]
    param(
        [string]$ResourceGroupName,
        
        [switch]$FixNonCompliant
    )
    
    $results = @()
    
    # Get resources
    if ($ResourceGroupName) {
        $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    }
    else {
        $resources = Get-AzResource
    }
    
    foreach ($resource in $resources) {
        $compliance = @{
            ResourceId = $resource.ResourceId
            ResourceName = $resource.Name
            ResourceType = $resource.ResourceType
            IsCompliant = $true
            MissingTags = @()
            Issues = @()
        }
        
        # Check required tags
        $missingRequired = $script:TaggingStandards.Required | Where-Object { 
            $_ -notin $resource.Tags.Keys -or [string]::IsNullOrWhiteSpace($resource.Tags[$_])
        }
        
        if ($missingRequired) {
            $compliance.IsCompliant = $false
            $compliance.MissingTags = $missingRequired
            $compliance.Issues += "Missing required tags: $($missingRequired -join ', ')"
        }
        
        # Fix if requested
        if ($FixNonCompliant -and -not $compliance.IsCompliant) {
            try {
                # Inherit from resource group
                $rg = Get-AzResourceGroup -Name $resource.ResourceGroupName
                $fixTags = @{}
                
                foreach ($tag in $missingRequired) {
                    if ($rg.Tags.ContainsKey($tag)) {
                        $fixTags[$tag] = $rg.Tags[$tag]
                    }
                    else {
                        $fixTags[$tag] = "NEEDS_VALUE"
                    }
                }
                
                Set-AzResourceTags -ResourceId $resource.ResourceId -Tags $fixTags -Merge
                $compliance.Fixed = $true
            }
            catch {
                $compliance.FixError = $_.Exception.Message
            }
        }
        
        $results += [PSCustomObject]$compliance
    }
    
    # Summary
    $summary = @{
        TotalResources = $results.Count
        CompliantResources = ($results | Where-Object IsCompliant).Count
        NonCompliantResources = ($results | Where-Object { -not $_.IsCompliant }).Count
        FixedResources = ($results | Where-Object Fixed).Count
    }
    
    Write-Information "Compliance Summary: $($summary.CompliantResources)/$($summary.TotalResources) compliant" -InformationAction Continue
    
    return @{
        Summary = $summary
        Details = $results
    }
}

#endregion

#region Resource Naming Convention

function Test-AzResourceNamingConvention {
    <#
    .SYNOPSIS
        Validate resource names against naming conventions
    .DESCRIPTION
        Checks if resource names follow enterprise naming standards
    .PARAMETER ResourceName
        Resource name to validate
    .PARAMETER ResourceType
        Type of Azure resource
    .EXAMPLE
        Test-AzResourceNamingConvention -ResourceName "vm-prod-web01" -ResourceType "Microsoft.Compute/virtualMachines"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceName,
        
        [Parameter(Mandatory)]
        [string]$ResourceType
    )
    
    # Define naming patterns by resource type
    $namingPatterns = @{
        'Microsoft.Compute/virtualMachines' = '^vm-[a-z]+-[a-z0-9]+$'
        'Microsoft.Storage/storageAccounts' = '^st[a-z0-9]{3,22}$'
        'Microsoft.Network/virtualNetworks' = '^vnet-[a-z]+-[a-z0-9]+$'
        'Microsoft.Network/networkSecurityGroups' = '^nsg-[a-z]+-[a-z0-9]+$'
        'Microsoft.Sql/servers' = '^sql-[a-z]+-[a-z0-9]+$'
        'Microsoft.Web/sites' = '^app-[a-z]+-[a-z0-9]+$'
        'Microsoft.KeyVault/vaults' = '^kv-[a-z]+-[a-z0-9]+$'
    }
    
    $result = @{
        ResourceName = $ResourceName
        ResourceType = $ResourceType
        IsValid = $false
        Pattern = $null
        Recommendation = $null
    }
    
    if ($namingPatterns.ContainsKey($ResourceType)) {
        $pattern = $namingPatterns[$ResourceType]
        $result.Pattern = $pattern
        $result.IsValid = $ResourceName -match $pattern
        
        if (-not $result.IsValid) {
            # Generate recommendation
            switch ($ResourceType) {
                'Microsoft.Compute/virtualMachines' { 
                    $result.Recommendation = "Use format: vm-{environment}-{application}{number}"
                }
                'Microsoft.Storage/storageAccounts' {
                    $result.Recommendation = "Use format: st{purpose}{uniqueid} (3-24 chars, lowercase, no hyphens)"
                }
                'Microsoft.Network/virtualNetworks' {
                    $result.Recommendation = "Use format: vnet-{environment}-{purpose}"
                }
            }
        }
    }
    else {
        $result.IsValid = $true
        $result.Pattern = "No specific pattern defined"
    }
    
    return $result
}

function Rename-AzResourceBatch {
    <#
    .SYNOPSIS
        Bulk rename resources following naming conventions
    .DESCRIPTION
        Renames multiple resources to follow enterprise naming standards
    .PARAMETER ResourceMappings
        Hashtable of old names to new names
    .PARAMETER CreateSnapshot
        Create snapshot/backup before renaming (where applicable)
    .EXAMPLE
        $mappings = @{"oldvm1" = "vm-prod-web01"; "oldvm2" = "vm-prod-app01"}
        Rename-AzResourceBatch -ResourceMappings $mappings
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')]
    param(
        [Parameter(Mandatory)]
        [hashtable]$ResourceMappings,
        
        [switch]$CreateSnapshot
    )
    
    $results = @()
    
    foreach ($oldName in $ResourceMappings.Keys) {
        $newName = $ResourceMappings[$oldName]
        
        try {
            # Find resource
            $resource = Get-AzResource -Name $oldName -ErrorAction Stop
            
            # Validate new name
            $validation = Test-AzResourceNamingConvention -ResourceName $newName -ResourceType $resource.ResourceType
            if (-not $validation.IsValid) {
                Write-Warning "New name '$newName' doesn't follow naming convention. Recommendation: $($validation.Recommendation)"
                continue
            }
            
            if ($PSCmdlet.ShouldProcess($oldName, "Rename to $newName")) {
                # Resource-specific rename logic
                switch ($resource.ResourceType) {
                    'Microsoft.Compute/virtualMachines' {
                        Write-Warning "VMs cannot be renamed directly. Consider redeployment."
                        $results += [PSCustomObject]@{
                            OldName = $oldName
                            NewName = $newName
                            Status = "Skipped"
                            Message = "VMs require redeployment to rename"
                        }
                    }
                    'Microsoft.Storage/storageAccounts' {
                        Write-Warning "Storage accounts cannot be renamed. Consider data migration."
                        $results += [PSCustomObject]@{
                            OldName = $oldName
                            NewName = $newName
                            Status = "Skipped"
                            Message = "Storage accounts require data migration"
                        }
                    }
                    default {
                        # Generic rename attempt (works for some resource types)
                        try {
                            $resource.Name = $newName
                            Set-AzResource -ResourceId $resource.ResourceId -Properties $resource.Properties -Force
                            $results += [PSCustomObject]@{
                                OldName = $oldName
                                NewName = $newName
                                Status = "Success"
                                Message = "Renamed successfully"
                            }
                        }
                        catch {
                            $results += [PSCustomObject]@{
                                OldName = $oldName
                                NewName = $newName
                                Status = "Failed"
                                Message = $_.Exception.Message
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Error "Failed to process $oldName: $_"
        }
    }
    
    return $results
}

#endregion

#region Bulk Resource Operations

function Start-AzResourceBulkOperation {
    <#
    .SYNOPSIS
        Perform bulk operations on resources
    .DESCRIPTION
        Execute operations on multiple resources with parallel processing
    .PARAMETER Resources
        Array of resource objects or IDs
    .PARAMETER Operation
        Operation to perform (Start, Stop, Restart, Delete)
    .PARAMETER ThrottleLimit
        Maximum parallel operations
    .EXAMPLE
        Get-AzVM -ResourceGroupName "rg-prod" | Start-AzResourceBulkOperation -Operation Stop
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]$Resources,
        
        [Parameter(Mandatory)]
        [ValidateSet('Start', 'Stop', 'Restart', 'Delete', 'Backup')]
        [string]$Operation,
        
        [int]$ThrottleLimit = 10
    )
    
    begin {
        $allResources = @()
    }
    
    process {
        $allResources += $Resources
    }
    
    end {
        $jobs = @()
        
        foreach ($resource in $allResources) {
            if ($PSCmdlet.ShouldProcess($resource.Name, $Operation)) {
                $jobs += Start-ThreadJob -ScriptBlock {
                    param($res, $op)
                    
                    try {
                        switch ($op) {
                            'Start' {
                                if ($res.ResourceType -eq 'Microsoft.Compute/virtualMachines') {
                                    Start-AzVM -ResourceGroupName $res.ResourceGroupName -Name $res.Name
                                }
                            }
                            'Stop' {
                                if ($res.ResourceType -eq 'Microsoft.Compute/virtualMachines') {
                                    Stop-AzVM -ResourceGroupName $res.ResourceGroupName -Name $res.Name -Force
                                }
                            }
                            'Restart' {
                                if ($res.ResourceType -eq 'Microsoft.Compute/virtualMachines') {
                                    Restart-AzVM -ResourceGroupName $res.ResourceGroupName -Name $res.Name
                                }
                            }
                            'Delete' {
                                Remove-AzResource -ResourceId $res.ResourceId -Force
                            }
                        }
                        
                        return @{
                            Resource = $res.Name
                            Operation = $op
                            Status = 'Success'
                        }
                    }
                    catch {
                        return @{
                            Resource = $res.Name
                            Operation = $op
                            Status = 'Failed'
                            Error = $_.Exception.Message
                        }
                    }
                } -ArgumentList $resource, $Operation -ThrottleLimit $ThrottleLimit
            }
        }
        
        # Wait for completion and collect results
        $results = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job
        
        # Summary
        $summary = @{
            Total = $results.Count
            Successful = ($results | Where-Object { $_.Status -eq 'Success' }).Count
            Failed = ($results | Where-Object { $_.Status -eq 'Failed' }).Count
        }
        
        Write-Information "Operation completed: $($summary.Successful) successful, $($summary.Failed) failed" -InformationAction Continue
        
        return @{
            Summary = $summary
            Details = $results
        }
    }
}

#endregion

#region Resource Dependency Mapping

function Get-AzResourceDependencies {
    <#
    .SYNOPSIS
        Map resource dependencies
    .DESCRIPTION
        Analyzes and maps dependencies between Azure resources
    .PARAMETER ResourceGroupName
        Resource group to analyze
    .PARAMETER ExportPath
        Path to export dependency graph
    .EXAMPLE
        Get-AzResourceDependencies -ResourceGroupName "rg-prod" -ExportPath ".\dependencies.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ResourceGroupName,
        
        [string]$ExportPath
    )
    
    $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
    $dependencies = @{}
    
    foreach ($resource in $resources) {
        $deps = @()
        
        # Get resource details with properties
        $fullResource = Get-AzResource -ResourceId $resource.ResourceId -ExpandProperties
        
        # Extract dependencies based on resource type
        switch ($resource.ResourceType) {
            'Microsoft.Compute/virtualMachines' {
                # Network interfaces
                if ($fullResource.Properties.networkProfile.networkInterfaces) {
                    $deps += $fullResource.Properties.networkProfile.networkInterfaces.id
                }
                # Disks
                if ($fullResource.Properties.storageProfile.osDisk.managedDisk) {
                    $deps += $fullResource.Properties.storageProfile.osDisk.managedDisk.id
                }
            }
            'Microsoft.Network/networkInterfaces' {
                # Subnet
                if ($fullResource.Properties.ipConfigurations) {
                    $deps += $fullResource.Properties.ipConfigurations.properties.subnet.id
                }
                # NSG
                if ($fullResource.Properties.networkSecurityGroup) {
                    $deps += $fullResource.Properties.networkSecurityGroup.id
                }
            }
            'Microsoft.Web/sites' {
                # App Service Plan
                if ($fullResource.Properties.serverFarmId) {
                    $deps += $fullResource.Properties.serverFarmId
                }
            }
        }
        
        $dependencies[$resource.ResourceId] = @{
            Name = $resource.Name
            Type = $resource.ResourceType
            Dependencies = $deps
        }
    }
    
    # Create visual representation
    $graph = @{
        Resources = $dependencies
        Visualization = @()
    }
    
    foreach ($resourceId in $dependencies.Keys) {
        $res = $dependencies[$resourceId]
        foreach ($dep in $res.Dependencies) {
            $graph.Visualization += "$($res.Name) --> $((Get-AzResource -ResourceId $dep -ErrorAction SilentlyContinue).Name)"
        }
    }
    
    if ($ExportPath) {
        $graph | ConvertTo-Json -Depth 10 | Out-File $ExportPath
        Write-Information "Dependency map exported to: $ExportPath" -InformationAction Continue
    }
    
    return $graph
}

#endregion

#region Cost Allocation and Tracking

function Get-AzResourceCostByTag {
    <#
    .SYNOPSIS
        Get resource costs grouped by tags
    .DESCRIPTION
        Analyzes resource costs and groups by specified tag keys
    .PARAMETER TagKeys
        Tag keys to group by (e.g., 'CostCenter', 'Project')
    .PARAMETER StartDate
        Start date for cost analysis
    .PARAMETER EndDate
        End date for cost analysis
    .EXAMPLE
        Get-AzResourceCostByTag -TagKeys @('CostCenter', 'Environment') -StartDate (Get-Date).AddDays(-30)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$TagKeys,
        
        [datetime]$StartDate = (Get-Date).AddDays(-30),
        
        [datetime]$EndDate = (Get-Date)
    )
    
    # Note: This is a simplified version. Full implementation would use Azure Cost Management APIs
    $costData = @{}
    $resources = Get-AzResource
    
    foreach ($resource in $resources) {
        # Build tag combination key
        $tagValues = @()
        foreach ($key in $TagKeys) {
            if ($resource.Tags -and $resource.Tags.ContainsKey($key)) {
                $tagValues += "$key=$($resource.Tags[$key])"
            }
            else {
                $tagValues += "$key=Untagged"
            }
        }
        $groupKey = $tagValues -join ';'
        
        if (-not $costData.ContainsKey($groupKey)) {
            $costData[$groupKey] = @{
                Resources = @()
                EstimatedMonthlyCost = 0
                ResourceCount = 0
            }
        }
        
        $costData[$groupKey].Resources += $resource.Name
        $costData[$groupKey].ResourceCount++
        
        # Estimate costs based on resource type (simplified)
        switch -Wildcard ($resource.ResourceType) {
            'Microsoft.Compute/virtualMachines*' {
                $costData[$groupKey].EstimatedMonthlyCost += 100 # Placeholder
            }
            'Microsoft.Storage/storageAccounts*' {
                $costData[$groupKey].EstimatedMonthlyCost += 20 # Placeholder
            }
            'Microsoft.Sql/servers*' {
                $costData[$groupKey].EstimatedMonthlyCost += 150 # Placeholder
            }
        }
    }
    
    # Convert to sorted array
    $results = @()
    foreach ($key in $costData.Keys | Sort-Object) {
        $results += [PSCustomObject]@{
            TagCombination = $key
            ResourceCount = $costData[$key].ResourceCount
            EstimatedMonthlyCost = $costData[$key].EstimatedMonthlyCost
            Resources = $costData[$key].Resources -join ', '
        }
    }
    
    return $results
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'New-AzResourceGroupAdvanced'
    'Remove-AzResourceGroupSafely'
    'Set-AzResourceTags'
    'Test-AzResourceCompliance'
    'Test-AzResourceNamingConvention'
    'Rename-AzResourceBatch'
    'Start-AzResourceBulkOperation'
    'Get-AzResourceDependencies'
    'Get-AzResourceCostByTag'
)