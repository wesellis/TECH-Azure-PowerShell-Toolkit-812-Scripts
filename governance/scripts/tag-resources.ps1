#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Manages and enforces resource tagging across subscriptions and resource groups

.DESCRIPTION
    on resources. Supports bulk operations, tag inheritance, compliance reporting,
    and automated remediation of missing or incorrect tags.
.PARAMETER Action
    Action to perform: Apply, Remove, Validate, Report, Inherit, Fix
.PARAMETER Scope
    Scope for tag operations (subscription, resource group, or specific resource)
.PARAMETER Tags
    Hashtable of tags to apply or validate
.PARAMETER RequiredTags
    Array of tag names that must be present on all resources
.PARAMETER ResourceType
    Filter operations to specific resource types
.PARAMETER ResourceGroup
    Target specific resource group(s)
.PARAMETER InheritFromResourceGroup
    Inherit tags from resource group to child resources
.PARAMETER RemoveUnauthorized
    Remove tags not in the approved list
.PARAMETER ExportPath
    Path for compliance report export
.PARAMETER Force
    Skip confirmation prompts
.EXAMPLE
    .\tag-resources.ps1 -Action Apply -Tags @{Environment='Production';Owner='TeamA'} -ResourceGroup "RG-Prod"

    Applies tags to all resources in the resource group
.EXAMPLE
    .\tag-resources.ps1 -Action Validate -RequiredTags @('Environment','CostCenter','Owner')

    Validates that all resources have required tags
.EXAMPLE
    .\tag-resources.ps1 -Action Inherit -InheritFromResourceGroup

    Inherits resource group tags to all child resources
.NOTES
    Author: Azure PowerShell Toolkit#>

[CmdletBinding(SupportsShouldProcess = $true)]
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory = $true)]
    [ValidateSet('Apply', 'Remove', 'Validate', 'Report', 'Inherit', 'Fix')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$Scope,

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags,

    [Parameter(Mandatory = $false)]
    [string[]]$RequiredTags,

    [Parameter(Mandatory = $false)]
    [string[]]$ResourceType,

    [Parameter(Mandatory = $false)]
    [string[]]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [switch]$InheritFromResourceGroup,

    [Parameter(Mandatory = $false)]
    [switch]$RemoveUnauthorized,

    [Parameter(Mandatory = $false)]
    [string[]]$AuthorizedTags,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeResourceGroups,

    [Parameter(Mandatory = $false)]
    [hashtable]$DefaultValues
)

#region Initialize
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $ExportPath) {
    $ExportPath = ".\TagCompliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
}

$script:LogPath = ".\TagOperations_$(Get-Date -Format 'yyyyMMdd').log"
$script:ModifiedResources = @()

#endregion

#region Functions
[OutputType([bool])]
 {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp [$Level] $Message"
    Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue

    switch ($Level) {
        'Info'    { Write-Verbose $Message }
        'Warning' { Write-Warning $Message }
        'Error'   { Write-Error $Message }
        'Success' { Write-Host $Message -ForegroundColor Green }
    }
}

function Initialize-Azure {
    $context = Get-AzContext
    if (-not $context) {
        Write-LogEntry "Connecting to Azure..." -Level Warning
        Connect-AzAccount
        $context = Get-AzContext
    }
    return $context
}

function Get-ScopedResources {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$Scope,
        [string[]]$ResourceGroups,
        [string[]]$ResourceTypes
    )

    $resources = @()

    if ($Scope) {
        if ($Scope -match '^/subscriptions/.+/resourceGroups/[^/]+$') {
            # Resource group scope
            $rgName = $Scope.Split('/')[-1]
            $resources = Get-AzResource -ResourceGroupName $rgName
        }
        elseif ($Scope -match '^/subscriptions/[^/]+$') {
            # Subscription scope
            $resources = Get-AzResource
        }
        else {
            # Specific resource
            $resources = @(Get-AzResource -ResourceId $Scope)
        }
    }
    elseif ($ResourceGroups) {
        foreach ($rg in $ResourceGroups) {
            $resources += Get-AzResource -ResourceGroupName $rg
        }
    }
    else {
        $resources = Get-AzResource
    }

    # Filter by resource type if specified
    if ($ResourceTypes) {
        $resources = $resources | Where-Object {
            $_.ResourceType -in $ResourceTypes
        }
    }

    # Include resource groups if requested
    if ($IncludeResourceGroups) {
        $rgs = if ($ResourceGroups) {
            $ResourceGroups | ForEach-Object { Get-AzResourceGroup -Name $_ }
        } else {
            Get-AzResourceGroup
        }

        foreach ($rg in $rgs) {
            $resources += [PSCustomObject]@{
                ResourceId = $rg.ResourceId
                Name = $rg.ResourceGroupName
                ResourceType = 'Microsoft.Resources/resourceGroups'
                ResourceGroupName = $rg.ResourceGroupName
                Location = $rg.Location
                Tags = $rg.Tags
            }
        }
    }

    return $resources
}

