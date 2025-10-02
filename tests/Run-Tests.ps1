#Requires -Version 7.4
#Requires -Modules Pester

<#
.SYNOPSIS
    Advanced test orchestration system for Azure PowerShell Toolkit
.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Professional test runner with comprehensive test coverage analysis, parallel execution,
    code coverage reporting, and multiple output format support.
.PARAMETER TestType
    Type of tests to run: All, Unit, Integration, Security, Performance, Quality
.PARAMETER TestPath
    Specific test file or directory to run
.PARAMETER OutputFormat
    Output format: Console, JUnit, NUnit, HTML, JSON, Markdown
.PARAMETER OutputPath
    Path for test result files
.PARAMETER CodeCoverageEnabled
    Enable code coverage analysis
.PARAMETER CodeCoverageThreshold
    Minimum acceptable code coverage percentage
.PARAMETER Parallel
    Run tests in parallel
.PARAMETER MaxParallelJobs
    Maximum number of parallel test jobs
.PARAMETER Tag
    Run only tests with specific tags
.PARAMETER ExcludeTag
    Exclude tests with specific tags
.PARAMETER PassThru
    Return test results object
.PARAMETER Detailed
    Show detailed test output
.PARAMETER FailFast
    Stop on first test failure
.EXAMPLE
    .\Run-Tests.ps1 -TestType Unit -CodeCoverageEnabled
.EXAMPLE
    .\Run-Tests.ps1 -TestType Integration -Parallel -OutputFormat HTML -OutputPath "./TestResults"
.NOTES
    Author: Wes Ellis
    Created: 2025-04-21
    Version: 3.0.0
    Requires: Pester 5.3+, PowerShell 7.0+

