#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Resource Tagging Enforcer

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $SubscriptionId,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
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
    [ValidateSet("Audit" , "Enforce" , "Fix" )]
    $Action = "Audit" ,
    [Parameter()]
    [switch]$IncludeResourceGroups,
    [Parameter(ValueFromPipeline)]`n    $OutputPath = " .\tag-compliance-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
)
Write-Output "Script Started" # Color: $2
    $NonCompliantResources = @()
try {
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
    $resources = if ($ResourceGroupName) {
        Get-AzResource -ResourceGroupName $ResourceGroupName
    } else {
        Get-AzResource -ErrorAction Stop
    }
    if ($IncludeResourceGroups) {
    $ResourceGroups = if ($ResourceGroupName) {
            Get-AzResourceGroup -Name $ResourceGroupName
        } else {
            Get-AzResourceGroup -ErrorAction Stop
        }
    $resources = $resources + $ResourceGroups
    }

    foreach ($resource in $resources) {
    $MissingTags = @()
    $InvalidTags = @()
        foreach ($RequiredTag in $RequiredTags.Keys) {
            if (-not $resource.Tags -or -not $resource.Tags.ContainsKey($RequiredTag)) {
    $MissingTags = $MissingTags + $RequiredTag
            } elseif ($RequiredTags[$RequiredTag].Count -gt 0) {
                if ($resource.Tags[$RequiredTag] -notin $RequiredTags[$RequiredTag]) {
    $InvalidTags = $InvalidTags + " ;  $RequiredTag=$($resource.Tags[$RequiredTag])"
                }
            }
        }
        if ($MissingTags.Count -gt 0 -or $InvalidTags.Count -gt 0) {
    $NonCompliantResources = $NonCompliantResources + [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                ResourceGroup = $resource.ResourceGroupName
                Location = $resource.Location
                MissingTags = ($MissingTags -join ', ')
                InvalidTags = ($InvalidTags -join ', ')
                CurrentTags = if ($resource.Tags) { ($resource.Tags.GetEnumerator() | ForEach-Object { " $($_.Key)=$($_.Value)" }) -join '; ' } else { "None" }
                ComplianceStatus = "Non-Compliant"
            }
        }
    }
    switch ($Action) {
        "Audit" {

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

                } catch {

                }
            }
        }
    }
    $NonCompliantResources | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Output ""
    Write-Output "                              TAG COMPLIANCE ANALYSIS COMPLETE" # Color: $2
    Write-Output ""
    Write-Output "Compliance Summary:" # Color: $2
    Write-Output "    Total Resources: $($resources.Count)" # Color: $2
    Write-Output "    Non-Compliant: $($NonCompliantResources.Count)" # Color: $2
    Write-Output "    Compliance Rate: $([math]::Round((($resources.Count - $NonCompliantResources.Count) / $resources.Count) * 100, 2))%" # Color: $2
    Write-Output ""
    Write-Output "Required Tags:" # Color: $2
    foreach ($tag in $RequiredTags.Keys) {
    $AllowedValues = if ($RequiredTags[$tag].Count -gt 0) { " ($($RequiredTags[$tag] -join ', '))" } else { " (any value)" }
        Write-Output "    $tag $AllowedValues" # Color: $2
    }
    Write-Output ""
    Write-Output "Report: $OutputPath" # Color: $2
    Write-Output ""

} catch { throw`n}
