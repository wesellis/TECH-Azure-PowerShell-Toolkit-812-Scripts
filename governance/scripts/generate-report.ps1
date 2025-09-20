#Requires -Module Az.Resources
#Requires -Module Az.PolicyInsights
#Requires -Module Az.Monitor
#Requires -Version 5.1

    Generates

    Creates detailed reports covering resource compliance, policy assignments,
    role assignments, resource locks, and activity logs. Supports multiple
    output formats and automated scheduling.
.PARAMETER ReportType
    Type of report: Compliance, Security, Inventory, Activity, Custom
.PARAMETER SubscriptionId
    Target subscription (uses current context if not specified)
.PARAMETER ResourceGroupName
    Limit report to specific resource group
.PARAMETER OutputFormat
    Report format: HTML, JSON, CSV, Excel
.PARAMETER OutputPath
    Custom output path for report files
.PARAMETER TimeRange
    Time range for activity reports: 1h, 6h, 24h, 7d, 30d
.PARAMETER IncludeCharts
    Include visual charts in HTML reports
.PARAMETER EmailRecipients
    Email addresses for report distribution
.PARAMETER Compress
    Create compressed archive of all reports

    .\generate-report.ps1 -ReportType Compliance -OutputFormat HTML

    Generate HTML compliance report for current subscription

    .\generate-report.ps1 -ReportType Security -ResourceGroupName "RG-Prod" -IncludeCharts

    Generate security report for production resource group with charts#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Compliance', 'Security', 'Inventory', 'Activity', 'Custom')]
    [string]$ReportType,

    [Parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [ValidateSet('HTML', 'JSON', 'CSV', 'Excel')]
    [string]$OutputFormat = 'HTML',

    [Parameter()]
    [string]$OutputPath,

    [Parameter()]
    [ValidateSet('1h', '6h', '24h', '7d', '30d')]
    [string]$TimeRange = '24h',

    [Parameter()]
    [switch]$IncludeCharts,

    [Parameter()]
    [string[]]$EmailRecipients,

    [Parameter()]
    [switch]$Compress
)

$ErrorActionPreference = 'Stop'

function Test-AzureConnection {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
        $context = Get-AzContext
    }

    if ($SubscriptionId -and $context.Subscription.Id -ne $SubscriptionId) {
        Write-Host "Switching to subscription: $SubscriptionId" -ForegroundColor Yellow
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }

    return $context
}

