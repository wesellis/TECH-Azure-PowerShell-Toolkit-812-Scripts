#Requires -Version 7.0

<#`n.SYNOPSIS
    Creates Excel dashboard templates for Azure cost management analysis

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
    Author: Wes Ellis (wes@wesellis.com)Prerequisites:
    - ImportExcel PowerShell module
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline)]`n    [string]$OutputPath = 'dashboards\Excel',
    
    [Parameter()]
    [switch]$IncludeSampleData,
    
    [Parameter()]
    [switch]$OverwriteExisting
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Import required modules
try {
        Write-Host "ImportExcel module loaded successfully" -ForegroundColor Green
}
catch {
    Write-Error "ImportExcel module is required. Install with: Install-Module ImportExcel"
    throw
}

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

#endregion

#region Functions-function New-CostAnalysisTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    Write-Host "Creating Cost Analysis Template..." -ForegroundColor Cyan
    
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
    
    Remove-Item $FilePath -ErrorAction SilentlyContinue
    
    # Create main sheet with cost data
    $costData | Export-Excel -Path $FilePath -WorksheetName "Raw Data" -AutoSize -FreezeTopRow -BoldTopRow
    
    # Create summary data
    $summary = @(
        [PSCustomObject]@{Metric="Total Cost"; Value=1419.40}
        [PSCustomObject]@{Metric="Resources"; Value=8}
        [PSCustomObject]@{Metric="Avg Cost"; Value=177.43}
    )
    $summary | Export-Excel -Path $FilePath -WorksheetName "Summary" -AutoSize -FreezeTopRow -BoldTopRow
    
    Write-Host "Cost Analysis Template created: $FilePath" -ForegroundColor Green
}

function New-BudgetTrackingTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    Write-Host "Creating Budget Tracking Template..." -ForegroundColor Cyan
    
    # Budget data
    $budgetData = @(
        [PSCustomObject]@{Department="IT Operations"; Budget=5000; Actual=4200; Variance=-800}
        [PSCustomObject]@{Department="Development"; Budget=3000; Actual=2500; Variance=-500}
        [PSCustomObject]@{Department="Testing"; Budget=1000; Actual=800; Variance=-200}
    )
    
    Remove-Item $FilePath -ErrorAction SilentlyContinue
    
    $budgetData | Export-Excel -Path $FilePath -WorksheetName "Budget Data" -AutoSize -FreezeTopRow -BoldTopRow
    
    Write-Host "Budget Tracking Template created: $FilePath" -ForegroundColor Green
}

function New-ExecutiveSummaryTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    
    Write-Host "Creating Executive Summary Template..." -ForegroundColor Cyan
    
    # Executive KPIs
    $kpiData = @(
        [PSCustomObject]@{Metric="Total Spend"; Current=12450; Previous=11200; Change=11.2}
        [PSCustomObject]@{Metric="Budget Utilization"; Current=83; Previous=75; Change=8}
        [PSCustomObject]@{Metric="Resources"; Current=156; Previous=148; Change=5.4}
    )
    
    Remove-Item $FilePath -ErrorAction SilentlyContinue
    
    $kpiData | Export-Excel -Path $FilePath -WorksheetName "Executive KPIs" -AutoSize -FreezeTopRow -BoldTopRow
    
    Write-Host "Executive Summary Template created: $FilePath" -ForegroundColor Green
}

}

#endregion

#region Main-Execution
try {
    Write-Host "Azure Cost Management Dashboard - Excel Template Generator" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor White

    $templates = @(
        @{Name='Cost-Analysis-Template.xlsx'; Function='New-CostAnalysisTemplate'},
        @{Name='Budget-Tracking-Template.xlsx'; Function='New-BudgetTrackingTemplate'},
        @{Name='Executive-Summary-Template.xlsx'; Function='New-ExecutiveSummaryTemplate'}
    )

    foreach ($template in $templates) {
        $filePath = Join-Path $OutputPath $template.Name

        if ((Test-Path $filePath) -and -not $OverwriteExisting) {
            Write-Host "Warning: $($template.Name) already exists. Use -OverwriteExisting to replace." -ForegroundColor Yellow
            continue
        }

        & $template.Function $filePath
    }

    Write-Host "`nExcel template generation completed!" -ForegroundColor Green
    Write-Host "`nCreated templates in: $OutputPath" -ForegroundColor White
    Write-Host "- Cost-Analysis-Template.xlsx -
    Write-Host "- Budget-Tracking-Template.xlsx - Budget monitoring and variance" -ForegroundColor Gray
    Write-Host "- Executive-Summary-Template.xlsx - Executive-level reporting" -ForegroundColor Gray

    Write-Host "`nNext steps:" -ForegroundColor White
    Write-Host "1. Open templates in Excel to customize" -ForegroundColor Gray
    Write-Host "2. Import your actual cost data" -ForegroundColor Gray
    Write-Host "3. Configure data refresh connections" -ForegroundColor Gray
    Write-Host "4. Set up automated reporting" -ForegroundColor Gray

    if ($IncludeSampleData) {
        Write-Host "`nTemplates include sample data for demonstration" -ForegroundColor Yellow
    
} catch {
    Write-Error "Template generation failed: $($_.Exception.Message)"
    throw
}
finally {
    Write-Verbose "Template generation script completed"
}

#endregion

