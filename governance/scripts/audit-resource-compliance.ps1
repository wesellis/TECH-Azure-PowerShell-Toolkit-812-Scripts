#Requires -Module Az.Resources
#Requires -Module Az.PolicyInsights
#Requires -Version 5.1
<#
.SYNOPSIS
    audit resource compliance
.DESCRIPTION
    audit resource compliance operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Audits Azure resource compliance against policies

    Evaluates resources against Azure Policy assignments and generates compliance reports.
    Supports multiple output formats and remediation tracking.
.PARAMETER SubscriptionId
    Target subscription ID (optional, uses current context if not specified)
.PARAMETER ResourceGroup
    Limit audit to specific resource group
.PARAMETER OutputFormat
    Report format: JSON, CSV, HTML (default: JSON)
.PARAMETER ExportPath
    Path for report file (optional, auto-generates if not specified)

    .\audit-resource-compliance.ps1 -OutputFormat CSV

    Audits current subscription and exports to CSV

    .\audit-resource-compliance.ps1 -ResourceGroup "RG-Production" -OutputFormat HTML

    Audits specific resource group with HTML report

    Author: Azure PowerShell Toolkit#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$ResourceGroup,

    [Parameter()]
    [ValidateSet('JSON', 'CSV', 'HTML')]
    [string]$OutputFormat = 'JSON',

    [Parameter()]
    [string]$ExportPath,

    [Parameter()]
    [switch]$IncludeRemediation,

    [Parameter()]
    [switch]$DetailedReport
)

# Set up error handling
$ErrorActionPreference = 'Stop'
trap {
    Write-Error "Script failed: $_"
    throw
}

#region Functions

function Test-AzureConnection {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Not connected to Azure. Initiating login..." -ForegroundColor Yellow
        Connect-AzAccount
        $context = Get-AzContext
    }

    if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
        Write-Host "Switching to subscription: $SubscriptionId" -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }

    return $context
}

function Get-PolicyCompliance {
    param(
        [string]$ResourceGroupName
    )

    $params = @{
        Top = 5000
    }

    if ($ResourceGroupName) {
        $params['ResourceGroupName'] = $ResourceGroupName
    }

    try {
        $states = Get-AzPolicyState @params

        $compliance = foreach ($state in $states) {
            [PSCustomObject]@{
                ResourceId = $state.ResourceId
                ResourceName = if ($state.ResourceId) { $state.ResourceId.Split('/')[-1] } else { 'N/A' }
                ResourceType = $state.ResourceType
                ResourceGroup = $state.ResourceGroup
                PolicyAssignment = $state.PolicyAssignmentName
                PolicyDefinition = $state.PolicyDefinitionName
                ComplianceState = $state.ComplianceState
                IsCompliant = $state.IsCompliant
                Timestamp = $state.Timestamp
            }
        }

        return $compliance
    }
    catch {
        Write-Error "Failed to retrieve policy compliance: $_"
        return @()
    }
}

function Get-ComplianceSummary {
    param(
        [array]$ComplianceData
    )

    $total = $ComplianceData.Count
    $compliant = ($ComplianceData | Where-Object IsCompliant).Count
    $nonCompliant = $total - $compliant

    return [PSCustomObject]@{
        TotalResources = $total
        CompliantResources = $compliant
        NonCompliantResources = $nonCompliant
        CompliancePercentage = if ($total -gt 0) { [Math]::Round(($compliant / $total) * 100, 2) } else { 0 }
        ByResourceType = $ComplianceData | Group-Object ResourceType | ForEach-Object {
            [PSCustomObject]@{
                Type = $_.Name
                Count = $_.Count
                Compliant = ($_.Group | Where-Object IsCompliant).Count
            }
        }
        ByPolicy = $ComplianceData | Group-Object PolicyAssignment | ForEach-Object {
            [PSCustomObject]@{
                Policy = $_.Name
                Count = $_.Count
                Compliant = ($_.Group | Where-Object IsCompliant).Count
            }
        }
    }
}