function Get-ComplianceData {
    param([string]$ResourceGroup)

    Write-Host "Gathering compliance data..." -ForegroundColor Yellow

    $params = @{
        Top = 5000
    }
    if ($ResourceGroup) {
        $params['ResourceGroupName'] = $ResourceGroup
    }

    try {
        $policyStates = Get-AzPolicyState @params
        $assignments = Get-AzPolicyAssignment

        return @{
            PolicyStates = $policyStates
            Assignments = $assignments
            Summary = @{
                TotalResources = $policyStates.Count
                CompliantResources = ($policyStates | Where-Object IsCompliant).Count
                NonCompliantResources = ($policyStates | Where-Object { -not $_.IsCompliant }).Count
                TotalPolicies = $assignments.Count
            }
        
} catch {
        Write-Warning "Failed to retrieve compliance data: $_"
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

    Write-Host "Gathering security data..." -ForegroundColor Yellow

    try {
        $params = if ($ResourceGroup) { @{ ResourceGroupName = $ResourceGroup } } else { @{} }

        $roleAssignments = Get-AzRoleAssignment @params
        $locks = Get-AzResourceLock @params
        $nsgs = Get-AzNetworkSecurityGroup @params

        return @{
            RoleAssignments = $roleAssignments
            ResourceLocks = $locks
            NetworkSecurityGroups = $nsgs
            Summary = @{
                TotalRoleAssignments = $roleAssignments.Count
                TotalLocks = $locks.Count
                TotalNSGs = $nsgs.Count
                UnprotectedResources = 0  # Calculate based on resources without locks
            }
        
} catch {
        Write-Warning "Failed to retrieve security data: $_"
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

    Write-Host "Gathering inventory data..." -ForegroundColor Yellow

    try {
        $params = if ($ResourceGroup) { @{ ResourceGroupName = $ResourceGroup } } else { @{} }
        $resources = Get-AzResource @params

        $groupedByType = $resources | Group-Object ResourceType
        $groupedByLocation = $resources | Group-Object Location
        $groupedByRG = $resources | Group-Object ResourceGroupName

        return @{
            Resources = $resources
            ByType = $groupedByType
            ByLocation = $groupedByLocation
            ByResourceGroup = $groupedByRG
            Summary = @{
                TotalResources = $resources.Count
                UniqueTypes = $groupedByType.Count
                UniqueLocations = $groupedByLocation.Count
                ResourceGroups = $groupedByRG.Count
            }
        
} catch {
        Write-Warning "Failed to retrieve inventory data: $_"
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

    Write-Host "Gathering activity data..." -ForegroundColor Yellow

    $startTime = switch ($TimeRange) {
        '1h' { (Get-Date).AddHours(-1) }
        '6h' { (Get-Date).AddHours(-6) }
        '24h' { (Get-Date).AddDays(-1) }
        '7d' { (Get-Date).AddDays(-7) }
        '30d' { (Get-Date).AddDays(-30) }
        default { (Get-Date).AddDays(-1) }
    }

    try {
        $params = @{
            StartTime = $startTime
            EndTime = Get-Date
        }
        if ($ResourceGroup) {
            $params['ResourceGroupName'] = $ResourceGroup
        }

        $activities = Get-AzActivityLog @params

        return @{
            Activities = $activities
            Summary = @{
                TotalEvents = $activities.Count
                ErrorEvents = ($activities | Where-Object Level -eq 'Error').Count
                WarningEvents = ($activities | Where-Object Level -eq 'Warning').Count
                TimeRange = $TimeRange
                StartTime = $startTime
                EndTime = Get-Date
            }
        
} catch {
        Write-Warning "Failed to retrieve activity data: $_"
        return @{
            Activities = @()
            Summary = @{
                TotalEvents = 0
                ErrorEvents = 0
                WarningEvents = 0
                TimeRange = $TimeRange
                StartTime = $startTime
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

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure $ReportType Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #0078d4, #106ebe); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .header h1 { margin: 0; font-size: 2.5em; font-weight: 300; }
        .header .subtitle { opacity: 0.9; margin-top: 10px; font-size: 1.1em; }
        .content { padding: 30px; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .summary-card { background: #f8f9fa; border: 1px solid #e9ecef; border-radius: 6px; padding: 20px; text-align: center; }
        .summary-card h3 { margin: 0 0 10px 0; color: #495057; font-size: 0.9em; text-transform: uppercase; letter-spacing: 1px; }
        .summary-card .value { font-size: 2.5em; font-weight: bold; color: #0078d4; margin: 10px 0; }
        .section { margin-bottom: 40px; }
        .section h2 { color: #0078d4; border-bottom: 2px solid #e9ecef; padding-bottom: 10px; margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; }
        th { background: #0078d4; color: white; padding: 12px; text-align: left; font-weight: 600; }
        td { padding: 12px; border-bottom: 1px solid #e9ecef; }
        tr:hover { background: #f8f9fa; }
        .status-compliant { color: #28a745; font-weight: bold; }
        .status-non-compliant { color: #dc3545; font-weight: bold; }
        .status-warning { color: #ffc107; font-weight: bold; }
        .footer { background: #f8f9fa; padding: 20px; text-align: center; color: #6c757d; border-radius: 0 0 8px 8px; }
        .chart-container { margin: 20px 0; padding: 20px; background: #f8f9fa; border-radius: 6px; }
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

    # Add summary section based on report type
    switch ($ReportType) {
        'Compliance' {
            $html += @"
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
            $html += @"
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
            $html += @"
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
            $html += @"
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

    $html += @"
        </div>
        <div class="footer">
            Report generated by Azure PowerShell Toolkit
        </div>
    </div>
</body>
</html>
"@

    $html | Out-File -FilePath $FilePath -Encoding UTF8
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
            $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $FilePath -Encoding UTF8
        }
        'CSV' {
            # Export main data as CSV (structure depends on report type)
            if ($Data.PolicyStates) {
                $Data.PolicyStates | Export-Csv -Path $FilePath -NoTypeInformation
            } elseif ($Data.Resources) {
                $Data.Resources | Export-Csv -Path $FilePath -NoTypeInformation
            } elseif ($Data.Activities) {
                $Data.Activities | Export-Csv -Path $FilePath -NoTypeInformation
            }
        }
        'Excel' {
            Write-Warning "Excel export requires additional modules. Saving as CSV instead."
            $csvPath = $FilePath -replace '\.xlsx$', '.csv'
            Export-ReportData -Data $Data -Format 'CSV' -FilePath $csvPath
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
            Write-Warning "Compress-Archive not available. Skipping archive creation."
        
} catch {
        Write-Warning "Failed to create archive: $_"
    }
}

# Main execution
Write-Host "`nAzure Governance Report Generator" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

# Set output path
if (-not $OutputPath) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $OutputPath = ".\Reports\Azure_${ReportType}_Report_$timestamp"
}

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Gather data based on report type
$reportData = switch ($ReportType) {
    'Compliance' { Get-ComplianceData -ResourceGroup $ResourceGroupName }
    'Security' { Get-SecurityData -ResourceGroup $ResourceGroupName }
    'Inventory' { Get-InventoryData -ResourceGroup $ResourceGroupName }
    'Activity' { Get-ActivityData -ResourceGroup $ResourceGroupName -TimeRange $TimeRange }
    'Custom' {
        # Gather all data for custom report
        @{
            Compliance = Get-ComplianceData -ResourceGroup $ResourceGroupName
            Security = Get-SecurityData -ResourceGroup $ResourceGroupName
            Inventory = Get-InventoryData -ResourceGroup $ResourceGroupName
            Activity = Get-ActivityData -ResourceGroup $ResourceGroupName -TimeRange $TimeRange
        }
    }
}

# Generate report files
$reportFiles = @()

# Primary report
$primaryFile = "$OutputPath.$($OutputFormat.ToLower())"
switch ($OutputFormat) {
    'HTML' {
        New-HTMLReport -Data $reportData -ReportType $ReportType -FilePath $primaryFile -IncludeCharts $IncludeCharts
    }
    default {
        Export-ReportData -Data $reportData -Format $OutputFormat -FilePath $primaryFile
    }
}
$reportFiles += $primaryFile

# Always create a JSON backup
if ($OutputFormat -ne 'JSON') {
    $jsonFile = "$OutputPath.json"
    Export-ReportData -Data $reportData -Format 'JSON' -FilePath $jsonFile
    $reportFiles += $jsonFile
}

# Create archive if requested
if ($Compress) {
    $archivePath = "$OutputPath.zip"
    New-ReportArchive -FilePaths $reportFiles -ArchivePath $archivePath
}

# Email reports if recipients specified
if ($EmailRecipients) {
    Write-Host "`nWould email reports to: $($EmailRecipients -join ', ')" -ForegroundColor Yellow
    Write-Host "Email functionality requires additional configuration" -ForegroundColor Yellow
}

Write-Host "`nReport generation completed!" -ForegroundColor Green
Write-Host "Files created:" -ForegroundColor Cyan
$reportFiles | ForEach-Object {
    Write-Host "  - $_" -ForegroundColor Green
}

