#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Manages and enforces resource tagging across subscriptions and resource groups

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    on resources. Supports bulk operations, tag inheritance, compliance reporting,
    and automated remediation of missing or incorrect tags.
.parameter Action
    Action to perform: Apply, Remove, Validate, Report, Inherit, Fix
.parameter Scope
    Scope for tag operations (subscription, resource group, or specific resource)
.parameter Tags
    Hashtable of tags to apply or validate
.parameter RequiredTags
    Array of tag names that must be present on all resources
.parameter ResourceType
    Filter operations to specific resource types
.parameter ResourceGroup
    Target specific resource group(s)
.parameter InheritFromResourceGroup
    Inherit tags from resource group to child resources
.parameter RemoveUnauthorized
    Remove tags not in the approved list
.parameter ExportPath
    Path for compliance report export
.parameter Force
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
    Author: Azure PowerShell Toolkit

[parameter(Mandatory = $true)]
    [ValidateSet('Apply', 'Remove', 'Validate', 'Report', 'Inherit', 'Fix')]
    [string]$Action,

    [parameter(Mandatory = $false)]
    [string]$Scope,

    [parameter(Mandatory = $false)]
    [hashtable]$Tags,

    [parameter(Mandatory = $false)]
    [string[]]$RequiredTags,

    [parameter(Mandatory = $false)]
    [string[]]$ResourceType,

    [parameter(Mandatory = $false)]
    [string[]]$ResourceGroup,

    [parameter(Mandatory = $false)]
    [switch]$InheritFromResourceGroup,

    [parameter(Mandatory = $false)]
    [switch]$RemoveUnauthorized,

    [parameter(Mandatory = $false)]
    [string[]]$AuthorizedTags,

    [parameter(Mandatory = $false)]
    [string]$ExportPath,

    [parameter(Mandatory = $false)]
    [switch]$Force,

    [parameter(Mandatory = $false)]
    [switch]$IncludeResourceGroups,

    [parameter(Mandatory = $false)]
    [hashtable]$DefaultValues
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $ExportPath) {
    $ExportPath = ".\TagCompliance_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
}

$script:LogPath = ".\TagOperations_$(Get-Date -Format 'yyyyMMdd').log"
$script:ModifiedResources = @()


