#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Audits Azure resources against defined policies and compliance standards with

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    This script performs
    and governance requirements. It can audit single subscriptions, management groups, or across multiple
    subscriptions with detailed compliance reporting and remediation recommendations.
.parameter SubscriptionId
    Azure subscription ID to audit. If not provided, audits current subscription context.
.parameter ManagementGroupId
    Management group ID to audit (audits all subscriptions within the management group).
.parameter AllSubscriptions
    Audit all accessible subscriptions.
.parameter ResourceGroupName
    Specific resource group to audit within the subscription.
.parameter ResourceType
    Filter audit to specific resource types (e.g., 'Microsoft.Compute/virtualMachines').
.parameter PolicyDefinitionIds
    Array of specific policy definition IDs to audit against.
.parameter IncludeCompliant
    Include compliant resources in the audit results (default: false).
.parameter IncludeExemptions
    Include policy exemptions in the audit results.
.parameter ComplianceState
    Filter by compliance state: Compliant, NonCompliant, Unknown, NotStarted.
.parameter OutputFormat
    Output format: JSON, CSV, HTML, Excel.
.parameter OutputPath
    Path to save the audit report. If not provided, displays on console.
.parameter IncludePolicyDetails
    Include detailed policy information in the report.
.parameter IncludeRemediationGuidance
    Include remediation guidance for non-compliant resources.
.parameter DetailLevel
    Level of detail in the report: Summary, Standard, Detailed.
.parameter MaxResults
    Maximum number of results to return (default: 1000).
.parameter ExcludeResourceGroups
    Array of resource group names to exclude from the audit.
.parameter Tags
    Filter resources by specific tags (hashtable).
.parameter LogPath
    Path to store detailed logs. If not provided, logs to default location.

    .\audit-resources.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -OutputFormat CSV -OutputPath "C:\Reports\audit.csv"

    .\audit-resources.ps1 -ManagementGroupId "MyMgmtGroup" -ComplianceState NonCompliant -IncludeRemediationGuidance

    .\audit-resources.ps1 -ResourceType "Microsoft.Compute/virtualMachines" -DetailLevel Detailed -OutputFormat HTML
.NOTES
    File Name      : audit-resources.ps1
    Author         : Azure PowerShell Toolkit
    Created        : 2024-11-15
    Prerequisites  : Azure PowerShell module, appropriate Azure permissions
    Version        : 1.0.0

