<#
.SYNOPSIS
    Creates Excel dashboard templates for Azure cost management analysis.

.DESCRIPTION
    This script automatically generates professional Excel templates with proper
    formatting, formulas, charts, and sample data for Azure cost management.

.PARAMETER OutputPath
    Directory where Excel templates will be created. Defaults to dashboards\Excel.

.PARAMETER IncludeSampleData
    Include sample data in the templates for demonstration purposes.

.PARAMETER OverwriteExisting
    Overwrite existing template files if they exist.

.EXAMPLE
    .\Create-ExcelTemplates.ps1

.EXAMPLE
    .\Create-ExcelTemplates.ps1 -IncludeSampleData -OverwriteExisting

.NOTES
    Author: Wesley Ellis
    Email: wes@wesellis.com
    Created: May 23, 2025
    Version: 1.0

    Prerequisites:
    - ImportExcel PowerShell module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "dashboards\Excel",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSampleData,
    
    [Parameter(Mandatory = $false)]
    [switch]$OverwriteExisting
)

# Import required modules
try {
    Import-Module ImportExcel -Force
    Write-Information "ImportExcel module loaded successfully"
}
catch {
    Write-Error "ImportExcel module is required. Install with: Install-Module ImportExcel"
    exit 1
}

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

[CmdletBinding()]
function New-CostAnalysisTemplate -ErrorAction Stop {
    param([string]$FilePath)
    
    Write-Information "Creating Cost Analysis Template..."
    
    # Sample cost data
    $costData = @(
        [PSCustomObject]@{Date="2025-05-01"; ResourceGroup="Production-RG"; ServiceName="Virtual Machines"; Cost=245.50; Location="East US"}
        [PSCustomObject]@{Date="2025-05-01"; ResourceGroup="Production-RG"; ServiceName="Storage Accounts"; Cost=89.25; Location="East US"}
        [PSCustomObject]@{Date="2025-05-01"; ResourceGroup="Production-RG"; ServiceName="SQL Database"; Cost=458.75; Location="East US"}
        [PSCustomObject]@{Date="2025-05-01"; ResourceGroup="Development-RG"; ServiceName="Virtual Machines"; Cost=125.75; Location="West US"}
        [PSCustomObject]@{Date="2025-05-01"; ResourceGroup="Development-RG"; ServiceName="Storage Accounts"; Cost=34.50; Location="West US"}
        [PSCustomObject]@{Date="2025-05-02"; ResourceGroup="Production-RG"; ServiceName="Virtual Machines"; Cost=247.30; Location="East US"}
        [PSCustomObject]@{Date="2025-05-02"; ResourceGroup="Production-RG"; ServiceName="Storage Accounts"; Cost=91.15; Location="East US"}
        [PSCustomObject]@{Date="2025-05-02"; ResourceGroup="Development-RG"; ServiceName="Virtual Machines"; Cost=127.20; Location="West US"}
    )
    
    Remove-Item -ErrorAction Stop $FilePath -ErrorAction SilentlyContinue
    
    # Create main sheet with cost data
    $costData | Export-Excel -Path $FilePath -WorksheetName "Raw Data" -AutoSize -FreezeTopRow -BoldTopRow
    
    # Create summary data
    $summary = @(
        [PSCustomObject]@{Metric="Total Cost"; Value=1419.40}
        [PSCustomObject]@{Metric="Resources"; Value=8}
        [PSCustomObject]@{Metric="Avg Cost"; Value=177.43}
    )
    $summary | Export-Excel -Path $FilePath -WorksheetName "Summary" -AutoSize -FreezeTopRow -BoldTopRow
    
    Write-Information "Cost Analysis Template created: $FilePath"
}

[CmdletBinding()]
function New-BudgetTrackingTemplate -ErrorAction Stop {
    param([string]$FilePath)
    
    Write-Information "Creating Budget Tracking Template..."
    
    # Budget data
    $budgetData = @(
        [PSCustomObject]@{Department="IT Operations"; Budget=5000; Actual=4200; Variance=-800}
        [PSCustomObject]@{Department="Development"; Budget=3000; Actual=2500; Variance=-500}
        [PSCustomObject]@{Department="Testing"; Budget=1000; Actual=800; Variance=-200}
    )
    
    Remove-Item -ErrorAction Stop $FilePath -ErrorAction SilentlyContinue
    
    $budgetData | Export-Excel -Path $FilePath -WorksheetName "Budget Data" -AutoSize -FreezeTopRow -BoldTopRow
    
    Write-Information "Budget Tracking Template created: $FilePath"
}

[CmdletBinding()]
function New-ExecutiveSummaryTemplate -ErrorAction Stop {
    param([string]$FilePath)
    
    Write-Information "Creating Executive Summary Template..."
    
    # Executive KPIs
    $kpiData = @(
        [PSCustomObject]@{Metric="Total Spend"; Current=12450; Previous=11200; Change=11.2}
        [PSCustomObject]@{Metric="Budget Utilization"; Current=83; Previous=75; Change=8}
        [PSCustomObject]@{Metric="Resources"; Current=156; Previous=148; Change=5.4}
    )
    
    Remove-Item -ErrorAction Stop $FilePath -ErrorAction SilentlyContinue
    
    $kpiData | Export-Excel -Path $FilePath -WorksheetName "Executive KPIs" -AutoSize -FreezeTopRow -BoldTopRow
    
    Write-Information "Executive Summary Template created: $FilePath"
}

# Main execution
try {
    Write-Information "Azure Cost Management Dashboard - Excel Template Generator"
    Write-Information "============================================================"
    
    $templates = @(
        @{Name="Cost-Analysis-Template.xlsx"; Function="New-CostAnalysisTemplate"},
        @{Name="Budget-Tracking-Template.xlsx"; Function="New-BudgetTrackingTemplate"},
        @{Name="Executive-Summary-Template.xlsx"; Function="New-ExecutiveSummaryTemplate"}
    )
    
    foreach ($template in $templates) {
        $filePath = Join-Path $OutputPath $template.Name
        
        if ((Test-Path $filePath) -and -not $OverwriteExisting) {
            Write-Information "Warning: $($template.Name) already exists. Use -OverwriteExisting to replace."
            continue
        }
        
        & $template.Function $filePath
    }
    
    Write-Information ""
    Write-Information "Excel template generation completed!"
    Write-Information ""
    Write-Information "Created templates in: $OutputPath"
    Write-Information "- Cost-Analysis-Template.xlsx - Comprehensive cost analysis"
    Write-Information "- Budget-Tracking-Template.xlsx - Budget monitoring and variance"
    Write-Information "- Executive-Summary-Template.xlsx - Executive-level reporting"
    
    Write-Information ""
    Write-Information "Next steps:"
    Write-Information "1. Open templates in Excel to customize"
    Write-Information "2. Import your actual cost data"
    Write-Information "3. Configure data refresh connections"
    Write-Information "4. Set up automated reporting"
    
    if ($IncludeSampleData) {
        Write-Information ""
        Write-Information "Templates include sample data for demonstration"
    }
}
catch {
    Write-Error "Template generation failed: $($_.Exception.Message)"
    exit 1
}