function Apply-ResourceTags {
    [CmdletBinding(SupportsShouldProcess)]

        [object]$Resource,
        [hashtable]$TagsToApply,
        [switch]$Merge
    )

    try {
        $currentTags = if ($Resource.Tags) { $Resource.Tags } else { @{} }

        if ($Merge) {
            # Merge with existing tags
            foreach ($key in $TagsToApply.Keys) {
                $currentTags[$key] = $TagsToApply[$key]
            }
            $finalTags = $currentTags
        }
        else {
            # Replace all tags
            $finalTags = $TagsToApply
        }

        if ($PSCmdlet.ShouldProcess($Resource.Name, "Apply tags")) {
            if ($Resource.ResourceType -eq 'Microsoft.Resources/resourceGroups') {
                Set-AzResourceGroup -Name $Resource.Name -Tag $finalTags | Out-Null
            }
            else {
                Set-AzResource -ResourceId $Resource.ResourceId -Tag $finalTags -Force | Out-Null
            }

            $script:ModifiedResources += [PSCustomObject]@{
                ResourceId = $Resource.ResourceId
                Name = $Resource.Name
                Action = 'TagsApplied'
                Tags = $finalTags
                Timestamp = Get-Date
            }

            Write-LogEntry "Applied tags to: $($Resource.Name)" -Level Success
            return $true
        
} catch {
        Write-LogEntry "Failed to apply tags to $($Resource.Name): $_" -Level Error
        return $false
    }
}

function Remove-ResourceTags {
    [CmdletBinding(SupportsShouldProcess)]

        [object]$Resource,
        [string[]]$TagsToRemove
    )

    try {
        $currentTags = if ($Resource.Tags) { $Resource.Tags.Clone() } else { @{} }

        foreach ($tagName in $TagsToRemove) {
            if ($currentTags.ContainsKey($tagName)) {
                $currentTags.Remove($tagName)
            }
        }

        if ($PSCmdlet.ShouldProcess($Resource.Name, "Remove tags")) {
            if ($Resource.ResourceType -eq 'Microsoft.Resources/resourceGroups') {
                Set-AzResourceGroup -Name $Resource.Name -Tag $currentTags | Out-Null
            }
            else {
                Set-AzResource -ResourceId $Resource.ResourceId -Tag $currentTags -Force | Out-Null
            }

            Write-LogEntry "Removed tags from: $($Resource.Name)" -Level Success
            return $true
        
} catch {
        Write-LogEntry "Failed to remove tags from $($Resource.Name): $_" -Level Error
        return $false
    }
}

function Test-TagCompliance {
    [CmdletBinding(SupportsShouldProcess)]

        [object]$Resource,
        [string[]]$RequiredTagNames,
        [hashtable]$RequiredTagValues
    )

    $compliance = @{
        IsCompliant = $true
        MissingTags = @()
        IncorrectValues = @()
        UnauthorizedTags = @()
    }

    $currentTags = if ($Resource.Tags) { $Resource.Tags } else { @{} }

    # Check required tags
    foreach ($tagName in $RequiredTagNames) {
        if (-not $currentTags.ContainsKey($tagName)) {
            $compliance.MissingTags += $tagName
            $compliance.IsCompliant = $false
        }
        elseif ($RequiredTagValues -and $RequiredTagValues.ContainsKey($tagName)) {
            $expectedValue = $RequiredTagValues[$tagName]
            if ($currentTags[$tagName] -ne $expectedValue) {
                $compliance.IncorrectValues += @{
                    Tag = $tagName
                    Current = $currentTags[$tagName]
                    Expected = $expectedValue
                }
                $compliance.IsCompliant = $false
            }
        }
    }

    # Check for unauthorized tags
    if ($AuthorizedTags) {
        foreach ($tagName in $currentTags.Keys) {
            if ($tagName -notin $AuthorizedTags) {
                $compliance.UnauthorizedTags += $tagName
                $compliance.IsCompliant = $false
            }
        }
    }

    return $compliance
}

