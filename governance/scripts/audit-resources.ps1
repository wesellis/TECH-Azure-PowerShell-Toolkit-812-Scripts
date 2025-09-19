#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Audits Azure resources against defined policies and compliance standards with comprehensive reporting.

.DESCRIPTION
    This script performs comprehensive auditing of Azure resources against defined policies, compliance standards,
    and governance requirements. It can audit single subscriptions, management groups, or across multiple
    subscriptions with detailed compliance reporting and remediation recommendations.

.PARAMETER SubscriptionId
    Azure subscription ID to audit. If not provided, audits current subscription context.

.PARAMETER ManagementGroupId
    Management group ID to audit (audits all subscriptions within the management group).

.PARAMETER AllSubscriptions
    Audit all accessible subscriptions.

.PARAMETER ResourceGroupName
    Specific resource group to audit within the subscription.

.PARAMETER ResourceType
    Filter audit to specific resource types (e.g., 'Microsoft.Compute/virtualMachines').

.PARAMETER PolicyDefinitionIds
    Array of specific policy definition IDs to audit against.

.PARAMETER IncludeCompliant
    Include compliant resources in the audit results (default: false).

.PARAMETER IncludeExemptions
    Include policy exemptions in the audit results.

.PARAMETER ComplianceState
    Filter by compliance state: Compliant, NonCompliant, Unknown, NotStarted.

.PARAMETER OutputFormat
    Output format: JSON, CSV, HTML, Excel.

.PARAMETER OutputPath
    Path to save the audit report. If not provided, displays on console.

.PARAMETER IncludePolicyDetails
    Include detailed policy information in the report.

.PARAMETER IncludeRemediationGuidance
    Include remediation guidance for non-compliant resources.

.PARAMETER DetailLevel
    Level of detail in the report: Summary, Standard, Detailed.

.PARAMETER MaxResults
    Maximum number of results to return (default: 1000).

.PARAMETER ExcludeResourceGroups
    Array of resource group names to exclude from the audit.

.PARAMETER Tags
    Filter resources by specific tags (hashtable).

.PARAMETER LogPath
    Path to store detailed logs. If not provided, logs to default location.

.EXAMPLE
    .\audit-resources.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -OutputFormat CSV -OutputPath "C:\Reports\audit.csv"

.EXAMPLE
    .\audit-resources.ps1 -ManagementGroupId "MyMgmtGroup" -ComplianceState NonCompliant -IncludeRemediationGuidance

.EXAMPLE
    .\audit-resources.ps1 -ResourceType "Microsoft.Compute/virtualMachines" -DetailLevel Detailed -OutputFormat HTML

.NOTES
    File Name      : audit-resources.ps1
    Author         : Wes Ellis (wes@wesellis.com)
    Created        : 2024-11-15
    Prerequisites  : Azure PowerShell module, appropriate Azure permissions
    Version        : 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(HelpMessage = "Azure subscription ID to audit")]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SubscriptionId,

    [Parameter(HelpMessage = "Management group ID to audit")]
    [ValidateNotNullOrEmpty()]
    [string]$ManagementGroupId,

    [Parameter(HelpMessage = "Audit all accessible subscriptions")]
    [switch]$AllSubscriptions,

    [Parameter(HelpMessage = "Specific resource group to audit")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(HelpMessage = "Filter by specific resource types")]
    [string[]]$ResourceType,

    [Parameter(HelpMessage = "Specific policy definition IDs to audit")]
    [string[]]$PolicyDefinitionIds,

    [Parameter(HelpMessage = "Include compliant resources in results")]
    [switch]$IncludeCompliant,

    [Parameter(HelpMessage = "Include policy exemptions in results")]
    [switch]$IncludeExemptions,

    [Parameter(HelpMessage = "Filter by compliance state")]
    [ValidateSet("Compliant", "NonCompliant", "Unknown", "NotStarted")]
    [string]$ComplianceState,

    [Parameter(HelpMessage = "Output format for the report")]
    [ValidateSet("JSON", "CSV", "HTML", "Excel", "Console")]
    [string]$OutputFormat = "Console",

    [Parameter(HelpMessage = "Path to save the audit report")]
    [string]$OutputPath,

    [Parameter(HelpMessage = "Include detailed policy information")]
    [switch]$IncludePolicyDetails,

    [Parameter(HelpMessage = "Include remediation guidance")]
    [switch]$IncludeRemediationGuidance,

    [Parameter(HelpMessage = "Level of detail in the report")]
    [ValidateSet("Summary", "Standard", "Detailed")]
    [string]$DetailLevel = "Standard",

    [Parameter(HelpMessage = "Maximum number of results to return")]
    [ValidateRange(1, 10000)]
    [int]$MaxResults = 1000,

    [Parameter(HelpMessage = "Resource groups to exclude from audit")]
    [string[]]$ExcludeResourceGroups,

    [Parameter(HelpMessage = "Filter resources by tags")]
    [hashtable]$Tags,

    [Parameter(HelpMessage = "Path for detailed logging")]
    [ValidateScript({ Test-Path (Split-Path $_ -Parent) })]
    [string]$LogPath
)