[CmdletBinding()]
param(
    [parameter(HelpMessage = "Azure subscription ID to audit")]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SubscriptionId,

    [parameter(HelpMessage = "Management group ID to audit")]
    [ValidateNotNullOrEmpty()]
    [string]$ManagementGroupId,

    [parameter(HelpMessage = "Audit all accessible subscriptions")]
    [switch]$AllSubscriptions,

    [parameter(HelpMessage = "Specific resource group to audit")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [parameter(HelpMessage = "Filter by specific resource types")]
    [string[]]$ResourceType,

    [parameter(HelpMessage = "Specific policy definition IDs to audit")]
    [string[]]$PolicyDefinitionIds,

    [parameter(HelpMessage = "Include compliant resources in results")]
    [switch]$IncludeCompliant,

    [parameter(HelpMessage = "Include policy exemptions in results")]
    [switch]$IncludeExemptions,

    [parameter(HelpMessage = "Filter by compliance state")]
    [ValidateSet("Compliant", "NonCompliant", "Unknown", "NotStarted")]
    [string]$ComplianceState,

    [parameter(HelpMessage = "Output format for the report")]
    [ValidateSet("JSON", "CSV", "HTML", "Excel", "Console")]
    [string]$OutputFormat = "Console",

    [parameter(HelpMessage = "Path to save the audit report")]


    [ValidateNotNullOrEmpty()]


    [string] $OutputPath,

    [parameter(HelpMessage = "Include detailed policy information")]
    [switch]$IncludePolicyDetails,

    [parameter(HelpMessage = "Include remediation guidance")]
    [switch]$IncludeRemediationGuidance,

    [parameter(HelpMessage = "Level of detail in the report")]
    [ValidateSet("Summary", "Standard", "Detailed")]
    [string]$DetailLevel = "Standard",

    [parameter(HelpMessage = "Maximum number of results to return")]
    [ValidateRange(1, 10000)]
    [int]$MaxResults = 1000,

    [parameter(HelpMessage = "Resource groups to exclude from audit")]
    [string[]]$ExcludeResourceGroups,

    [parameter(HelpMessage = "Filter resources by tags")]
    [hashtable]$Tags,

    [parameter(HelpMessage = "Path for detailed logging")]
    [ValidateScript({ Test-Path (Split-Path $_ -Parent) })]
    [string]$LogPath
)
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
if (-not $LogPath) {
    [string]$LogPath = Join-Path $env:TEMP "audit-resources_$timestamp.log"
}

[OutputType([PSCustomObject])] 
 {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    [string]$LogEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $LogPath -Value $LogEntry

    switch ($Level) {
        'Error' { write-Error $Message }
        'Warning' { write-Warning $Message }
        'Debug' { write-Debug $Message }
        default { Write-Output $Message }
    }
}

function Test-AzureConnection {
    try {
    $context = Get-AzContext
        if (-not $context) {
            throw "Not connected to Azure"
        }
        write-Log "Connected to Azure as $($context.Account.Id)"
        return $true
    }
    catch {
        write-Log "Azure connection test failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Get-AuditScope {
        param(
        [string]$SubscriptionId,
        [string]$ManagementGroupId,
        [bool]$AllSubscriptions,
        [string]$ResourceGroupName
    )
    [string]$scopes = @()

    if ($AllSubscriptions) {
        write-Log "Getting all accessible subscriptions..."
    $subscriptions = Get-AzSubscription
        foreach ($sub in $subscriptions) {
            if ($ResourceGroupName) {
    [string]$scopes += "/subscriptions/$($sub.Id)/resourceGroups/$ResourceGroupName"
            }
            else {
    [string]$scopes += "/subscriptions/$($sub.Id)"
            }
        }
        write-Log "Found $($subscriptions.Count) subscriptions to audit"
    }
    elseif ($ManagementGroupId) {
    [string]$scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
    [string]$scopes += $scope
        write-Log "Using management group scope: $scope"
    }
    elseif ($SubscriptionId) {
        if ($ResourceGroupName) {
    [string]$scope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"
        }
        else {
    [string]$scope = "/subscriptions/$SubscriptionId"
        }
    [string]$scopes += $scope
        write-Log "Using subscription scope: $scope"
    }
    else {
    $context = Get-AzContext
        if ($context -and $context.Subscription) {
            if ($ResourceGroupName) {
    [string]$scope = "/subscriptions/$($context.Subscription.Id)/resourceGroups/$ResourceGroupName"
            }
            else {
    [string]$scope = "/subscriptions/$($context.Subscription.Id)"
            }
    [string]$scopes += $scope
            write-Log "Using current subscription scope: $scope"
        }
        else {
            throw "Unable to determine audit scope. Please provide SubscriptionId, ManagementGroupId, or ensure you have an active Azure context."
        }
    }

    return $scopes
}

function Get-PolicyStates {
        param(
        [string[]]$Scopes,
        [string[]]$ResourceTypes,
        [string[]]$PolicyDefinitionIds,
        [string]$ComplianceState,
        [int]$MaxResults,
        [string[]]$ExcludeResourceGroups,
        [hashtable]$Tags
    )
    [string]$AllPolicyStates = @()

    foreach ($scope in $Scopes) {
        try {
            write-Log "Retrieving policy states for scope: $scope"
    $QueryParams = @{
                Scope = $scope
                Top = $MaxResults
            }

            if ($PolicyDefinitionIds) {
    [string]$QueryParams.PolicyDefinitionName = $PolicyDefinitionIds
            }

            if ($ComplianceState) {
    [string]$QueryParams.ComplianceState = $ComplianceState
            }
    $PolicyStates = Get-AzPolicyState @queryParams

            if ($ResourceTypes) {
    [string]$PolicyStates = $PolicyStates | Where-Object { $_.ResourceType -in $ResourceTypes }
            }

            if ($ExcludeResourceGroups) {
    [string]$PolicyStates = $PolicyStates | Where-Object {
    [string]$RgName = $_.ResourceId -replace '.*?/resourceGroups/([^/]+)/.*', '$1'
    [string]$RgName -notin $ExcludeResourceGroups
                }
            }

            if ($Tags) {
    [string]$PolicyStates = $PolicyStates | Where-Object {
    $resource = Get-AzResource -ResourceId $_.ResourceId -ErrorAction SilentlyContinue
                    if ($resource -and $resource.Tags) {
    [string]$MatchesTags = $true
                        foreach ($TagKey in $Tags.Keys) {
                            if (-not $resource.Tags.ContainsKey($TagKey) -or $resource.Tags[$TagKey] -ne $Tags[$TagKey]) {
    [string]$MatchesTags = $false
                                break
                            }
                        }
                        return $MatchesTags
                    }
                    return $false
                }
            }
    [string]$AllPolicyStates += $PolicyStates
            write-Log "Retrieved $($PolicyStates.Count) policy states from scope: $scope"
        }
        catch {
            write-Log "Failed to retrieve policy states for scope $scope: $($_.Exception.Message)" -Level Warning
        }
    }

    return $AllPolicyStates
}

function Get-PolicyDefinitionDetails {
        param([string]$PolicyDefinitionId)

    try {
    $PolicyDef = Get-AzPolicyDefinition -Id $PolicyDefinitionId -ErrorAction SilentlyContinue
        if ($PolicyDef) {
            return @{
                DisplayName = $PolicyDef.Properties.DisplayName
                Description = $PolicyDef.Properties.Description
                Category = $PolicyDef.Properties.Metadata.category
                Version = $PolicyDef.Properties.Metadata.version
            }
        }
    } catch {
        write-Log "Could not retrieve policy definition details for $PolicyDefinitionId" -Level Debug
    }

    return @{
        DisplayName = "Unknown"
        Description = "Policy definition not accessible"
        Category = "Unknown"
        Version = "Unknown"
    }
}

function Get-RemediationGuidance {
        param(
        [string]$PolicyDefinitionId,
        [string]$ResourceType,
        [string]$ComplianceState
    )
    [string]$guidance = @()

    if ($ComplianceState -eq "NonCompliant") {
        switch -Regex ($ResourceType) {
            "Microsoft\.Compute/virtualMachines" {
    [string]$guidance += "Review VM configuration for compliance with organizational policies"
    [string]$guidance += "Check VM extensions, disk encryption, and network security group assignments"
            }
            "Microsoft\.Storage/storageAccounts" {
    [string]$guidance += "Verify storage account encryption, access policies, and network restrictions"
    [string]$guidance += "Review blob storage configuration and access permissions"
            }
            "Microsoft\.Network/networkSecurityGroups" {
    [string]$guidance += "Review NSG rules for compliance with security policies"
    [string]$guidance += "Ensure proper inbound and outbound rule configurations"
            }
            "Microsoft\.KeyVault/vaults" {
    [string]$guidance += "Verify Key Vault access policies and network restrictions"
    [string]$guidance += "Check encryption and secret management compliance"
            }
            default {
    [string]$guidance += "Review resource configuration against policy requirements"
    [string]$guidance += "Consult Azure Policy documentation for specific remediation steps"
            }
        }
    $PolicyDetails = Get-PolicyDefinitionDetails -PolicyDefinitionId $PolicyDefinitionId
        if ($PolicyDetails.Description -and $PolicyDetails.Description -ne "Policy definition not accessible") {
    [string]$guidance += "Policy requirement: $($PolicyDetails.Description)"
        }
    }

    return $guidance
}

function Format-AuditResults {
        param(
        [array]$PolicyStates,
        [string]$DetailLevel,
        [bool]$IncludePolicyDetails,
        [bool]$IncludeRemediationGuidance
    )
    [string]$results = @()

    foreach ($state in $PolicyStates) {
    $result = [PSCustomObject]@{
            ResourceId = $state.ResourceId
            ResourceType = $state.ResourceType
            ResourceName = ($state.ResourceId -split '/')[-1]
            ResourceGroup = ($state.ResourceId -split '/')[4]
            Subscription = ($state.ResourceId -split '/')[2]
            ComplianceState = $state.ComplianceState
            PolicyDefinitionId = $state.PolicyDefinitionId
            PolicyAssignmentId = $state.PolicyAssignmentId
            Timestamp = $state.Timestamp
        }

        if ($DetailLevel -eq "Detailed" -or $IncludePolicyDetails) {
    $PolicyDetails = Get-PolicyDefinitionDetails -PolicyDefinitionId $state.PolicyDefinitionId
    [string]$result | Add-Member -MemberType NoteProperty -Name "PolicyDisplayName" -Value $PolicyDetails.DisplayName
    [string]$result | Add-Member -MemberType NoteProperty -Name "PolicyDescription" -Value $PolicyDetails.Description
    [string]$result | Add-Member -MemberType NoteProperty -Name "PolicyCategory" -Value $PolicyDetails.Category
        }

        if ($IncludeRemediationGuidance) {
    $guidance = Get-RemediationGuidance -PolicyDefinitionId $state.PolicyDefinitionId -ResourceType $state.ResourceType -ComplianceState $state.ComplianceState
    [string]$result | Add-Member -MemberType NoteProperty -Name "RemediationGuidance" -Value ($guidance -join "; ")
        }
    [string]$results += $result
    }

    return $results
}

function Export-AuditReport {
        param(
        [array]$Results,
        [string]$Format,
        [string]$Path,
        [string]$DetailLevel
    )

    if (-not $Path) {
        if ($Format -eq "Console") {
            return $Results | Format-Table -AutoSize
        }
        else {
    [string]$Path = Join-Path $env:TEMP "audit-report_$timestamp.$($Format.ToLower())"
        }
    }

    switch ($Format) {
        "JSON" {
    [string]$Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        }
        "CSV" {
    [string]$Results | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        }
        "HTML" {
    [string]$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Resource Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid
        th { background-color:
        .non-compliant { background-color:
        .compliant { background-color:
        .unknown { background-color:
    </style>
</head>
<body>
    <h1>Azure Resource Audit Report</h1>
    <p>Generated: $(Get-Date)</p>
    <p>Total Resources: $($Results.Count)</p>

    <table>
        <thead>
            <tr>
                <th>Resource Name</th>
                <th>Resource Type</th>
                <th>Resource Group</th>
                <th>Compliance State</th>
                <th>Policy</th>
            </tr>
        </thead>
        <tbody>
"@
            foreach ($result in $Results) {
    [string]$CssClass = switch ($result.ComplianceState) {
                    "NonCompliant" { "non-compliant" }
                    "Compliant" { "compliant" }
                    default { "unknown" }
                }
    [string]$PolicyName = if ($result.PolicyDisplayName) { $result.PolicyDisplayName } else { ($result.PolicyDefinitionId -split '/')[-1] }
    [string]$html += @"
            <tr class="$CssClass">
                <td>$($result.ResourceName)</td>
                <td>$($result.ResourceType)</td>
                <td>$($result.ResourceGroup)</td>
                <td>$($result.ComplianceState)</td>
                <td>$PolicyName</td>
            </tr>
"@
            }
    [string]$html += @"
        </tbody>
    </table>
</body>
</html>
"@
    [string]$html | Out-File -FilePath $Path -Encoding UTF8
        }
        "Excel" {
            if (Get-Module -ListAvailable -Name ImportExcel) {
    [string]$Results | Export-Excel -Path $Path -AutoSize -TableStyle Medium2 -FreezeTopRow
            }
            else {
                write-Log "ImportExcel module not available. Exporting as CSV instead." -Level Warning
    [string]$Path = $Path -replace '\.xlsx?$', '.csv'
    [string]$Results | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
            }
        }
    }

    write-Log "Report exported to: $Path"
    return $Path
}

function Get-ComplianceSummary {
        param([array]$Results)
    $summary = @{
        TotalResources = $Results.Count
        Compliant = ($Results | Where-Object { $_.ComplianceState -eq "Compliant" }).Count
        NonCompliant = ($Results | Where-Object { $_.ComplianceState -eq "NonCompliant" }).Count
        Unknown = ($Results | Where-Object { $_.ComplianceState -eq "Unknown" }).Count
        NotStarted = ($Results | Where-Object { $_.ComplianceState -eq "NotStarted" }).Count
    }
    [string]$summary.CompliancePercentage = if ($summary.TotalResources -gt 0) {
        [math]::Round(($summary.Compliant / $summary.TotalResources) * 100, 2)
    } else { 0 }

    return $summary
}

try {
    write-Log "Starting Azure resource audit..."

    if (-not (Test-AzureConnection)) {
        throw "Azure connection required. Please run Connect-AzAccount first."
    }

    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        write-Log "Set subscription context: $SubscriptionId"
    }
    $AuditScopes = Get-AuditScope -SubscriptionId $SubscriptionId -ManagementGroupId $ManagementGroupId -AllSubscriptions $AllSubscriptions -ResourceGroupName $ResourceGroupName

    write-Log "Retrieving policy compliance states..."
    $PolicyStates = Get-PolicyStates -Scopes $AuditScopes -ResourceTypes $ResourceType -PolicyDefinitionIds $PolicyDefinitionIds -ComplianceState $ComplianceState -MaxResults $MaxResults -ExcludeResourceGroups $ExcludeResourceGroups -Tags $Tags

    if (-not $IncludeCompliant) {
    [string]$PolicyStates = $PolicyStates | Where-Object { $_.ComplianceState -ne "Compliant" }
    }

    write-Log "Retrieved $($PolicyStates.Count) policy states for analysis"
    [string]$AuditResults = Format-AuditResults -PolicyStates $PolicyStates -DetailLevel $DetailLevel -IncludePolicyDetails $IncludePolicyDetails -IncludeRemediationGuidance $IncludeRemediationGuidance
    $summary = Get-ComplianceSummary -Results $AuditResults

    write-Log "Audit Summary:"
    write-Log "  Total Resources: $($summary.TotalResources)"
    write-Log "  Compliant: $($summary.Compliant)"
    write-Log "  Non-Compliant: $($summary.NonCompliant)"
    write-Log "  Unknown: $($summary.Unknown)"
    write-Log "  Compliance Percentage: $($summary.CompliancePercentage)%"

    if ($OutputFormat -ne "Console" -or $OutputPath) {
    [string]$ReportPath = Export-AuditReport -Results $AuditResults -Format $OutputFormat -Path $OutputPath -DetailLevel $DetailLevel
        write-Log "Audit report saved to: $ReportPath"
    }
    else {
        write-Log "Displaying audit results on console..."
    [string]$AuditResults | Format-Table -AutoSize
    }

    return @{
        Summary = $summary
        Results = $AuditResults
        ReportPath = if ($ReportPath) { $ReportPath } else { $null }
    }
} catch {
    [string]$ErrorMessage = "Resource audit failed: $($_.Exception.Message)"
    write-Log $ErrorMessage -Level Error
    throw $_
}
finally {
    write-Log "Log file saved to: $LogPath"}