function Export-ComplianceReport {
    [CmdletBinding(SupportsShouldProcess)]

        [array]$ComplianceData,
        [string]$Path
    )

    $report = @()

    foreach ($item in $ComplianceData) {
        $report += [PSCustomObject]@{
            ResourceId = $item.Resource.ResourceId
            ResourceName = $item.Resource.Name
            ResourceType = $item.Resource.ResourceType
            ResourceGroup = $item.Resource.ResourceGroupName
            IsCompliant = $item.Compliance.IsCompliant
            MissingTags = ($item.Compliance.MissingTags -join ';')
            IncorrectValues = ($item.Compliance.IncorrectValues | ForEach-Object { "$($_.Tag)=$($_.Current)" }) -join ';'
            UnauthorizedTags = ($item.Compliance.UnauthorizedTags -join ';')
            CurrentTags = ($item.Resource.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';'
        }
    }

    $report | Export-Csv -Path $Path -NoTypeInformation
    Write-LogEntry "Compliance report exported to: $Path" -Level Success
}

function Invoke-TagInheritance {
    [CmdletBinding(SupportsShouldProcess)]

        [object]$ResourceGroup,
        [object[]]$Resources
    )

    $rgTags = if ($ResourceGroup.Tags) { $ResourceGroup.Tags } else { @{} }

    if ($rgTags.Count -eq 0) {
        Write-LogEntry "Resource group $($ResourceGroup.ResourceGroupName) has no tags to inherit" -Level Warning
        return
    }

    $inheritedCount = 0

    foreach ($resource in $Resources) {
        if ($resource.ResourceGroupName -eq $ResourceGroup.ResourceGroupName) {
            if (Apply-ResourceTags -Resource $resource -TagsToApply $rgTags -Merge) {
                $inheritedCount++
            }
        }
    }

    Write-LogEntry "Inherited tags to $inheritedCount resources in $($ResourceGroup.ResourceGroupName)" -Level Success
}

#endregion