function Write-Log {
    [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$timestamp [$Level] $Message"
    Add-Content -Path $script:LogPath -Value $LogEntry -ErrorAction SilentlyContinue

    switch ($Level) {
        'Info'    { write-Verbose $Message }
        'Warning' { write-Warning $Message }
        'Error'   { write-Error $Message }
        'Success' { Write-Output $Message -ForegroundColor Green }
    }
}

function Initialize-Azure {
    $context = Get-AzContext
    if (-not $context) {
        write-LogEntry "Connecting to Azure..." -Level Warning
        Connect-AzAccount
        $context = Get-AzContext
    }
    return $context
}

function Get-ScopedResources {
    [string]$Scope,
        [string[]]$ResourceGroups,
        [string[]]$ResourceTypes
    )

    $resources = @()

    if ($Scope) {
        if ($Scope -match '^/subscriptions/.+/resourceGroups/[^/]+$') {
            $RgName = $Scope.Split('/')[-1]
            $resources = Get-AzResource -ResourceGroupName $RgName
        }
        elseif ($Scope -match '^/subscriptions/[^/]+$') {
            $resources = Get-AzResource
        }
        else {
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

    if ($ResourceTypes) {
        $resources = $resources | Where-Object {
            $_.ResourceType -in $ResourceTypes
        }
    }

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
    [object]$Resource,
        [hashtable]$TagsToApply,
        [switch]$Merge
    )

    try {
        $CurrentTags = if ($Resource.Tags) { $Resource.Tags } else { @{} }

        if ($Merge) {
            foreach ($key in $TagsToApply.Keys) {
                $CurrentTags[$key] = $TagsToApply[$key]
            }
            $FinalTags = $CurrentTags
        }
        else {
            $FinalTags = $TagsToApply
        }

        if ($PSCmdlet.ShouldProcess($Resource.Name, "Apply tags")) {
            if ($Resource.ResourceType -eq 'Microsoft.Resources/resourceGroups') {
                Set-AzResourceGroup -Name $Resource.Name -Tag $FinalTags | Out-Null
            }
            else {
                Set-AzResource -ResourceId $Resource.ResourceId -Tag $FinalTags -Force | Out-Null
            }

            $script:ModifiedResources += [PSCustomObject]@{
                ResourceId = $Resource.ResourceId
                Name = $Resource.Name
                Action = 'TagsApplied'
                Tags = $FinalTags
                Timestamp = Get-Date
            }

            write-LogEntry "Applied tags to: $($Resource.Name)" -Level Success
            return $true

} catch {
        write-LogEntry "Failed to apply tags to $($Resource.Name): $_" -Level Error
        return $false
    }
}

function Remove-ResourceTags {
    [object]$Resource,
        [string[]]$TagsToRemove
    )

    try {
        $CurrentTags = if ($Resource.Tags) { $Resource.Tags.Clone() } else { @{} }

        foreach ($TagName in $TagsToRemove) {
            if ($CurrentTags.ContainsKey($TagName)) {
                $CurrentTags.Remove($TagName)
            }
        }

        if ($PSCmdlet.ShouldProcess($Resource.Name, "Remove tags")) {
            if ($Resource.ResourceType -eq 'Microsoft.Resources/resourceGroups') {
                Set-AzResourceGroup -Name $Resource.Name -Tag $CurrentTags | Out-Null
            }
            else {
                Set-AzResource -ResourceId $Resource.ResourceId -Tag $CurrentTags -Force | Out-Null
            }

            write-LogEntry "Removed tags from: $($Resource.Name)" -Level Success
            return $true

} catch {
        write-LogEntry "Failed to remove tags from $($Resource.Name): $_" -Level Error
        return $false
    }
}

function Test-TagCompliance {
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

    $CurrentTags = if ($Resource.Tags) { $Resource.Tags } else { @{} }

    foreach ($TagName in $RequiredTagNames) {
        if (-not $CurrentTags.ContainsKey($TagName)) {
            $compliance.MissingTags += $TagName
            $compliance.IsCompliant = $false
        }
        elseif ($RequiredTagValues -and $RequiredTagValues.ContainsKey($TagName)) {
            $ExpectedValue = $RequiredTagValues[$TagName]
            if ($CurrentTags[$TagName] -ne $ExpectedValue) {
                $compliance.IncorrectValues += @{
                    Tag = $TagName
                    Current = $CurrentTags[$TagName]
                    Expected = $ExpectedValue
                }
                $compliance.IsCompliant = $false
            }
        }
    }

    if ($AuthorizedTags) {
        foreach ($TagName in $CurrentTags.Keys) {
            if ($TagName -notin $AuthorizedTags) {
                $compliance.UnauthorizedTags += $TagName
                $compliance.IsCompliant = $false
            }
        }
    }

    return $compliance
}

function Export-ComplianceReport {
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
    write-LogEntry "Compliance report exported to: $Path" -Level Success
}

function Invoke-TagInheritance {
    [object]$ResourceGroup,
        [object[]]$Resources
    )

    $RgTags = if ($ResourceGroup.Tags) { $ResourceGroup.Tags } else { @{} }

    if ($RgTags.Count -eq 0) {
        write-LogEntry "Resource group $($ResourceGroup.ResourceGroupName) has no tags to inherit" -Level Warning
        return
    }

    $InheritedCount = 0

    foreach ($resource in $Resources) {
        if ($resource.ResourceGroupName -eq $ResourceGroup.ResourceGroupName) {
            if (Apply-ResourceTags -Resource $resource -TagsToApply $RgTags -Merge) {
                $InheritedCount++
            }
        }
    }

    write-LogEntry "Inherited tags to $InheritedCount resources in $($ResourceGroup.ResourceGroupName)" -Level Success
}


    Write-Host "`nResource Tagging Management" -ForegroundColor Green
    Write-Host "============================" -ForegroundColor Green

    $context = Initialize-Azure
    Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green

    Write-Host "`nGathering resources..." -ForegroundColor Green
    $resources = Get-ScopedResources -Scope $Scope -ResourceGroups $ResourceGroup -ResourceTypes $ResourceType

    Write-Host "Found $($resources.Count) resources" -ForegroundColor Green

    switch ($Action) {
        'Apply' {
            if (-not $Tags) {
                throw "Tags parameter is required for Apply action"
            }

            Write-Host "`nApplying tags to resources..." -ForegroundColor Green
            $SuccessCount = 0

            foreach ($resource in $resources) {
                if (Apply-ResourceTags -Resource $resource -TagsToApply $Tags -Merge) {
                    $SuccessCount++
                }

                $params = @{
                    Status = "$SuccessCount of $($resources.Count)"
                    PercentComplete = (($SuccessCount / $resources.Count) * 100)
                    Activity = "Applying tags"
                }
                write-Progress @params
            }

            Write-Host "Successfully tagged $SuccessCount resources" -ForegroundColor Green
        }

        'Remove' {
            if (-not $Tags -and -not $RemoveUnauthorized) {
                throw "Specify tags to remove or use -RemoveUnauthorized"
            }

            Write-Host "`nRemoving tags from resources..." -ForegroundColor Green
            $TagsToRemove = if ($Tags) { $Tags.Keys } else { @() }

            foreach ($resource in $resources) {
                if ($RemoveUnauthorized -and $AuthorizedTags) {
                    $CurrentTags = if ($resource.Tags) { $resource.Tags.Keys } else { @() }
                    $UnauthorizedTags = $CurrentTags | Where-Object { $_ -notin $AuthorizedTags }
                    if ($UnauthorizedTags) {
                        Remove-ResourceTags -Resource $resource -TagsToRemove $UnauthorizedTags
                    }
                }
                elseif ($TagsToRemove) {
                    Remove-ResourceTags -Resource $resource -TagsToRemove $TagsToRemove
                }
            }
        }

        'Validate' {
            Write-Host "`nValidating tag compliance..." -ForegroundColor Green
            $ComplianceData = @()
            $CompliantCount = 0

            foreach ($resource in $resources) {
                $params = @{
                    Resource = $resource
                    RequiredTagNames = $RequiredTags
                    RequiredTagValues = $DefaultValues
                }
                $compliance = Test-TagCompliance @params

                $ComplianceData += @{
                    Resource = $resource
                    Compliance = $compliance
                }

                if ($compliance.IsCompliant) {
                    $CompliantCount++
                }
            }

            $ComplianceRate = if ($resources.Count -gt 0) {
                [Math]::Round(($CompliantCount / $resources.Count) * 100, 2)
            } else { 0 }

            Write-Host "`nCompliance Summary:" -ForegroundColor Green
            Write-Host "Total Resources: $($resources.Count)" -ForegroundColor Green
            Write-Host "Compliant: $CompliantCount" -ForegroundColor Green
            Write-Host "Non-Compliant: $($resources.Count - $CompliantCount)" -ForegroundColor Green
            Write-Output "Compliance Rate: $ComplianceRate%" -ForegroundColor $(
                if ($ComplianceRate -ge 90) { 'Green' }
                elseif ($ComplianceRate -ge 70) { 'Yellow' }
                else { 'Red' }
            )

            Export-ComplianceReport -ComplianceData $ComplianceData -Path $ExportPath
        }

        'Report' {
            Write-Host "`nGenerating tag report..." -ForegroundColor Green
            $TagSummary = @{}

            foreach ($resource in $resources) {
                if ($resource.Tags) {
                    foreach ($tag in $resource.Tags.GetEnumerator()) {
                        if (-not $TagSummary.ContainsKey($tag.Key)) {
                            $TagSummary[$tag.Key] = @{
                                Count = 0
                                Values = @{}
                            }
                        }
                        $TagSummary[$tag.Key].Count++

                        if (-not $TagSummary[$tag.Key].Values.ContainsKey($tag.Value)) {
                            $TagSummary[$tag.Key].Values[$tag.Value] = 0
                        }
                        $TagSummary[$tag.Key].Values[$tag.Value]++
                    }
                }
            }

            Write-Host "`nTag Usage Summary:" -ForegroundColor Green
            foreach ($TagName in ($TagSummary.Keys | Sort-Object)) {
                Write-Host "  $TagName : $($TagSummary[$TagName].Count) resources" -ForegroundColor Green
                $TopValues = $TagSummary[$TagName].Values.GetEnumerator() |
                    Sort-Object Value -Descending |
                    Select-Object -First 3
                foreach ($value in $TopValues) {
                    Write-Host "    - $($value.Key): $($value.Value)" -ForegroundColor Green
                }
            }
        }

        'Inherit' {
            if (-not $InheritFromResourceGroup) {
                throw "Use -InheritFromResourceGroup switch for inheritance"
            }

            Write-Host "`nInheriting tags from resource groups..." -ForegroundColor Green

            $ResourceGroups = if ($ResourceGroup) {
                $ResourceGroup | ForEach-Object { Get-AzResourceGroup -Name $_ }
            } else {
                Get-AzResourceGroup
            }

            foreach ($rg in $ResourceGroups) {
                Write-Host "Processing resource group: $($rg.ResourceGroupName)" -ForegroundColor Green
                $RgResources = $resources | Where-Object { $_.ResourceGroupName -eq $rg.ResourceGroupName }
                Invoke-TagInheritance -ResourceGroup $rg -Resources $RgResources
            }
        }

        'Fix' {
            Write-Host "`nFixing tag compliance issues..." -ForegroundColor Green

            foreach ($resource in $resources) {
                $params = @{
                    Resource = $resource
                    RequiredTagNames = $RequiredTags
                    RequiredTagValues = $DefaultValues
                }
                $compliance = Test-TagCompliance @params

                if (-not $compliance.IsCompliant) {
                    $TagsToApply = @{}

                    foreach ($TagName in $compliance.MissingTags) {
                        $TagsToApply[$TagName] = if ($DefaultValues -and $DefaultValues.ContainsKey($TagName)) {
                            $DefaultValues[$TagName]
                        } else {
                            "Unknown"
                        }
                    }

                    foreach ($incorrect in $compliance.IncorrectValues) {
                        $TagsToApply[$incorrect.Tag] = $incorrect.Expected
                    }

                    if ($TagsToApply.Count -gt 0) {
                        Apply-ResourceTags -Resource $resource -TagsToApply $TagsToApply -Merge
                    }

                    if ($compliance.UnauthorizedTags -and $RemoveUnauthorized) {
                        Remove-ResourceTags -Resource $resource -TagsToRemove $compliance.UnauthorizedTags
                    }
                }
            }

            Write-Host "Tag remediation completed" -ForegroundColor Green
        }
    }

    if ($script:ModifiedResources.Count -gt 0) {
        $LogPath = ".\TagModifications_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $script:ModifiedResources | Export-Csv -Path $LogPath -NoTypeInformation
        Write-Host "`nModification log saved to: $LogPath" -ForegroundColor Green
    }

    Write-Host "`nOperation completed successfully!" -ForegroundColor Green
}
catch {
    write-LogEntry "Operation failed: $_" -Level Error
    write-Error $_
    throw
}
finally {
    $ProgressPreference = 'Continue'`n}
