#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Azure Resource Tagging Enforcer
# Professional Azure utility script for enforcing consistent resource tagging
# Version: 1.0 | Enterprise tag governance and compliance

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$RequiredTags = @{
        'Environment' = @('Development', 'Testing', 'Staging', 'Production')
        'Owner' = @()  # Any value allowed
        'CostCenter' = @()
        'Project' = @()
    },
    
    [Parameter(Mandatory=$false)]
    [hashtable]$DefaultTags = @{
        'ManagedBy' = 'Azure-Automation'
        'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
    },
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Audit", "Enforce", "Fix")]
    [string]$Action = "Audit",
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeResourceGroups,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\tag-compliance-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

#region Functions

# Import common functions
# Module import removed - use #Requires instead

Show-Banner -ScriptName "Azure Resource Tagging Enforcer" -Version "1.0" -Description "Enforce consistent resource tagging for governance and compliance"

$nonCompliantResources = @()

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 6 -StepName "Azure Connection" -Status "Validating connection"
    if (-not (Test-AzureConnection)) {
        throw "Azure connection validation failed"
    }

    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 6 -StepName "Resource Discovery" -Status "Gathering resources"
    
    $resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzResource -ErrorAction Stop
    }
    
    if ($IncludeResourceGroups) {
        $resourceGroups = if ($ResourceGroupName) {
            Get-AzResourceGroup -Name $ResourceGroupName
        } else {
            Get-AzResourceGroup -ErrorAction Stop
        }
        $resources += $resourceGroups
    }
    
    Write-Log "Found $($resources.Count) resources to analyze" -Level INFO

    Write-ProgressStep -StepNumber 3 -TotalSteps 6 -StepName "Tag Analysis" -Status "Analyzing tag compliance"
    
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

    Write-ProgressStep -StepNumber 4 -TotalSteps 6 -StepName "Compliance Action" -Status "Executing $Action action"
    
    switch ($Action) {
        "Audit" {
            Write-Log "📋 Audit complete - found $($nonCompliantResources.Count) non-compliant resources" -Level INFO
        }
        
        "Fix" {
            Write-Log " Fixing tag compliance..." -Level WARNING
            
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
                    Write-Log "[OK] Fixed tags for $($resource.ResourceName)" -Level SUCCESS
                    
                } catch {
                    Write-Log " Failed to fix tags for $($resource.ResourceName): $($_.Exception.Message)" -Level ERROR
                }
            }
        }
    }

    Write-ProgressStep -StepNumber 5 -TotalSteps 6 -StepName "Report Generation" -Status "Generating compliance report"
    
    $nonCompliantResources | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Log "[OK] Tag compliance report saved to: $OutputPath" -Level SUCCESS

    Write-ProgressStep -StepNumber 6 -TotalSteps 6 -StepName "Summary" -Status "Generating summary"

    # Success summary
    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                              TAG COMPLIANCE ANALYSIS COMPLETE"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    Write-Information " Compliance Summary:"
    Write-Information "   • Total Resources: $($resources.Count)"
    Write-Information "   • Non-Compliant: $($nonCompliantResources.Count)"
    Write-Information "   • Compliance Rate: $([math]::Round((($resources.Count - $nonCompliantResources.Count) / $resources.Count) * 100, 2))%"
    
    Write-Information ""
    Write-Information "🏷 Required Tags:"
    foreach ($tag in $RequiredTags.Keys) {
        $allowedValues = if ($RequiredTags[$tag].Count -gt 0) { "($($RequiredTags[$tag] -join ', '))" } else { "(any value)" }
        Write-Information "   • $tag $allowedValues"
    }
    
    Write-Information ""
    Write-Information "� Report: $OutputPath"
    Write-Information ""

    Write-Log " Tag compliance analysis completed successfully!" -Level SUCCESS

} catch {
    Write-Log " Tag compliance analysis failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity "Tag Compliance Analysis" -Completed

#endregion