function Export-ComplianceReport {
    param(
        [object]$Summary,
        [array]$Details,
        [string]$Format,
        [string]$Path
    )

    switch ($Format) {
        'JSON' {
            $report = @{
                GeneratedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                Summary = $Summary
                Details = $Details
            }
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        }

        'CSV' {
            $Details | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        }

        'HTML' {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Policy Compliance Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; }
        h1 { color: #0078d4; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 24px; font-weight: bold; }
        .compliant { color: #107c10; }
        .non-compliant { color: #d13438; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background: #0078d4; color: white; padding: 10px; text-align: left; }
        td { padding: 8px; border-bottom: 1px solid #ddd; }
        tr:hover { background: #f5f5f5; }
    </style>
</head>
<body>
    <h1>Azure Policy Compliance Report</h1>
    <div class="summary">
        <div class="metric">
            <div class="metric-value">$($Summary.TotalResources)</div>
            <div>Total Resources</div>
        </div>
        <div class="metric">
            <div class="metric-value compliant">$($Summary.CompliantResources)</div>
            <div>Compliant</div>
        </div>
        <div class="metric">
            <div class="metric-value non-compliant">$($Summary.NonCompliantResources)</div>
            <div>Non-Compliant</div>
        </div>
        <div class="metric">
            <div class="metric-value">$($Summary.CompliancePercentage)%</div>
            <div>Compliance Rate</div>
        </div>
    </div>

    <h2>Non-Compliant Resources</h2>
    <table>
        <thead>
            <tr>
                <th>Resource Name</th>
                <th>Type</th>
                <th>Resource Group</th>
                <th>Policy</th>
                <th>State</th>
            </tr>
        </thead>
        <tbody>
"@
            foreach ($resource in ($Details | Where-Object { -not $_.IsCompliant } | Select-Object -First 100)) {
                $html += @"
            <tr>
                <td>$($resource.ResourceName)</td>
                <td>$($resource.ResourceType)</td>
                <td>$($resource.ResourceGroup)</td>
                <td>$($resource.PolicyAssignment)</td>
                <td class="non-compliant">$($resource.ComplianceState)</td>
            </tr>
"@
            }

            $html += @"
        </tbody>
    </table>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
</body>
</html>
"@
            $html | Out-File -FilePath $Path -Encoding UTF8
        }
    }
}

function Get-RemediationTasks {
    param(
        [array]$NonCompliantResources
    )

    $tasks = foreach ($resource in $NonCompliantResources) {
        try {
            $remediation = Get-AzPolicyRemediation -Name $resource.PolicyAssignment -ErrorAction SilentlyContinue

            [PSCustomObject]@{
                ResourceId = $resource.ResourceId
                PolicyAssignment = $resource.PolicyAssignment
                RemediationExists = $null -ne $remediation
                RemediationState = if ($remediation) { $remediation.ProvisioningState } else { 'Not Started' }
            
} catch {
            # Remediation not available for this policy
            [PSCustomObject]@{
                ResourceId = $resource.ResourceId
                PolicyAssignment = $resource.PolicyAssignment
                RemediationExists = $false
                RemediationState = 'Not Available'
            }
        }
    }

    return $tasks
}

#endregion

#region Main Execution

Write-Host "`nAzure Policy Compliance Audit" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

# Connect to Azure
$context = Test-AzureConnection
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green

# Set default export path if not provided
if (-not $ExportPath) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $extension = $OutputFormat.ToLower()
    $ExportPath = ".\PolicyCompliance_$timestamp.$extension"
}

# Get compliance data
Write-Host "`nRetrieving compliance data..." -ForegroundColor Yellow
$complianceData = Get-PolicyCompliance -ResourceGroupName $ResourceGroup

if ($complianceData.Count -eq 0) {
    Write-Warning "No policy compliance data found"
    exit 0
}

Write-Host "Retrieved $($complianceData.Count) policy states" -ForegroundColor Green

# Generate summary
$summary = Get-ComplianceSummary -ComplianceData $complianceData

# Display summary
Write-Host "`nCompliance Summary:" -ForegroundColor Cyan
Write-Host "Total Resources: $($summary.TotalResources)"
Write-Host "Compliant: $($summary.CompliantResources)" -ForegroundColor Green
Write-Host "Non-Compliant: $($summary.NonCompliantResources)" -ForegroundColor $(if ($summary.NonCompliantResources -gt 0) { 'Red' } else { 'Green' })
Write-Host "Compliance Rate: $($summary.CompliancePercentage)%`n"

# Show detailed breakdown if requested
if ($DetailedReport) {
    Write-Host "Resource Type Breakdown:" -ForegroundColor Cyan
    $summary.ByResourceType | Format-Table -AutoSize

    Write-Host "Policy Assignment Breakdown:" -ForegroundColor Cyan
    $summary.ByPolicy | Select-Object -First 10 | Format-Table -AutoSize
}

# Get remediation info if requested
$remediationTasks = @()
if ($IncludeRemediation) {
    Write-Host "Checking remediation status..." -ForegroundColor Yellow
    $nonCompliant = $complianceData | Where-Object { -not $_.IsCompliant }
    $remediationTasks = Get-RemediationTasks -NonCompliantResources $nonCompliant

    $availableRemediations = ($remediationTasks | Where-Object RemediationExists).Count
    Write-Host "Remediation available for $availableRemediations of $($nonCompliant.Count) non-compliant resources" -ForegroundColor Cyan
}

# Export report
Write-Host "`nExporting report to: $ExportPath" -ForegroundColor Yellow
Export-ComplianceReport -Summary $summary -Details $complianceData -Format $OutputFormat -Path $ExportPath
Write-Host "Report exported successfully" -ForegroundColor Green

# Final message
if ($summary.NonCompliantResources -gt 0) {
    Write-Host "`nAction Required: $($summary.NonCompliantResources) resources need attention" -ForegroundColor Yellow
}
else {
    Write-Host "`nAll resources are compliant!" -ForegroundColor Green
}

#endregion\n