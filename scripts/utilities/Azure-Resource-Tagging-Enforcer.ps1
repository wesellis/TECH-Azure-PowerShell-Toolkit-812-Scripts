#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Enforce resource tagging compliance

.DESCRIPTION
    Audit, enforce, or fix Azure resource tag compliance across subscriptions and resource groups
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter()]
    $SubscriptionId,
    [Parameter()]
    $ResourceGroupName,
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
    $Action = "Audit",
    [Parameter()]
    [switch]$IncludeResourceGroups,
    [Parameter()]
    $OutputPath = ".\tag-compliance-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)
$NonCompliantResources = @()
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
        $ResourceGroups = if ($ResourceGroupName) {
            Get-AzResourceGroup -Name $ResourceGroupName
        } else {
            Get-AzResourceGroup
        }
        $resources += $ResourceGroups
    }

        foreach ($resource in $resources) {
        $MissingTags = @()
        $InvalidTags = @()
        foreach ($RequiredTag in $RequiredTags.Keys) {
            if (-not $resource.Tags -or -not $resource.Tags.ContainsKey($RequiredTag)) {
                $MissingTags += $RequiredTag
            } elseif ($RequiredTags[$RequiredTag].Count -gt 0) {
                if ($resource.Tags[$RequiredTag] -notin $RequiredTags[$RequiredTag]) {
                    $InvalidTags += "$RequiredTag=$($resource.Tags[$RequiredTag])"
                }
            }
        }
        if ($MissingTags.Count -gt 0 -or $InvalidTags.Count -gt 0) {
            $NonCompliantResources += [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                ResourceGroup = $resource.ResourceGroupName
                Location = $resource.Location
                MissingTags = ($MissingTags -join ', ')
                InvalidTags = ($InvalidTags -join ', ')
                CurrentTags = if ($resource.Tags) { ($resource.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; ' } else { "None" }
                ComplianceStatus = "Non-Compliant"
            }
        }
    }
        switch ($Action) {
        "Audit" {
            Write-Output "Audit completed. Found $($NonCompliantResources.Count) non-compliant resources." # Color: $2
        }
        "Fix" {

            foreach ($resource in $NonCompliantResources) {
                try {
                    $ResourceObj = Get-AzResource -Name $resource.ResourceName -ResourceGroupName $resource.ResourceGroup
                    $NewTags = if ($ResourceObj.Tags) { $ResourceObj.Tags.Clone() } else { @{} }
                    foreach ($MissingTag in ($resource.MissingTags -split ', ')) {
                        if ($MissingTag -and $DefaultTags.ContainsKey($MissingTag)) {
                            $NewTags[$MissingTag] = $DefaultTags[$MissingTag]
                        } elseif ($MissingTag) {
                            $NewTags[$MissingTag] = "Unknown"
                        }
                    }
                    foreach ($DefaultTag in $DefaultTags.Keys) {
                        if (-not $NewTags.ContainsKey($DefaultTag)) {
                            $NewTags[$DefaultTag] = $DefaultTags[$DefaultTag]
                        }
                    }
                    Set-AzResource -ResourceId $ResourceObj.ResourceId -Tag $NewTags -Force
                    Write-Output "Successfully updated tags for $($resource.ResourceName)" # Color: $2
                } catch {
                    Write-Warning "Failed to update tags for $($resource.ResourceName): $($_.Exception.Message)"
                }
            }
        }
    }
        $NonCompliantResources | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Output ""
    Write-Output "                              TAG COMPLIANCE ANALYSIS COMPLETE"
    Write-Output ""
    Write-Output "Compliance Summary:"
    Write-Output "    Total Resources: $($resources.Count)"
    Write-Output "    Non-Compliant: $($NonCompliantResources.Count)"
    Write-Output "    Compliance Rate: $([math]::Round((($resources.Count - $NonCompliantResources.Count) / $resources.Count) * 100, 2))%"
    Write-Output ""
    Write-Output "Required Tags:"
    foreach ($tag in $RequiredTags.Keys) {
        $AllowedValues = if ($RequiredTags[$tag].Count -gt 0) { "($($RequiredTags[$tag] -join ', '))" } else { "(any value)" }
        Write-Output "    $tag $AllowedValues"
    }
    Write-Output ""
    Write-Output ""

} catch { throw`n}
