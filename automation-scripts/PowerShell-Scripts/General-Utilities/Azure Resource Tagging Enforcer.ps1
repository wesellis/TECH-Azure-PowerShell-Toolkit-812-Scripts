#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Resource Tagging Enforcer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Resource Tagging Enforcer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$WERequiredTags = @{
        'Environment' = @('Development', 'Testing', 'Staging', 'Production')
        'Owner' = @()  # Any value allowed
        'CostCenter' = @()
        'Project' = @()
    },
    
    [Parameter(Mandatory=$false)]
    [hashtable]$WEDefaultTags = @{
        'ManagedBy' = 'Azure-Automation'
        'CreatedDate' = (Get-Date -Format 'yyyy-MM-dd')
    },
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Audit" , " Enforce" , " Fix" )]
    [string]$WEAction = " Audit" ,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEIncludeResourceGroups,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOutputPath = " .\tag-compliance-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)

#region Functions


# Module import removed - use #Requires instead

Show-Banner -ScriptName " Azure Resource Tagging Enforcer" -Version " 1.0" -Description " Enforce consistent resource tagging for governance and compliance"

$nonCompliantResources = @()

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 6 -StepName " Azure Connection" -Status " Validating connection"
    if (-not (Test-AzureConnection)) {
        throw " Azure connection validation failed"
    }

    if ($WESubscriptionId) {
        Set-AzContext -SubscriptionId $WESubscriptionId
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 6 -StepName " Resource Discovery" -Status " Gathering resources"
    
    $resources = if ($WEResourceGroupName) {
        Get-AzResource -ResourceGroupName $WEResourceGroupName
    } else {
        Get-AzResource -ErrorAction Stop
    }
    
    if ($WEIncludeResourceGroups) {
        $resourceGroups = if ($WEResourceGroupName) {
            Get-AzResourceGroup -Name $WEResourceGroupName
        } else {
            Get-AzResourceGroup -ErrorAction Stop
        }
        $resources = $resources + $resourceGroups
    }
    
    Write-Log " Found $($resources.Count) resources to analyze" -Level INFO

    Write-ProgressStep -StepNumber 3 -TotalSteps 6 -StepName " Tag Analysis" -Status " Analyzing tag compliance"
    
    foreach ($resource in $resources) {
        $missingTags = @()
        $invalidTags = @()
        
        foreach ($requiredTag in $WERequiredTags.Keys) {
            if (-not $resource.Tags -or -not $resource.Tags.ContainsKey($requiredTag)) {
                $missingTags = $missingTags + $requiredTag
            } elseif ($WERequiredTags[$requiredTag].Count -gt 0) {
                # Check if value is in allowed list
                if ($resource.Tags[$requiredTag] -notin $WERequiredTags[$requiredTag]) {
                   ;  $invalidTags = $invalidTags + " ;  $requiredTag=$($resource.Tags[$requiredTag])"
                }
            }
        }
        
        if ($missingTags.Count -gt 0 -or $invalidTags.Count -gt 0) {
           ;  $nonCompliantResources = $nonCompliantResources + [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                ResourceGroup = $resource.ResourceGroupName
                Location = $resource.Location
                MissingTags = ($missingTags -join ', ')
                InvalidTags = ($invalidTags -join ', ')
                CurrentTags = if ($resource.Tags) { ($resource.Tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join '; ' } else { " None" }
                ComplianceStatus = " Non-Compliant"
            }
        }
    }

    Write-ProgressStep -StepNumber 4 -TotalSteps 6 -StepName " Compliance Action" -Status " Executing $WEAction action"
    
    switch ($WEAction) {
        " Audit" {
            Write-Log " 📋 Audit complete - found $($nonCompliantResources.Count) non-compliant resources" -Level INFO
        }
        
        " Fix" {
            Write-Log "  Fixing tag compliance..." -Level WARNING
            
            foreach ($resource in $nonCompliantResources) {
                try {
                    $resourceObj = Get-AzResource -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup
                   ;  $newTags = if ($resourceObj.Tags) { $resourceObj.Tags.Clone() } else { @{} }
                    
                    # Add missing required tags with default values
                    foreach ($missingTag in ($resource.MissingTags -split ', ')) {
                        if ($missingTag -and $WEDefaultTags.ContainsKey($missingTag)) {
                            $newTags[$missingTag] = $WEDefaultTags[$missingTag]
                        } elseif ($missingTag) {
                            $newTags[$missingTag] = " Unknown"
                        }
                    }
                    
                    # Add default tags
                    foreach ($defaultTag in $WEDefaultTags.Keys) {
                        if (-not $newTags.ContainsKey($defaultTag)) {
                            $newTags[$defaultTag] = $WEDefaultTags[$defaultTag]
                        }
                    }
                    
                    Set-AzResource -ResourceId $resourceObj.ResourceId -Tag $newTags -Force
                    Write-Log " [OK] Fixed tags for $($resource.ResourceName)" -Level SUCCESS
                    
                } catch {
                    Write-Log "  Failed to fix tags for $($resource.ResourceName): $($_.Exception.Message)" -Level ERROR
                }
            }
        }
    }

    Write-ProgressStep -StepNumber 5 -TotalSteps 6 -StepName " Report Generation" -Status " Generating compliance report"
    
    $nonCompliantResources | Export-Csv -Path $WEOutputPath -NoTypeInformation -Encoding UTF8
    Write-Log " [OK] Tag compliance report saved to: $WEOutputPath" -Level SUCCESS

    Write-ProgressStep -StepNumber 6 -TotalSteps 6 -StepName " Summary" -Status " Generating summary"

    # Success summary
    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                              TAG COMPLIANCE ANALYSIS COMPLETE" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    Write-WELog "  Compliance Summary:" " INFO" -ForegroundColor Cyan
    Write-WELog "   • Total Resources: $($resources.Count)" " INFO" -ForegroundColor White
    Write-WELog "   • Non-Compliant: $($nonCompliantResources.Count)" " INFO" -ForegroundColor Yellow
    Write-WELog "   • Compliance Rate: $([math]::Round((($resources.Count - $nonCompliantResources.Count) / $resources.Count) * 100, 2))%" " INFO" -ForegroundColor Green
    
    Write-WELog "" " INFO"
    Write-WELog " 🏷️ Required Tags:" " INFO" -ForegroundColor Cyan
    foreach ($tag in $WERequiredTags.Keys) {
       ;  $allowedValues = if ($WERequiredTags[$tag].Count -gt 0) { " ($($WERequiredTags[$tag] -join ', '))" } else { " (any value)" }
        Write-WELog "   • $tag $allowedValues" " INFO" -ForegroundColor White
    }
    
    Write-WELog "" " INFO"
    Write-WELog " 📋 Report: $WEOutputPath" " INFO" -ForegroundColor Cyan
    Write-WELog "" " INFO"

    Write-Log "  Tag compliance analysis completed successfully!" -Level SUCCESS

} catch {
    Write-Log "  Tag compliance analysis failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity " Tag Compliance Analysis" -Completed


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
