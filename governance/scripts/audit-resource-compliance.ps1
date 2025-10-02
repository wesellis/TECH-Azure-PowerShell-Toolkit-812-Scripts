#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    audit resource compliance
.DESCRIPTION
    audit resource compliance operation
    Author: Wes Ellis (wes@wesellis.com)

    Audits Azure resource compliance against policies

    Evaluates resources against Azure Policy assignments and generates compliance reports.
    Supports multiple output formats and remediation tracking.
.parameter SubscriptionId
    Target subscription ID (optional, uses current context if not specified)
.parameter ResourceGroup
    Limit audit to specific resource group
.parameter OutputFormat
    Report format: JSON, CSV, HTML (default: JSON)
.parameter ExportPath
    Path for report file (optional, auto-generates if not specified)

    .\audit-resource-compliance.ps1 -OutputFormat CSV

    Audits current subscription and exports to CSV

    .\audit-resource-compliance.ps1 -ResourceGroup "RG-Production" -OutputFormat HTML

    Audits specific resource group with HTML report

    Author: Azure PowerShell Toolkit

[CmdletBinding()]
param(
    [parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [parameter(ValueFromPipeline)]`n    [string]$ResourceGroup,

    [parameter()]
    [ValidateSet('JSON', 'CSV', 'HTML')]
    [string]$OutputFormat = 'JSON',

    [parameter(ValueFromPipeline)]`n    [string]$ExportPath,

    [parameter()]
    [switch]$IncludeRemediation,

    [parameter()]
    [switch]$DetailedReport
)
    [string]$ErrorActionPreference = 'Stop'
try { } catch { throw }


[OutputType([bool])] 
 {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Not connected to Azure. Initiating login..." -ForegroundColor Green
        Connect-AzAccount
    $context = Get-AzContext
    }

    if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
        Write-Host "Switching to subscription: $SubscriptionId" -ForegroundColor Green
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
    [string]$params['ResourceGroupName'] = $ResourceGroupName
    }

    try {
    $states = Get-AzPolicyState @params
    [string]$compliance = foreach ($state in $states) {
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
        write-Error "Failed to retrieve policy compliance: $_"
        return @()
    }
}

function Get-ComplianceSummary {
        param(
        [array]$ComplianceData
    )
    [string]$total = $ComplianceData.Count
    [string]$compliant = ($ComplianceData | Where-Object IsCompliant).Count
    [string]$NonCompliant = $total - $compliant

    return [PSCustomObject]@{
        TotalResources = $total
        CompliantResources = $compliant
        NonCompliantResources = $NonCompliant
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
    [string]$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        }

        'CSV' {
    [string]$Details | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        }

        'HTML' {
    [string]$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Policy Compliance Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; }
        h1 { color:
        .summary { background:
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 24px; font-weight: bold; }
        .compliant { color:
        .non-compliant { color:
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th { background:
        td { padding: 8px; border-bottom: 1px solid
        tr:hover { background:
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
    [string]$html += @"
            <tr>
                <td>$($resource.ResourceName)</td>
                <td>$($resource.ResourceType)</td>
                <td>$($resource.ResourceGroup)</td>
                <td>$($resource.PolicyAssignment)</td>
                <td class="non-compliant">$($resource.ComplianceState)</td>
            </tr>
"@
            }
    [string]$html += @"
        </tbody>
    </table>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
</body>
</html>
"@
    [string]$html | Out-File -FilePath $Path -Encoding UTF8
        }
    }
}

function Get-RemediationTasks {
        param(
        [array]$NonCompliantResources
    )
    [string]$tasks = foreach ($resource in $NonCompliantResources) {
        try {
    $remediation = Get-AzPolicyRemediation -Name $resource.PolicyAssignment -ErrorAction SilentlyContinue

            [PSCustomObject]@{
                ResourceId = $resource.ResourceId
                PolicyAssignment = $resource.PolicyAssignment
                RemediationExists = $null -ne $remediation
                RemediationState = if ($remediation) { $remediation.ProvisioningState } else { 'Not Started' }

} catch {
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


Write-Host "`nAzure Policy Compliance Audit" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan
    [string]$context = Test-AzureConnection
Write-Host "Connected to subscription: $($context.Subscription.Name)" -ForegroundColor Green

if (-not $ExportPath) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    [string]$extension = $OutputFormat.ToLower()
    [string]$ExportPath = ".\PolicyCompliance_$timestamp.$extension"
}

Write-Host "`nRetrieving compliance data..." -ForegroundColor Green
    $ComplianceData = Get-PolicyCompliance -ResourceGroupName $ResourceGroup

if ($ComplianceData.Count -eq 0) {
    write-Warning "No policy compliance data found"
    exit 0
}

Write-Host "Retrieved $($ComplianceData.Count) policy states" -ForegroundColor Green
    $summary = Get-ComplianceSummary -ComplianceData $ComplianceData

Write-Host "`nCompliance Summary:" -ForegroundColor Green
Write-Output "Total Resources: $($summary.TotalResources)"
Write-Host "Compliant: $($summary.CompliantResources)" -ForegroundColor Green
Write-Output "Non-Compliant: $($summary.NonCompliantResources)" -ForegroundColor $(if ($summary.NonCompliantResources -gt 0) { 'Red' } else { 'Green' })
Write-Output "Compliance Rate: $($summary.CompliancePercentage)%`n"

if ($DetailedReport) {
    Write-Host "Resource Type Breakdown:" -ForegroundColor Green
    [string]$summary.ByResourceType | Format-Table -AutoSize

    Write-Host "Policy Assignment Breakdown:" -ForegroundColor Green
    [string]$summary.ByPolicy | Select-Object -First 10 | Format-Table -AutoSize
}
    [string]$RemediationTasks = @()
if ($IncludeRemediation) {
    Write-Host "Checking remediation status..." -ForegroundColor Green
    [string]$NonCompliant = $ComplianceData | Where-Object { -not $_.IsCompliant }
    $RemediationTasks = Get-RemediationTasks -NonCompliantResources $NonCompliant
    [string]$AvailableRemediations = ($RemediationTasks | Where-Object RemediationExists).Count
    Write-Host "Remediation available for $AvailableRemediations of $($NonCompliant.Count) non-compliant resources" -ForegroundColor Green
}

Write-Host "`nExporting report to: $ExportPath" -ForegroundColor Green
Export-ComplianceReport -Summary $summary -Details $ComplianceData -Format $OutputFormat -Path $ExportPath
Write-Host "Report exported successfully" -ForegroundColor Green

if ($summary.NonCompliantResources -gt 0) {
    Write-Host "`nAction Required: $($summary.NonCompliantResources) resources need attention" -ForegroundColor Green
}
else {
    Write-Host "`nAll resources are compliant!" -ForegroundColor Green}