[CmdletBinding(DefaultParameterSetName = 'Standard')]
param(
    [parameter(ParameterSetName = 'Standard')]
    [ValidateSet('All', 'Unit', 'Integration', 'Security', 'Performance', 'Quality')]
    $TestType = 'All',

    [parameter(ParameterSetName = 'Specific')]
    [ValidateScript({ Test-Path $_ })]
$TestPath,

    [parameter()]
    [ValidateSet('Console', 'JUnit', 'NUnit', 'HTML', 'JSON', 'Markdown')]
    $OutputFormat = 'Console',

    [parameter()]
    [ValidateNotNullOrEmpty()]
    $OutputPath = './TestResults',

    [parameter()]
    [switch]$CodeCoverageEnabled,

    [parameter()]
    [ValidateRange(0, 100)]
    [int]$CodeCoverageThreshold = 70,

    [parameter()]
    [switch]$Parallel,

    [parameter()]
    [ValidateRange(1, 16)]
    [int]$MaxParallelJobs = 4,

    [parameter()]
    [string[]]$Tag,

    [parameter()]
    [string[]]$ExcludeTag,

    [parameter()]
    [switch]$PassThru,

    [parameter()]
    [switch]$Detailed,

    [parameter()]
    [switch]$FailFast
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'Continue'

    class TestOrchestrator {
$RootPath
$TestType
        [hashtable]$Configuration = @{}
        [System.Collections.ArrayList]$TestResults = @()
        [hashtable]$Coverage = @{}
        [System.Diagnostics.Stopwatch]$Timer

        TestOrchestrator([string]$RootPath) {
$this.RootPath = $RootPath
$this.Timer = [System.Diagnostics.Stopwatch]::new()
        }

        [void] Initialize() {
    $PesterModule = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge '5.3.0' } |
                Select-Object -First 1

            if (-not $PesterModule) {
                throw "Pester 5.3.0 or higher is required. Install with: Install-Module -Name Pester -MinimumVersion 5.3.0"
            }

            Import-Module Pester -Force

            if ($this.Configuration.OutputPath -and -not (Test-Path $this.Configuration.OutputPath)) {
                New-Item -Path $this.Configuration.OutputPath -ItemType Directory -Force | Out-Null
            }
        }

        [hashtable] BuildConfiguration() {
    $config = @{
                Run = @{
                    Path = $this.GetTestPaths()
                    Exit = $false
                    PassThru = $true
                    SkipRun = $false
                }
                Output = @{
                    Verbosity = if ($this.Configuration.Detailed) { 'Detailed' } else { 'Normal' }
                    StackTraceVerbosity = 'FirstLine'
                    CIFormat = 'Auto'
                }
                Should = @{
                    ErrorAction = if ($this.Configuration.FailFast) { 'Stop' } else { 'Continue' }
                }
                TestResult = @{
                    Enabled = $true
                    OutputPath = Join-Path $this.Configuration.OutputPath "TestResults.xml"
                    OutputFormat = 'NUnit3'
                }
            }

            if ($this.Configuration.CodeCoverageEnabled) {
$config.CodeCoverage = @{
                    Enabled = $true
                    Path = $this.GetCodePaths()
                    OutputPath = Join-Path $this.Configuration.OutputPath 'Coverage.xml'
                    OutputFormat = 'JaCoCo'
                    CoveragePercentTarget = $this.Configuration.CodeCoverageThreshold
                }
            }

            if ($this.Configuration.Tag) {
$config.Filter = @{
                    Tag = $this.Configuration.Tag
                }
            }

            if ($this.Configuration.ExcludeTag) {
                if (-not $config.ContainsKey('Filter')) {
$config.Filter = @{}
                }
$config.Filter.ExcludeTag = $this.Configuration.ExcludeTag
            }

            return $config
        }

        [string[]] GetTestPaths() {
            if ($this.Configuration.TestPath) {
                return @($this.Configuration.TestPath)
            }
    $paths = @()
    $TestRoot = Join-Path $this.RootPath 'tests'

            switch ($this.TestType) {
                'All' {
$paths += Get-ChildItem -Path $TestRoot -Filter '*.Tests.ps1' -Recurse
                }
                'Unit' {
$paths += Get-ChildItem -Path $TestRoot -Filter 'Unit*.Tests.ps1' -Recurse
$paths += Join-Path $TestRoot 'Unit'
                }
                'Integration' {
$paths += Get-ChildItem -Path $TestRoot -Filter 'Integration*.Tests.ps1' -Recurse
$paths += Join-Path $TestRoot 'Integration'
                }
                'Security' {
$paths += Get-ChildItem -Path $TestRoot -Filter 'Security*.Tests.ps1' -Recurse
$paths += Join-Path $TestRoot 'Security'
                }
                'Performance' {
$paths += Get-ChildItem -Path $TestRoot -Filter 'Performance*.Tests.ps1' -Recurse
$paths += Join-Path $TestRoot 'Performance'
                }
                'Quality' {
$paths += Get-ChildItem -Path $TestRoot -Filter 'Quality*.Tests.ps1' -Recurse
$paths += Join-Path $TestRoot 'Quality'
                }
            }

            return $paths | Where-Object { Test-Path $_ } | Select-Object -Unique
        }

        [string[]] GetCodePaths() {
    $paths = @()
    $ScriptsPath = Join-Path $this.RootPath 'scripts'
    $ToolsPath = Join-Path $this.RootPath 'tools'

            if (Test-Path $ScriptsPath) {
$paths += Get-ChildItem -Path $ScriptsPath -Filter '*.ps1' -Recurse | Where-Object { $_.Name -notlike '*.Tests.ps1' }
            }

            if (Test-Path $ToolsPath) {
$paths += Get-ChildItem -Path $ToolsPath -Filter '*.ps1' -Recurse | Where-Object { $_.Name -notlike '*.Tests.ps1' }
            }

            return $paths
        }

        [PSObject] RunTests() {
$this.Timer.Start()

            Write-Information "Test Execution Started" -InformationAction Continue
            Write-Information "Test Type: $($this.TestType)" -InformationAction Continue
            Write-Information "Parallel Execution: $(if ($this.Configuration.Parallel) { 'Enabled' } else { 'Disabled' })" -InformationAction Continue
    $PesterConfig = New-PesterConfiguration
    $ConfigHash = $this.BuildConfiguration()

            foreach ($section in $ConfigHash.Keys) {
                foreach ($setting in $ConfigHash[$section].Keys) {
$PesterConfig.$section.$setting = $ConfigHash[$section][$setting]
                }
            }

            if ($this.Configuration.Parallel -and $PesterConfig.Run.Path.Count -gt 1) {
    $results = $this.RunParallelTests($PesterConfig)
            }
            else {
    $results = Invoke-Pester -Configuration $PesterConfig
            }
$this.Timer.Stop()
$this.TestResults.Add($results)

            return $results
        }

        [PSObject] RunParallelTests([PSObject]$config) {
    $jobs = @()
    $paths = $config.Run.Path

            Write-Information "Running tests in parallel across $($paths.Count) paths" -InformationAction Continue
$paths | ForEach-Object {
    $job = Start-ThreadJob -ScriptBlock {
                    param($path, $config)

                    Import-Module Pester -Force
$config.Run.Path = @($path)
                    Invoke-Pester -Configuration $config
                } -ArgumentList $_, $config
$jobs += $job

                if ($jobs.Count -ge $this.Configuration.MaxParallelJobs) {
    $completed = Wait-Job -Job $jobs -Any
    $jobs = $jobs | Where-Object { $_.Id -ne $completed.Id }
                }
            }
    $results = $jobs | Wait-Job | Receive-Job
    $aggregated = [PSCustomObject]@{
                Tests = ($results.Tests | ForEach-Object { $_ })
                PassedCount = ($results.PassedCount | Measure-Object -Sum).Sum
                FailedCount = ($results.FailedCount | Measure-Object -Sum).Sum
                SkippedCount = ($results.SkippedCount | Measure-Object -Sum).Sum
                TotalCount = ($results.TotalCount | Measure-Object -Sum).Sum
                Duration = [TimeSpan]::FromMilliseconds(($results.Duration.TotalMilliseconds | Measure-Object -Sum).Sum)
                Result = if (($results.FailedCount | Measure-Object -Sum).Sum -eq 0) { 'Passed' } else { 'Failed' }
            }

            return $aggregated
        }

        [void] GenerateReports([PSObject]$results) {
            switch ($this.Configuration.OutputFormat) {
                'Console' {
                }
                'JUnit' {
$this.GenerateJUnitReport($results)
                }
                'NUnit' {
                }
                'HTML' {
$this.GenerateHtmlReport($results)
                }
                'JSON' {
$this.GenerateJsonReport($results)
                }
                'Markdown' {
$this.GenerateMarkdownReport($results)
                }
            }
        }

        [void] GenerateHtmlReport([PSObject]$results) {
    $ReportPath = Join-Path $this.Configuration.OutputPath "TestReport.html"
    $PassRate = if ($results.TotalCount -gt 0) {
                [Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2)
            } else { 0 }
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Results Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; }
        .container { max-width: 1200px; margin: auto; }
        .summary { display: grid; grid-template-columns: repeat(5, 1fr); gap: 20px; margin: 20px 0; }
        .metric { background:
        .metric-value { font-size: 2em; font-weight: bold; margin: 10px 0; }
        .passed { color:
        .failed { color:
        .skipped { color:
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { padding: 12px; border: 1px solid
        th { background:
    </style>
</head>
<body>
    <div class="container">
        <h1>Test Results Report</h1>
        <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p>Duration: $($results.Duration)</p>

        <div class="summary">
            <div class="metric">
                <div class="metric-value">$($results.TotalCount)</div>
                <div>Total Tests</div>
            </div>
            <div class="metric">
                <div class="metric-value passed">$($results.PassedCount)</div>
                <div>Passed</div>
            </div>
            <div class="metric">
                <div class="metric-value failed">$($results.FailedCount)</div>
                <div>Failed</div>
            </div>
            <div class="metric">
                <div class="metric-value skipped">$($results.SkippedCount)</div>
                <div>Skipped</div>
            </div>
            <div class="metric">
                <div class="metric-value">$PassRate%</div>
                <div>Pass Rate</div>
            </div>
        </div>

        <h2>Test Details</h2>
        <table>
            <thead>
                <tr>
                    <th>Test Name</th>
                    <th>Duration</th>
                    <th>Status</th>
                    <th>Error</th>
                </tr>
            </thead>
            <tbody>
"@

            foreach ($test in $results.Tests) {
    $status = if ($test.Passed) { 'Passed' }
                         elseif ($test.Skipped) { 'Skipped' }
                         else { 'Failed' }
    $ErrorText = if ($test.ErrorRecord) {
                    [System.Web.HttpUtility]::HtmlEncode($test.ErrorRecord.Exception.Message)
                } else { '-' }
$html += @"
                <tr>
                    <td>$([System.Web.HttpUtility]::HtmlEncode($test.Name))</td>
                    <td>$($test.Duration.TotalMilliseconds) ms</td>
                    <td>$status</td>
                    <td>$ErrorText</td>
                </tr>
"@
            }
$html += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@
$html | Out-File -FilePath $ReportPath -Encoding UTF8
            Write-Information "HTML report generated: $ReportPath" -InformationAction Continue
        }

        [void] GenerateJsonReport([PSObject]$results) {
    $ReportPath = Join-Path $this.Configuration.OutputPath 'TestReport.json'
    $report = @{
                Timestamp = Get-Date -Format 'o'
                Duration = $results.Duration.ToString()
                Summary = @{
                    Total = $results.TotalCount
                    Passed = $results.PassedCount
                    Failed = $results.FailedCount
                    Skipped = $results.SkippedCount
                    PassRate = if ($results.TotalCount -gt 0) {
                        [Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2)
                    } else { 0 }
                }
                Tests = $results.Tests | ForEach-Object {
                    @{
                        Name = $_.Name
                        Result = if ($_.Passed) { 'Passed' }
                                elseif ($_.Skipped) { 'Skipped' }
                                else { 'Failed' }
                        Duration = $_.Duration.TotalMilliseconds
                        Error = if ($_.ErrorRecord) { $_.ErrorRecord.Exception.Message } else { $null }
                    }
                }
            }
$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $ReportPath -Encoding UTF8
            Write-Information "JSON report generated: $ReportPath" -InformationAction Continue
        }

        [void] GenerateMarkdownReport([PSObject]$results) {
    $ReportPath = Join-Path $this.Configuration.OutputPath "TestReport.md"
    $PassRate = if ($results.TotalCount -gt 0) {
                [Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2)
            } else { 0 }
    $markdown = @"

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Duration:** $($results.Duration)
**Test Type:** $($this.TestType)


| Metric | Value |
|--------|-------|
| Total Tests | $($results.TotalCount) |
| Passed | $($results.PassedCount) |
| Failed | $($results.FailedCount) |
| Skipped | $($results.SkippedCount) |
| Pass Rate | $PassRate% |


| Test Name | Duration (ms) | Status | Error |
|-----------|---------------|--------|-------|
"@

            foreach ($test in $results.Tests) {
    $status = if ($test.Passed) { 'Passed' }
                         elseif ($test.Skipped) { 'Skipped' }
                         else { 'Failed' }
    $ErrorText = if ($test.ErrorRecord) {
$test.ErrorRecord.Exception.Message -replace '\|', '\|' -replace '\n', ' '
                } else { '-' }
$markdown += "| $($test.Name) | $($test.Duration.TotalMilliseconds) | $status | $ErrorText |`n"
            }
$markdown += @"


- PowerShell Version: $($PSVersionTable.PSVersion)
- Pester Version: $((Get-Module Pester).Version)
- Platform: $($PSVersionTable.Platform)
- OS: $($PSVersionTable.OS)

---
"@
$markdown | Out-File -FilePath $ReportPath -Encoding UTF8
            Write-Information "Markdown report generated: $ReportPath" -InformationAction Continue
        }

        [void] GenerateJUnitReport([PSObject]$results) {
    $ReportPath = Join-Path $this.Configuration.OutputPath "TestReport.xml"
    $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Azure PowerShell Toolkit Tests" tests="$($results.TotalCount)" failures="$($results.FailedCount)" skipped="$($results.SkippedCount)" time="$($results.Duration.TotalSeconds)">
    <testsuite name="$($this.TestType)" tests="$($results.TotalCount)" failures="$($results.FailedCount)" skipped="$($results.SkippedCount)" time="$($results.Duration.TotalSeconds)">
"@

            foreach ($test in $results.Tests) {
    $TestTime = $test.Duration.TotalSeconds
$xml += "        <testcase name=`"$([System.Security.SecurityElement]::Escape($test.Name))`" time=`"$TestTime`""

                if ($test.Passed) {
$xml += "/>`n"
                }
                elseif ($test.Skipped) {
$xml += ">`n            <skipped />`n        </testcase>`n"
                }
                else {
    $ErrorText = [System.Security.SecurityElement]::Escape($test.ErrorRecord.Exception.Message)
    $TraceText = [System.Security.SecurityElement]::Escape($test.ErrorRecord.ScriptStackTrace)
$xml += ">`n            <failure message=`"$ErrorText`">$TraceText</failure>`n        </testcase>`n"
                }
            }
$xml += @"
    </testsuite>
</testsuites>
"@
$xml | Out-File -FilePath $ReportPath -Encoding UTF8
            Write-Information "JUnit report generated: $ReportPath" -InformationAction Continue
        }
    }

    Write-Information "Azure PowerShell Toolkit Test Framework v3.0.0" -InformationAction Continue
    Write-Information "===============================================" -InformationAction Continue
}

process {
    try {
    $RootPath = Split-Path -Parent $PSScriptRoot
    $orchestrator = [TestOrchestrator]::new($RootPath)
$orchestrator.TestType = $TestType
$orchestrator.Configuration = @{
            OutputPath = $OutputPath
            OutputFormat = $OutputFormat
            CodeCoverageEnabled = $CodeCoverageEnabled
            CodeCoverageThreshold = $CodeCoverageThreshold
            Parallel = $Parallel
            MaxParallelJobs = $MaxParallelJobs
            Tag = $Tag
            ExcludeTag = $ExcludeTag
            Detailed = $Detailed
            FailFast = $FailFast
            TestPath = $TestPath
        }
$orchestrator.Initialize()
    $results = $orchestrator.RunTests()
$orchestrator.GenerateReports($results)

        Write-Information "`nTest Execution Summary" -InformationAction Continue
        Write-Information "======================" -InformationAction Continue
        Write-Information "Total Tests: $($results.TotalCount)" -InformationAction Continue
        Write-Information "Passed: $($results.PassedCount)" -InformationAction Continue
        Write-Information "Failed: $($results.FailedCount)" -InformationAction Continue
        Write-Information "Skipped: $($results.SkippedCount)" -InformationAction Continue
        Write-Information "Duration: $($results.Duration)" -InformationAction Continue
    $PassRate = if ($results.TotalCount -gt 0) {
            [Math]::Round(($results.PassedCount / $results.TotalCount) * 100, 2)
        } else { 0 }
        Write-Information "Pass Rate: $PassRate%" -InformationAction Continue

        if ($CodeCoverageEnabled -and $results.CodeCoverage) {
            Write-Information "`nCode Coverage Summary" -InformationAction Continue
            Write-Information "====================" -InformationAction Continue
            Write-Information "Coverage: $($results.CodeCoverage.CoveragePercent)%" -InformationAction Continue
            Write-Information "Covered: $($results.CodeCoverage.CommandsExecutedCount) commands" -InformationAction Continue
            Write-Information "Missed: $($results.CodeCoverage.CommandsMissedCount) commands" -InformationAction Continue
        }

        if ($results.FailedCount -gt 0) {
            Write-Warning "$($results.FailedCount) test(s) failed"
            if (-not $PassThru) {
                exit 1
            }
        }

        if ($CodeCoverageEnabled -and $results.CodeCoverage) {
            if ($results.CodeCoverage.CoveragePercent -lt $CodeCoverageThreshold) {
                Write-Warning "Code coverage ($($results.CodeCoverage.CoveragePercent)%) is below threshold ($CodeCoverageThreshold%)"
                if (-not $PassThru) {
                    exit 1
                }
            }
        }

        if ($PassThru) {
            return $results
        }
    }
    catch {
        Write-Error "Test execution failed: $_"
        throw
    }
}

end {
    Write-Information "`nTest execution completed" -InformationAction Continue
    Write-Information "Reports saved to: $OutputPath" -InformationAction Continue`n}
