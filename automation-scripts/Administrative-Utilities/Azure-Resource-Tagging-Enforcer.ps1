#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Enforce resource tagging compliance

.DESCRIPTION
    Audit, enforce, or fix Azure resource tag compliance across subscriptions and resource groups
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Resource Tagging Enforcer
#
[CmdletBinding()]

    [Parameter()]
    [string]$SubscriptionId,
    [Parameter()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [hashtable]$RequiredTags = @{
        'Environment' = @('Development', 'Testing', 'Staging', 'Production')
        'Owner' = @()  # Any value allowed
        'CostCenter' = @()
        'Project' = @()
    },
    [Parameter()]
    [hashtable]$DefaultTags = @{
        'ManagedBy' = 'Azure-Automation'
        'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
    },
    [Parameter()]
    [ValidateSet("Audit", "Enforce", "Fix")]
    [string]$Action = "Audit",
    [Parameter()]
    [switch]$IncludeResourceGroups,
    [Parameter()]
    [string]$OutputPath = ".\tag-compliance-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)
$nonCompliantResources = @()
try {
        if (-not (Get-AzContext)) { Connect-AzAccount }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
        $resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzResource
    }
    if ($IncludeResourceGroups) {
        $resourceGroups = if ($ResourceGroupName) {
            Get-AzResourceGroup -Name $ResourceGroupName
        } else {
            Get-AzResourceGroup
        }
        $resources += $resourceGroups
    }
    
        foreach ($resource in $resources) {
        $missingTags = @()
        $invalidTags = @()
        foreach ($requiredTag in $RequiredTags.Keys) {
            if (-not $resource.Tags -or -not $resource.Tags.ContainsKey($requiredTag)) {
                $missingTags += $requiredTag
            } elseif ($RequiredTags[$requiredTag].Count -gt 0) {
                # Check if value is in allowed list
                if ($resource.Tags[$requiredTag] -notin $RequiredTags[$requiredTag]) {
                    $invalidTags += "$requiredTag=$($resource.Tags[$requiredTag])"
                }
            }
        }
        if ($missingTags.Count -gt 0 -or $invalidTags.Count -gt 0) {
            $nonCompliantResources += [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                ResourceGroup = $resource.ResourceGroupName
                Location = $resource.Location
                MissingTags = ($missingTags -join ', ')
                InvalidTags = ($invalidTags -join ', ')
                CurrentTags = if ($resource.Tags) { ($resource.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; ' } else { "None" }
                ComplianceStatus = "Non-Compliant"
            }
        }
    }
        switch ($Action) {
        "Audit" {
            Write-Host "Audit completed. Found $($nonCompliantResources.Count) non-compliant resources." -ForegroundColor Yellow
        }
        "Fix" {
            
            foreach ($resource in $nonCompliantResources) {
                try {
                    $resourceObj = Get-AzResource -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup
                    $newTags = if ($resourceObj.Tags) { $resourceObj.Tags.Clone() } else { @{} }
                    # Add missing required tags with default values
                    foreach ($missingTag in ($resource.MissingTags -split ', ')) {
                        if ($missingTag -and $DefaultTags.ContainsKey($missingTag)) {
                            $newTags[$missingTag] = $DefaultTags[$missingTag]
                        } elseif ($missingTag) {
                            $newTags[$missingTag] = "Unknown"
                        }
                    }
                    # Add default tags
                    foreach ($defaultTag in $DefaultTags.Keys) {
                        if (-not $newTags.ContainsKey($defaultTag)) {
                            $newTags[$defaultTag] = $DefaultTags[$defaultTag]
                        }
                    }
                    Set-AzResource -ResourceId $resourceObj.ResourceId -Tag $newTags -Force
                    Write-Host "Successfully updated tags for $($resource.ResourceName)" -ForegroundColor Green
                } catch {
                    Write-Warning "Failed to update tags for $($resource.ResourceName): $($_.Exception.Message)"
                }
            }
        }
    }
        $nonCompliantResources | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    
        # Success summary
    Write-Host ""
    Write-Host "                              TAG COMPLIANCE ANALYSIS COMPLETE"
    Write-Host ""
    Write-Host "Compliance Summary:"
    Write-Host "    Total Resources: $($resources.Count)"
    Write-Host "    Non-Compliant: $($nonCompliantResources.Count)"
    Write-Host "    Compliance Rate: $([math]::Round((($resources.Count - $nonCompliantResources.Count) / $resources.Count) * 100, 2))%"
    Write-Host ""
    Write-Host "Required Tags:"
    foreach ($tag in $RequiredTags.Keys) {
        $allowedValues = if ($RequiredTags[$tag].Count -gt 0) { "($($RequiredTags[$tag] -join ', '))" } else { "(any value)" }
        Write-Host "    $tag $allowedValues"
    }
    Write-Host ""
    Write-Host ""
    
} catch { throw }

