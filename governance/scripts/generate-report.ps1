#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    generate report
.DESCRIPTION
    generate report operation
    Author: Wes Ellis (wes@wesellis.com)

    Generates

    Creates detailed reports covering resource compliance, policy assignments,
    role assignments, resource locks, and activity logs. Supports multiple
    output formats and automated scheduling.
.parameter ReportType
    Type of report: Compliance, Security, Inventory, Activity, Custom
.parameter SubscriptionId
    Target subscription (uses current context if not specified)
.parameter ResourceGroupName
    Limit report to specific resource group
.parameter OutputFormat
    Report format: HTML, JSON, CSV, Excel
.parameter OutputPath
    Custom output path for report files
.parameter TimeRange
    Time range for activity reports: 1h, 6h, 24h, 7d, 30d
.parameter IncludeCharts
    Include visual charts in HTML reports
.parameter EmailRecipients
    Email addresses for report distribution
.parameter Compress
    Create compressed archive of all reports

    .\generate-report.ps1 -ReportType Compliance -OutputFormat HTML

    Generate HTML compliance report for current subscription

    .\generate-report.ps1 -ReportType Security -ResourceGroupName "RG-Prod" -IncludeCharts

    Generate security report for production resource group with charts

[CmdletBinding()]
param(
    [parameter(Mandatory = $true)]
    [ValidateSet('Compliance', 'Security', 'Inventory', 'Activity', 'Custom')]
    [string]$ReportType,

    [parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [parameter()]
    [string]$ResourceGroupName,

    [parameter()]
    [ValidateSet('HTML', 'JSON', 'CSV', 'Excel')]
    [string]$OutputFormat = 'HTML',

    [parameter()]
    [string]$OutputPath,

    [parameter()]
    [ValidateSet('1h', '6h', '24h', '7d', '30d')]
    [string]$TimeRange = '24h',

    [parameter()]
    [switch]$IncludeCharts,

    [parameter()]
    [string[]]$EmailRecipients,

    [parameter()]
    [switch]$Compress
)
    [string]$ErrorActionPreference = 'Stop'

[OutputType([PSCustomObject])] 
 {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
        Connect-AzAccount
    $context = Get-AzContext
    }

    if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
        Write-Host "Switching to subscription: $SubscriptionId" -ForegroundColor Green
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }

    return $context
}

