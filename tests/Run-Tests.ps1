#Requires -Version 7.0

<#
.SYNOPSIS
    Test runner for Azure PowerShell Toolkit

.DESCRIPTION
    Executes comprehensive test suite including unit tests, integration tests,
    and quality validation for the Azure PowerShell Toolkit.

.PARAMETER TestType
    Type of tests to run (All, Unit, Integration, Security, Quality)

.PARAMETER OutputFormat
    Output format for test results (Console, JUnit, HTML)

.PARAMETER PassThru
    Return test results object

.EXAMPLE
    .\Run-Tests.ps1
    Run all tests with console output

.EXAMPLE
    .\Run-Tests.ps1 -TestType Security -OutputFormat JUnit
    Run security tests with JUnit XML output

.NOTES
    Author: Azure PowerShell Toolkit Team
    Version: 1.0
    Requires: Pester 5.0+
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('All', 'Unit', 'Integration', 'Security', 'Quality')]
    [string]$TestType = 'All',

    [Parameter()]
    [ValidateSet('Console', 'JUnit', 'HTML')]
    [string]$OutputFormat = 'Console',

    [Parameter()]
    [switch]$PassThru
)

# Import required modules
try {
    Import-Module Pester -MinimumVersion 5.0.0 -Force -ErrorAction Stop
} catch {
    Write-Error "Pester 5.0+ is required. Install with: Install-Module -Name Pester -Force"
    exit 1
}

# Set up paths
$TestsPath = $PSScriptRoot
$ToolkitRoot = Split-Path -Parent $TestsPath
$ReportsPath = Join-Path $TestsPath "TestResults"

# Ensure reports directory exists
if (-not (Test-Path $ReportsPath)) {
    New-Item -Path $ReportsPath -ItemType Directory -Force | Out-Null
}

Write-Host "=== Azure PowerShell Toolkit Test Suite ===" -ForegroundColor Cyan
Write-Host "Test Type: $TestType" -ForegroundColor Green
Write-Host "Output Format: $OutputFormat" -ForegroundColor Green
Write-Host "Reports Path: $ReportsPath" -ForegroundColor Green
Write-Host ""

# Configure Pester
$PesterConfig = New-PesterConfiguration

# Set test discovery
$PesterConfig.Run.Path = $TestsPath
$PesterConfig.TestResult.Enabled = $true

# Configure tags based on test type
switch ($TestType) {
    'Security' {
        $PesterConfig.Filter.Tag = @('Security')
    }
    'Integration' {
        $PesterConfig.Filter.Tag = @('Integration')
    }
    'Unit' {
        $PesterConfig.Filter.ExcludeTag = @('Integration', 'Security')
    }
    'Quality' {
        $PesterConfig.Filter.Tag = @('Quality')
    }
    'All' {
        # Run all tests
    }
}

# Configure output
switch ($OutputFormat) {
    'JUnit' {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outputFile = Join-Path $ReportsPath "TestResults-$TestType-$timestamp.xml"
        $PesterConfig.TestResult.OutputFormat = 'JunitXml'
        $PesterConfig.TestResult.OutputPath = $outputFile
        Write-Host "JUnit results will be saved to: $outputFile" -ForegroundColor Yellow
    }
    'HTML' {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outputFile = Join-Path $ReportsPath "TestResults-$TestType-$timestamp.html"
        # Note: HTML output requires additional configuration
        Write-Host "HTML results will be saved to: $outputFile" -ForegroundColor Yellow
    }
    'Console' {
        $PesterConfig.Output.Verbosity = 'Detailed'
    }
}

# Set additional configuration
$PesterConfig.Output.CIFormat = 'Auto'
$PesterConfig.Run.PassThru = $PassThru

try {
    Write-Host "Starting test execution..." -ForegroundColor Cyan
    $StartTime = Get-Date

    # Run tests
    $TestResult = Invoke-Pester -Configuration $PesterConfig

    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime

    Write-Host ""
    Write-Host "=== Test Execution Complete ===" -ForegroundColor Cyan
    Write-Host "Duration: $($Duration.ToString('hh\:mm\:ss'))" -ForegroundColor Green
    Write-Host "Total Tests: $($TestResult.TotalCount)" -ForegroundColor White
    Write-Host "Passed: $($TestResult.PassedCount)" -ForegroundColor Green
    Write-Host "Failed: $($TestResult.FailedCount)" -ForegroundColor $(if ($TestResult.FailedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Skipped: $($TestResult.SkippedCount)" -ForegroundColor Yellow

    if ($TestResult.FailedCount -gt 0) {
        Write-Host ""
        Write-Host "Failed Tests:" -ForegroundColor Red
        foreach ($failedTest in $TestResult.Failed) {
            Write-Host "  - $($failedTest.Name)" -ForegroundColor Red
            if ($failedTest.ErrorRecord) {
                Write-Host "    Error: $($failedTest.ErrorRecord.Exception.Message)" -ForegroundColor DarkRed
            }
        }
    }

    # Generate summary report
    $summaryFile = Join-Path $ReportsPath "TestSummary-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $summary = @{
        TestType = $TestType
        OutputFormat = $OutputFormat
        StartTime = $StartTime
        EndTime = $EndTime
        Duration = $Duration.TotalSeconds
        TotalCount = $TestResult.TotalCount
        PassedCount = $TestResult.PassedCount
        FailedCount = $TestResult.FailedCount
        SkippedCount = $TestResult.SkippedCount
        SuccessRate = if ($TestResult.TotalCount -gt 0) {
            [math]::Round(($TestResult.PassedCount / $TestResult.TotalCount) * 100, 2)
        } else { 0 }
        FailedTests = $TestResult.Failed | ForEach-Object {
            @{
                Name = $_.Name
                Error = $_.ErrorRecord.Exception.Message
            }
        }
    }

    $summary | ConvertTo-Json -Depth 3 | Out-File -FilePath $summaryFile -Encoding UTF8
    Write-Host ""
    Write-Host "Summary saved to: $summaryFile" -ForegroundColor Cyan

    # Return test results if requested
    if ($PassThru) {
        return $TestResult
    }

    # Exit with appropriate code
    exit $TestResult.FailedCount

} catch {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    exit 1
}