#region Main-try {
    Write-Host "`nResource Tagging Management" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan

    # Initialize Azure connection
    $context = Initialize-Azure
    Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Yellow

    # Get resources in scope
    Write-Host "`nGathering resources..." -ForegroundColor Yellow
    $resources = Get-ScopedResources -Scope $Scope -ResourceGroups $ResourceGroup -ResourceTypes $ResourceType

    Write-Host "Found $($resources.Count) resources" -ForegroundColor Green

    switch ($Action) {
        'Apply' {
            if (-not $Tags) {
                throw "Tags parameter is required for Apply action"
            }

            Write-Host "`nApplying tags to resources..." -ForegroundColor Yellow
            $successCount = 0

            foreach ($resource in $resources) {
                if (Apply-ResourceTags -Resource $resource -TagsToApply $Tags -Merge) {
                    $successCount++
                }

                $params = @{
                    Status = "$successCount of $($resources.Count)"
                    PercentComplete = (($successCount / $resources.Count) * 100)
                    Activity = "Applying tags"
                }
                Write-Progress @params
            }

            Write-Host "Successfully tagged $successCount resources" -ForegroundColor Green
        }

        'Remove' {
            if (-not $Tags -and -not $RemoveUnauthorized) {
                throw "Specify tags to remove or use -RemoveUnauthorized"
            }

            Write-Host "`nRemoving tags from resources..." -ForegroundColor Yellow
            $tagsToRemove = if ($Tags) { $Tags.Keys } else { @() }

            foreach ($resource in $resources) {
                if ($RemoveUnauthorized -and $AuthorizedTags) {
                    $currentTags = if ($resource.Tags) { $resource.Tags.Keys } else { @() }
                    $unauthorizedTags = $currentTags | Where-Object { $_ -notin $AuthorizedTags }
                    if ($unauthorizedTags) {
                        Remove-ResourceTags -Resource $resource -TagsToRemove $unauthorizedTags
                    }
                }
                elseif ($tagsToRemove) {
                    Remove-ResourceTags -Resource $resource -TagsToRemove $tagsToRemove
                }
            }
        }

        'Validate' {
            Write-Host "`nValidating tag compliance..." -ForegroundColor Yellow
            $complianceData = @()
            $compliantCount = 0

            foreach ($resource in $resources) {
                $params = @{
                    Resource = $resource
                    RequiredTagNames = $RequiredTags
                    RequiredTagValues = $DefaultValues
                }
                $compliance = Test-TagCompliance @params

                $complianceData += @{
                    Resource = $resource
                    Compliance = $compliance
                }

                if ($compliance.IsCompliant) {
                    $compliantCount++
                }
            }

            $complianceRate = if ($resources.Count -gt 0) {
                [Math]::Round(($compliantCount / $resources.Count) * 100, 2)
            } else { 0 }

            Write-Host "`nCompliance Summary:" -ForegroundColor Cyan
            Write-Host "Total Resources: $($resources.Count)" -ForegroundColor White
            Write-Host "Compliant: $compliantCount" -ForegroundColor Green
            Write-Host "Non-Compliant: $($resources.Count - $compliantCount)" -ForegroundColor Red
            Write-Host "Compliance Rate: $complianceRate%" -ForegroundColor $(
                if ($complianceRate -ge 90) { 'Green' }
                elseif ($complianceRate -ge 70) { 'Yellow' }
                else { 'Red' }
            )

            Export-ComplianceReport -ComplianceData $complianceData -Path $ExportPath
        }

        'Report' {
            Write-Host "`nGenerating tag report..." -ForegroundColor Yellow
            $tagSummary = @{}

            foreach ($resource in $resources) {
                if ($resource.Tags) {
                    foreach ($tag in $resource.Tags.GetEnumerator()) {
                        if (-not $tagSummary.ContainsKey($tag.Key)) {
                            $tagSummary[$tag.Key] = @{
                                Count = 0
                                Values = @{}
                            }
                        }
                        $tagSummary[$tag.Key].Count++

                        if (-not $tagSummary[$tag.Key].Values.ContainsKey($tag.Value)) {
                            $tagSummary[$tag.Key].Values[$tag.Value] = 0
                        }
                        $tagSummary[$tag.Key].Values[$tag.Value]++
                    }
                }
            }

            Write-Host "`nTag Usage Summary:" -ForegroundColor Cyan
            foreach ($tagName in ($tagSummary.Keys | Sort-Object)) {
                Write-Host "  $tagName : $($tagSummary[$tagName].Count) resources" -ForegroundColor White
                $topValues = $tagSummary[$tagName].Values.GetEnumerator() |
                    Sort-Object Value -Descending |
                    Select-Object -First 3
                foreach ($value in $topValues) {
                    Write-Host "    - $($value.Key): $($value.Value)" -ForegroundColor Gray
                }
            }
        }

        'Inherit' {
            if (-not $InheritFromResourceGroup) {
                throw "Use -InheritFromResourceGroup switch for inheritance"
            }

            Write-Host "`nInheriting tags from resource groups..." -ForegroundColor Yellow

            $resourceGroups = if ($ResourceGroup) {
                $ResourceGroup | ForEach-Object { Get-AzResourceGroup -Name $_ }
            } else {
                Get-AzResourceGroup
            }

            foreach ($rg in $resourceGroups) {
                Write-Host "Processing resource group: $($rg.ResourceGroupName)" -ForegroundColor White
                $rgResources = $resources | Where-Object { $_.ResourceGroupName -eq $rg.ResourceGroupName }
                Invoke-TagInheritance -ResourceGroup $rg -Resources $rgResources
            }
        }

        'Fix' {
            Write-Host "`nFixing tag compliance issues..." -ForegroundColor Yellow

            foreach ($resource in $resources) {
                $params = @{
                    Resource = $resource
                    RequiredTagNames = $RequiredTags
                    RequiredTagValues = $DefaultValues
                }
                $compliance = Test-TagCompliance @params

                if (-not $compliance.IsCompliant) {
                    $tagsToApply = @{}

                    # Add missing tags with defaults
                    foreach ($tagName in $compliance.MissingTags) {
                        $tagsToApply[$tagName] = if ($DefaultValues -and $DefaultValues.ContainsKey($tagName)) {
                            $DefaultValues[$tagName]
                        } else {
                            "Unknown"
                        }
                    }

                    # Fix incorrect values
                    foreach ($incorrect in $compliance.IncorrectValues) {
                        $tagsToApply[$incorrect.Tag] = $incorrect.Expected
                    }

                    if ($tagsToApply.Count -gt 0) {
                        Apply-ResourceTags -Resource $resource -TagsToApply $tagsToApply -Merge
                    }

                    # Remove unauthorized tags
                    if ($compliance.UnauthorizedTags -and $RemoveUnauthorized) {
                        Remove-ResourceTags -Resource $resource -TagsToRemove $compliance.UnauthorizedTags
                    }
                }
            }

            Write-Host "Tag remediation completed" -ForegroundColor Green
        }
    }

    # Export modification log
    if ($script:ModifiedResources.Count -gt 0) {
        $logPath = ".\TagModifications_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $script:ModifiedResources | Export-Csv -Path $logPath -NoTypeInformation
        Write-Host "`nModification log saved to: $logPath" -ForegroundColor Cyan
    }

    Write-Host "`nOperation completed successfully!" -ForegroundColor Green
}
catch {
    Write-LogEntry "Operation failed: $_" -Level Error
    Write-Error $_
    throw
}
finally {
    $ProgressPreference = 'Continue'
}

#endregion