function Get-ComplianceData {
        param([string]$ResourceGroup)

    Write-Host "Gathering compliance data..." -ForegroundColor Green
    $params = @{
        Top = 5000
    }
    if ($ResourceGroup) {
    [string]$params['ResourceGroupName'] = $ResourceGroup
    }

    try {
    $PolicyStates = Get-AzPolicyState @params
    $assignments = Get-AzPolicyAssignment

        return @{
            PolicyStates = $PolicyStates
            Assignments = $assignments
            Summary = @{
                TotalResources = $PolicyStates.Count
                CompliantResources = ($PolicyStates | Where-Object IsCompliant).Count
                NonCompliantResources = ($PolicyStates | Where-Object { -not $_.IsCompliant }).Count
                TotalPolicies = $assignments.Count
            }

} catch {
        write-Warning "Failed to retrieve compliance data: $_"
        return @{
            PolicyStates = @()
            Assignments = @()
            Summary = @{
                TotalResources = 0
                CompliantResources = 0
                NonCompliantResources = 0
                TotalPolicies = 0
            }
        }
    }
}

function Get-SecurityData {
        param([string]$ResourceGroup)

    Write-Host "Gathering security data..." -ForegroundColor Green

    try {
    [string]$params = if ($ResourceGroup) { @{ ResourceGroupName = $ResourceGroup } } else { @{} }
    $RoleAssignments = Get-AzRoleAssignment @params
    $locks = Get-AzResourceLock @params
    $nsgs = Get-AzNetworkSecurityGroup @params

        return @{
            RoleAssignments = $RoleAssignments
            ResourceLocks = $locks
            NetworkSecurityGroups = $nsgs
            Summary = @{
                TotalRoleAssignments = $RoleAssignments.Count
                TotalLocks = $locks.Count
                TotalNSGs = $nsgs.Count
                UnprotectedResources = 0
            }

} catch {
        write-Warning "Failed to retrieve security data: $_"
        return @{
            RoleAssignments = @()
            ResourceLocks = @()
            NetworkSecurityGroups = @()
            Summary = @{
                TotalRoleAssignments = 0
                TotalLocks = 0
                TotalNSGs = 0
                UnprotectedResources = 0
            }
        }
    }
}

function Get-InventoryData {
        param([string]$ResourceGroup)

    Write-Host "Gathering inventory data..." -ForegroundColor Green

    try {
    [string]$params = if ($ResourceGroup) { @{ ResourceGroupName = $ResourceGroup } } else { @{} }
    $resources = Get-AzResource @params
    [string]$GroupedByType = $resources | Group-Object ResourceType
    [string]$GroupedByLocation = $resources | Group-Object Location
    [string]$GroupedByRG = $resources | Group-Object ResourceGroupName

        return @{
            Resources = $resources
            ByType = $GroupedByType
            ByLocation = $GroupedByLocation
            ByResourceGroup = $GroupedByRG
            Summary = @{
                TotalResources = $resources.Count
                UniqueTypes = $GroupedByType.Count
                UniqueLocations = $GroupedByLocation.Count
                ResourceGroups = $GroupedByRG.Count
            }

} catch {
        write-Warning "Failed to retrieve inventory data: $_"
        return @{
            Resources = @()
            ByType = @()
            ByLocation = @()
            ByResourceGroup = @()
            Summary = @{
                TotalResources = 0
                UniqueTypes = 0
                UniqueLocations = 0
                ResourceGroups = 0
            }
        }
    }
}

function Get-ActivityData {
        param(
        [string]$ResourceGroup,
        [string]$TimeRange
    )

    Write-Host "Gathering activity data..." -ForegroundColor Green
    [string]$StartTime = switch ($TimeRange) {
        '1h' { (Get-Date).AddHours(-1) }
        '6h' { (Get-Date).AddHours(-6) }
        '24h' { (Get-Date).AddDays(-1) }
        '7d' { (Get-Date).AddDays(-7) }
        '30d' { (Get-Date).AddDays(-30) }
        default { (Get-Date).AddDays(-1) }
    }

    try {
    $params = @{
            StartTime = $StartTime
            EndTime = Get-Date
        }
        if ($ResourceGroup) {
    [string]$params['ResourceGroupName'] = $ResourceGroup
        }
    $activities = Get-AzActivityLog @params

        return @{
            Activities = $activities
            Summary = @{
                TotalEvents = $activities.Count
                ErrorEvents = ($activities | Where-Object Level -eq 'Error').Count
                WarningEvents = ($activities | Where-Object Level -eq 'Warning').Count
                TimeRange = $TimeRange
                StartTime = $StartTime
                EndTime = Get-Date
            }

} catch {
        write-Warning "Failed to retrieve activity data: $_"
        return @{
            Activities = @()
            Summary = @{
                TotalEvents = 0
                ErrorEvents = 0
                WarningEvents = 0
                TimeRange = $TimeRange
                StartTime = $StartTime
                EndTime = Get-Date
            }
        }
    }
}

function New-HTMLReport {
        param(
        [hashtable]$Data,
        [string]$ReportType,
        [string]$FilePath,
        [bool]$IncludeCharts
    )
    [string]$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure $ReportType Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg,
        .header h1 { margin: 0; font-size: 2.5em; font-weight: 300; }
        .header .subtitle { opacity: 0.9; margin-top: 10px; font-size: 1.1em; }
        .content { padding: 30px; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .summary-card { background:
        .summary-card h3 { margin: 0 0 10px 0; color:
        .summary-card .value { font-size: 2.5em; font-weight: bold; color:
        .section { margin-bottom: 40px; }
        .section h2 { color:
        table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; }
        th { background:
        td { padding: 12px; border-bottom: 1px solid
        tr:hover { background:
        .status-compliant { color:
        .status-non-compliant { color:
        .status-warning { color:
        .footer { background:
        .chart-container { margin: 20px 0; padding: 20px; background:
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Azure $ReportType Report</h1>
            <div class="subtitle">Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')</div>
            <div class="subtitle">Subscription: $((Get-AzContext).Subscription.Name)</div>
        </div>
        <div class="content">
"@

    switch ($ReportType) {
        'Compliance' {
    [string]$html += @"
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Total Resources</h3>
                    <div class="value">$($Data.Summary.TotalResources)</div>
                </div>
                <div class="summary-card">
                    <h3>Compliant</h3>
                    <div class="value status-compliant">$($Data.Summary.CompliantResources)</div>
                </div>
                <div class="summary-card">
                    <h3>Non-Compliant</h3>
                    <div class="value status-non-compliant">$($Data.Summary.NonCompliantResources)</div>
                </div>
                <div class="summary-card">
                    <h3>Compliance Rate</h3>
                    <div class="value">$(if ($Data.Summary.TotalResources -gt 0) { [Math]::Round(($Data.Summary.CompliantResources / $Data.Summary.TotalResources) * 100, 1) } else { 0 })%</div>
                </div>
            </div>
"@
        }
        'Security' {
    [string]$html += @"
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Role Assignments</h3>
                    <div class="value">$($Data.Summary.TotalRoleAssignments)</div>
                </div>
                <div class="summary-card">
                    <h3>Resource Locks</h3>
                    <div class="value">$($Data.Summary.TotalLocks)</div>
                </div>
                <div class="summary-card">
                    <h3>Network Security Groups</h3>
                    <div class="value">$($Data.Summary.TotalNSGs)</div>
                </div>
                <div class="summary-card">
                    <h3>Unprotected Resources</h3>
                    <div class="value status-warning">$($Data.Summary.UnprotectedResources)</div>
                </div>
            </div>
"@
        }
        'Inventory' {
    [string]$html += @"
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Total Resources</h3>
                    <div class="value">$($Data.Summary.TotalResources)</div>
                </div>
                <div class="summary-card">
                    <h3>Resource Types</h3>
                    <div class="value">$($Data.Summary.UniqueTypes)</div>
                </div>
                <div class="summary-card">
                    <h3>Locations</h3>
                    <div class="value">$($Data.Summary.UniqueLocations)</div>
                </div>
                <div class="summary-card">
                    <h3>Resource Groups</h3>
                    <div class="value">$($Data.Summary.ResourceGroups)</div>
                </div>
            </div>
"@
        }
        'Activity' {
    [string]$html += @"
            <div class="summary-grid">
                <div class="summary-card">
                    <h3>Total Events</h3>
                    <div class="value">$($Data.Summary.TotalEvents)</div>
                </div>
                <div class="summary-card">
                    <h3>Error Events</h3>
                    <div class="value status-non-compliant">$($Data.Summary.ErrorEvents)</div>
                </div>
                <div class="summary-card">
                    <h3>Warning Events</h3>
                    <div class="value status-warning">$($Data.Summary.WarningEvents)</div>
                </div>
                <div class="summary-card">
                    <h3>Time Range</h3>
                    <div class="value">$($Data.Summary.TimeRange)</div>
                </div>
            </div>
"@
        }
    }
    [string]$html += @"
        </div>
        <div class="footer">
        </div>
    </div>
</body>
</html>
"@
    [string]$html | Out-File -FilePath $FilePath -Encoding UTF8
    Write-Host "HTML report saved: $FilePath" -ForegroundColor Green
}

function Export-ReportData {
        param(
        [hashtable]$Data,
        [string]$Format,
        [string]$FilePath
    )

    switch ($Format) {
        'JSON' {
    [string]$Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $FilePath -Encoding UTF8
        }
        'CSV' {
            if ($Data.PolicyStates) {
    [string]$Data.PolicyStates | Export-Csv -Path $FilePath -NoTypeInformation
            } elseif ($Data.Resources) {
    [string]$Data.Resources | Export-Csv -Path $FilePath -NoTypeInformation
            } elseif ($Data.Activities) {
    [string]$Data.Activities | Export-Csv -Path $FilePath -NoTypeInformation
            }
        }
        'Excel' {
            write-Warning "Excel export requires additional modules. Saving as CSV instead."
    [string]$CsvPath = $FilePath -replace '\.xlsx$', '.csv'
            Export-ReportData -Data $Data -Format 'CSV' -FilePath $CsvPath
        }
    }

    Write-Host "$Format report saved: $FilePath" -ForegroundColor Green
}

function New-ReportArchive {
        param(
        [string[]]$FilePaths,
        [string]$ArchivePath
    )

    try {
        if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
            Compress-Archive -Path $FilePaths -DestinationPath $ArchivePath -Force
            Write-Host "Report archive created: $ArchivePath" -ForegroundColor Green
        } else {
            write-Warning "Compress-Archive not available. Skipping archive creation."

} catch {
        write-Warning "Failed to create archive: $_"
    }
}

Write-Host "`nAzure Governance Report Generator" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan
    [string]$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

if (-not $OutputPath) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    [string]$OutputPath = ".\Reports\Azure_${ReportType}_Report_$timestamp"
}
    [string]$OutputDir = Split-Path $OutputPath -Parent
if ($OutputDir -and -not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
    [string]$ReportData = switch ($ReportType) {
    'Compliance' { Get-ComplianceData -ResourceGroup $ResourceGroupName }
    'Security' { Get-SecurityData -ResourceGroup $ResourceGroupName }
    'Inventory' { Get-InventoryData -ResourceGroup $ResourceGroupName }
    'Activity' { Get-ActivityData -ResourceGroup $ResourceGroupName -TimeRange $TimeRange }
    'Custom' {
        @{
            Compliance = Get-ComplianceData -ResourceGroup $ResourceGroupName
            Security = Get-SecurityData -ResourceGroup $ResourceGroupName
            Inventory = Get-InventoryData -ResourceGroup $ResourceGroupName
            Activity = Get-ActivityData -ResourceGroup $ResourceGroupName -TimeRange $TimeRange
        }
    }
}
    [string]$ReportFiles = @()
    [string]$PrimaryFile = "$OutputPath.$($OutputFormat.ToLower())"
switch ($OutputFormat) {
    'HTML' {
        New-HTMLReport -Data $ReportData -ReportType $ReportType -FilePath $PrimaryFile -IncludeCharts $IncludeCharts
    }
    default {
        Export-ReportData -Data $ReportData -Format $OutputFormat -FilePath $PrimaryFile
    }
}
    [string]$ReportFiles += $PrimaryFile

if ($OutputFormat -ne 'JSON') {
    [string]$JsonFile = "$OutputPath.json"
    Export-ReportData -Data $ReportData -Format 'JSON' -FilePath $JsonFile
    [string]$ReportFiles += $JsonFile
}

if ($Compress) {
    [string]$ArchivePath = "$OutputPath.zip"
    New-ReportArchive -FilePaths $ReportFiles -ArchivePath $ArchivePath
}

if ($EmailRecipients) {
    Write-Host "`nWould email reports to: $($EmailRecipients -join ', ')" -ForegroundColor Green
    Write-Host "Email functionality requires additional configuration" -ForegroundColor Green
}

Write-Host "`nReport generation completed!" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Green
    [string]$ReportFiles | ForEach-Object {
    Write-Host "  - $_" -ForegroundColor Green
}\n



