#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Resource Tagging Enforcer

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
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
    [ValidateSet("Audit" , "Enforce" , "Fix" )]
    [string]$Action = "Audit" ,
    [Parameter()]
    [switch]$IncludeResourceGroups,
    [Parameter(ValueFromPipeline)]`n    [string]$OutputPath = " .\tag-compliance-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)
Write-Host "Script Started" -ForegroundColor Green
$nonCompliantResources = @()
try {
    # Progress stepNumber 1 -TotalSteps 6 -StepName "Azure Connection" -Status "Validating connection"
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    }
    # Progress stepNumber 2 -TotalSteps 6 -StepName "Resource Discovery" -Status "Gathering resources"
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
        $resources = $resources + $resourceGroups
    }

    # Progress stepNumber 3 -TotalSteps 6 -StepName "Tag Analysis" -Status "Analyzing tag compliance"
    foreach ($resource in $resources) {
        $missingTags = @()
        $invalidTags = @()
        foreach ($requiredTag in $RequiredTags.Keys) {
            if (-not $resource.Tags -or -not $resource.Tags.ContainsKey($requiredTag)) {
                $missingTags = $missingTags + $requiredTag
            } elseif ($RequiredTags[$requiredTag].Count -gt 0) {
                # Check if value is in allowed list
                if ($resource.Tags[$requiredTag] -notin $RequiredTags[$requiredTag]) {
$invalidTags = $invalidTags + " ;  $requiredTag=$($resource.Tags[$requiredTag])"
                }
            }
        }
        if ($missingTags.Count -gt 0 -or $invalidTags.Count -gt 0) {
$nonCompliantResources = $nonCompliantResources + [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                ResourceGroup = $resource.ResourceGroupName
                Location = $resource.Location
                MissingTags = ($missingTags -join ', ')
                InvalidTags = ($invalidTags -join ', ')
                CurrentTags = if ($resource.Tags) { ($resource.Tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join '; ' } else { "None" }
                ComplianceStatus = "Non-Compliant"
            }
        }
    }
    # Progress stepNumber 4 -TotalSteps 6 -StepName "Compliance Action" -Status "Executing $Action action"
    switch ($Action) {
        "Audit" {

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

                } catch {

                }
            }
        }
    }
    # Progress stepNumber 5 -TotalSteps 6 -StepName "Report Generation" -Status "Generating compliance report"
    $nonCompliantResources | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    # Progress stepNumber 6 -TotalSteps 6 -StepName "Summary" -Status "Generating summary"
    # Success summary
    Write-Host ""
    Write-Host "                              TAG COMPLIANCE ANALYSIS COMPLETE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Compliance Summary:" -ForegroundColor Cyan
    Write-Host "    Total Resources: $($resources.Count)" -ForegroundColor White
    Write-Host "    Non-Compliant: $($nonCompliantResources.Count)" -ForegroundColor Yellow
    Write-Host "    Compliance Rate: $([math]::Round((($resources.Count - $nonCompliantResources.Count) / $resources.Count) * 100, 2))%" -ForegroundColor Green
    Write-Host ""
    Write-Host "Required Tags:" -ForegroundColor Cyan
    foreach ($tag in $RequiredTags.Keys) {
$allowedValues = if ($RequiredTags[$tag].Count -gt 0) { " ($($RequiredTags[$tag] -join ', '))" } else { " (any value)" }
        Write-Host "    $tag $allowedValues" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Report: $OutputPath" -ForegroundColor Cyan
    Write-Host ""

} catch { throw }