#region Functions

#Requires -Version 5.1
#Requires -Modules Az.Resources, Az.Accounts, Az.PolicyInsights

# Initialize logging
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
if (-not $LogPath) {
    $LogPath = Join-Path $env:TEMP "audit-resources_$timestamp.log"
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )

    $logEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $LogPath -Value $logEntry

    switch ($Level) {
        'Error' { Write-Error $Message }
        'Warning' { Write-Warning $Message }
        'Debug' { Write-Debug $Message }
        default { Write-Host $Message }
    }
}

function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if (-not $context) {
            throw "Not connected to Azure"
        }
        Write-Log "Connected to Azure as $($context.Account.Id)"
        return $true
    }
    catch {
        Write-Log "Azure connection test failed: $($_.Exception.Message)" -Level Error
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

    $scopes = @()

    if ($AllSubscriptions) {
        Write-Log "Getting all accessible subscriptions..."
        $subscriptions = Get-AzSubscription
        foreach ($sub in $subscriptions) {
            if ($ResourceGroupName) {
                $scopes += "/subscriptions/$($sub.Id)/resourceGroups/$ResourceGroupName"
            }
            else {
                $scopes += "/subscriptions/$($sub.Id)"
            }
        }
        Write-Log "Found $($subscriptions.Count) subscriptions to audit"
    }
    elseif ($ManagementGroupId) {
        $scope = "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
        $scopes += $scope
        Write-Log "Using management group scope: $scope"
    }
    elseif ($SubscriptionId) {
        if ($ResourceGroupName) {
            $scope = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"
        }
        else {
            $scope = "/subscriptions/$SubscriptionId"
        }
        $scopes += $scope
        Write-Log "Using subscription scope: $scope"
    }
    else {
        $context = Get-AzContext
        if ($context -and $context.Subscription) {
            if ($ResourceGroupName) {
                $scope = "/subscriptions/$($context.Subscription.Id)/resourceGroups/$ResourceGroupName"
            }
            else {
                $scope = "/subscriptions/$($context.Subscription.Id)"
            }
            $scopes += $scope
            Write-Log "Using current subscription scope: $scope"
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

    $allPolicyStates = @()

    foreach ($scope in $Scopes) {
        try {
            Write-Log "Retrieving policy states for scope: $scope"

            $queryParams = @{
                Scope = $scope
                Top = $MaxResults
            }

            if ($PolicyDefinitionIds) {
                $queryParams.PolicyDefinitionName = $PolicyDefinitionIds
            }

            if ($ComplianceState) {
                $queryParams.ComplianceState = $ComplianceState
            }

            $policyStates = Get-AzPolicyState @queryParams

            # Apply additional filters
            if ($ResourceTypes) {
                $policyStates = $policyStates | Where-Object { $_.ResourceType -in $ResourceTypes }
            }

            if ($ExcludeResourceGroups) {
                $policyStates = $policyStates | Where-Object {
                    $rgName = $_.ResourceId -replace '.*?/resourceGroups/([^/]+)/.*', '$1'
                    $rgName -notin $ExcludeResourceGroups
                }
            }

            if ($Tags) {
                $policyStates = $policyStates | Where-Object {
                    $resource = Get-AzResource -ResourceId $_.ResourceId -ErrorAction SilentlyContinue
                    if ($resource -and $resource.Tags) {
                        $matchesTags = $true
                        foreach ($tagKey in $Tags.Keys) {
                            if (-not $resource.Tags.ContainsKey($tagKey) -or $resource.Tags[$tagKey] -ne $Tags[$tagKey]) {
                                $matchesTags = $false
                                break
                            }
                        }
                        return $matchesTags
                    }
                    return $false
                }
            }

            $allPolicyStates += $policyStates
            Write-Log "Retrieved $($policyStates.Count) policy states from scope: $scope"
        }
        catch {
            Write-Log "Failed to retrieve policy states for scope $scope: $($_.Exception.Message)" -Level Warning
        }
    }

    return $allPolicyStates
}

function Get-PolicyDefinitionDetails {
    param([string]$PolicyDefinitionId)

    try {
        $policyDef = Get-AzPolicyDefinition -Id $PolicyDefinitionId -ErrorAction SilentlyContinue
        if ($policyDef) {
            return @{
                DisplayName = $policyDef.Properties.DisplayName
                Description = $policyDef.Properties.Description
                Category = $policyDef.Properties.Metadata.category
                Version = $policyDef.Properties.Metadata.version
            }
        }
    }
    catch {
        Write-Log "Could not retrieve policy definition details for $PolicyDefinitionId" -Level Debug
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

    $guidance = @()

    if ($ComplianceState -eq "NonCompliant") {
        # General guidance based on resource type
        switch -Regex ($ResourceType) {
            "Microsoft\.Compute/virtualMachines" {
                $guidance += "Review VM configuration for compliance with organizational policies"
                $guidance += "Check VM extensions, disk encryption, and network security group assignments"
            }
            "Microsoft\.Storage/storageAccounts" {
                $guidance += "Verify storage account encryption, access policies, and network restrictions"
                $guidance += "Review blob storage configuration and access permissions"
            }
            "Microsoft\.Network/networkSecurityGroups" {
                $guidance += "Review NSG rules for compliance with security policies"
                $guidance += "Ensure proper inbound and outbound rule configurations"
            }
            "Microsoft\.KeyVault/vaults" {
                $guidance += "Verify Key Vault access policies and network restrictions"
                $guidance += "Check encryption and secret management compliance"
            }
            default {
                $guidance += "Review resource configuration against policy requirements"
                $guidance += "Consult Azure Policy documentation for specific remediation steps"
            }
        }

        # Add policy-specific guidance if available
        $policyDetails = Get-PolicyDefinitionDetails -PolicyDefinitionId $PolicyDefinitionId
        if ($policyDetails.Description -and $policyDetails.Description -ne "Policy definition not accessible") {
            $guidance += "Policy requirement: $($policyDetails.Description)"
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

    $results = @()

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
            $policyDetails = Get-PolicyDefinitionDetails -PolicyDefinitionId $state.PolicyDefinitionId
            $result | Add-Member -MemberType NoteProperty -Name "PolicyDisplayName" -Value $policyDetails.DisplayName
            $result | Add-Member -MemberType NoteProperty -Name "PolicyDescription" -Value $policyDetails.Description
            $result | Add-Member -MemberType NoteProperty -Name "PolicyCategory" -Value $policyDetails.Category
        }

        if ($IncludeRemediationGuidance) {
            $guidance = Get-RemediationGuidance -PolicyDefinitionId $state.PolicyDefinitionId -ResourceType $state.ResourceType -ComplianceState $state.ComplianceState
            $result | Add-Member -MemberType NoteProperty -Name "RemediationGuidance" -Value ($guidance -join "; ")
        }

        $results += $result
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
            $Path = Join-Path $env:TEMP "audit-report_$timestamp.$($Format.ToLower())"
        }
    }

    switch ($Format) {
        "JSON" {
            $Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        }
        "CSV" {
            $Results | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        }
        "HTML" {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Resource Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .non-compliant { background-color: #ffebee; }
        .compliant { background-color: #e8f5e8; }
        .unknown { background-color: #fff3e0; }
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
                $cssClass = switch ($result.ComplianceState) {
                    "NonCompliant" { "non-compliant" }
                    "Compliant" { "compliant" }
                    default { "unknown" }
                }

                $policyName = if ($result.PolicyDisplayName) { $result.PolicyDisplayName } else { ($result.PolicyDefinitionId -split '/')[-1] }

                $html += @"
            <tr class="$cssClass">
                <td>$($result.ResourceName)</td>
                <td>$($result.ResourceType)</td>
                <td>$($result.ResourceGroup)</td>
                <td>$($result.ComplianceState)</td>
                <td>$policyName</td>
            </tr>
"@
            }

            $html += @"
        </tbody>
    </table>
</body>
</html>
"@
            $html | Out-File -FilePath $Path -Encoding UTF8
        }
        "Excel" {
            if (Get-Module -ListAvailable -Name ImportExcel) {
                $Results | Export-Excel -Path $Path -AutoSize -TableStyle Medium2 -FreezeTopRow
            }
            else {
                Write-Log "ImportExcel module not available. Exporting as CSV instead." -Level Warning
                $Path = $Path -replace '\.xlsx?$', '.csv'
                $Results | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
            }
        }
    }

    Write-Log "Report exported to: $Path"
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

    $summary.CompliancePercentage = if ($summary.TotalResources -gt 0) {
        [math]::Round(($summary.Compliant / $summary.TotalResources) * 100, 2)
    } else { 0 }

    return $summary
}

# Main execution
try {
    Write-Log "Starting Azure resource audit..."

    # Test Azure connection
    if (-not (Test-AzureConnection)) {
        throw "Azure connection required. Please run Connect-AzAccount first."
    }

    # Set subscription context if provided
    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-Log "Set subscription context: $SubscriptionId"
    }

    # Determine audit scopes
    $auditScopes = Get-AuditScope -SubscriptionId $SubscriptionId -ManagementGroupId $ManagementGroupId -AllSubscriptions $AllSubscriptions -ResourceGroupName $ResourceGroupName

    # Get policy states
    Write-Log "Retrieving policy compliance states..."
    $policyStates = Get-PolicyStates -Scopes $auditScopes -ResourceTypes $ResourceType -PolicyDefinitionIds $PolicyDefinitionIds -ComplianceState $ComplianceState -MaxResults $MaxResults -ExcludeResourceGroups $ExcludeResourceGroups -Tags $Tags

    # Filter out compliant resources if not requested
    if (-not $IncludeCompliant) {
        $policyStates = $policyStates | Where-Object { $_.ComplianceState -ne "Compliant" }
    }

    Write-Log "Retrieved $($policyStates.Count) policy states for analysis"

    # Format results
    $auditResults = Format-AuditResults -PolicyStates $policyStates -DetailLevel $DetailLevel -IncludePolicyDetails $IncludePolicyDetails -IncludeRemediationGuidance $IncludeRemediationGuidance

    # Generate compliance summary
    $summary = Get-ComplianceSummary -Results $auditResults

    Write-Log "Audit Summary:"
    Write-Log "  Total Resources: $($summary.TotalResources)"
    Write-Log "  Compliant: $($summary.Compliant)"
    Write-Log "  Non-Compliant: $($summary.NonCompliant)"
    Write-Log "  Unknown: $($summary.Unknown)"
    Write-Log "  Compliance Percentage: $($summary.CompliancePercentage)%"

    # Export results
    if ($OutputFormat -ne "Console" -or $OutputPath) {
        $reportPath = Export-AuditReport -Results $auditResults -Format $OutputFormat -Path $OutputPath -DetailLevel $DetailLevel
        Write-Log "Audit report saved to: $reportPath"
    }
    else {
        Write-Log "Displaying audit results on console..."
        $auditResults | Format-Table -AutoSize
    }

    # Return results object
    return @{
        Summary = $summary
        Results = $auditResults
        ReportPath = if ($reportPath) { $reportPath } else { $null }
    }
}
catch {
    $errorMessage = "Resource audit failed: $($_.Exception.Message)"
    Write-Log $errorMessage -Level Error
    throw $_
}
finally {
    Write-Log "Log file saved to: $LogPath"
}


#endregion
