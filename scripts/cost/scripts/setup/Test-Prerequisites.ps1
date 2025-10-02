#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Test Prerequisites
.DESCRIPTION
    Test Prerequisites operation


    Author: Wes Ellis (wes@wesellis.com)

    Validates all Azure Cost Management Dashboard prerequisites and configuration

    This script performs a complete validation of the Azure Cost Management Dashboard installation,
    including Azure connectivity, permissions, module dependencies, configuration files, and
    functionality testing. Provides detailed reporting and troubleshooting guidance.
.PARAMETER ConfigPath
    Path to the configuration file. Defaults to config\config.json.
.PARAMETER TestData
    Run tests with sample data instead of live Azure data.
.PARAMETER Detailed
    Show detailed test results for each component.
.PARAMETER ExportResults
    Export test results to a file.

    .\Test-Prerequisites.ps1

    Runs basic prerequisite validation tests

    .\Test-Prerequisites.ps1 -Detailed -ExportResults

    Runs detailed tests and exports results to a file

    .\Test-Prerequisites.ps1 -ConfigPath "config\prod-config.json" -TestData

    Tests with production config using sample data

    Author: Wes Ellis (wes@wesellis.com)

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigPath,

    [Parameter()]
    [switch]$TestData,

    [Parameter()]
    [switch]$Detailed,

    [Parameter()]
    [switch]$ExportResults
)
    [string]$ErrorActionPreference = 'Stop'
    [string]$ProgressPreference = 'SilentlyContinue'

if (-not $ConfigPath) {
    [string]$ConfigPath = "config\config.json"
}


function Write-Log {
    param()

    return @{
        PowerShell = @{}
        Modules = @{}
        Azure = @{}
        Configuration = @{}
        Functionality = @{}
        Overall = @{}
    }
}

function Write-TestResult {
    param(
        [Parameter(Mandatory)]
        [string]$Test,

        [Parameter(Mandatory)]
        [ValidateSet('PASS', 'FAIL', 'WARN', 'INFO', 'SKIP')]
        [string]$Status,

        [Parameter(ValueFromPipeline)]`n    [string]$Message = "",

        [Parameter(ValueFromPipeline)]`n    [string]$Details = ""
    )
    [string]$icon = switch ($Status) {
        'PASS' { '[OK]' }
        'FAIL' { '[FAIL]' }
        'WARN' { '[WARN]' }
        'INFO' { '[INFO]' }
        'SKIP' { '[SKIP]' }
    }
    [string]$color = switch ($Status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'WARN' { 'Yellow' }
        'INFO' { 'Cyan' }
        'SKIP' { 'Gray' }
    }

    Write-Output "$icon $Test" -ForegroundColor $color
    if ($Message) {
        Write-Output "   $Message" -ForegroundColor $color
    }
    if ($Details -and $script:Detailed) {
        Write-Host "   Details: $Details" -ForegroundColor Green
    }

    return @{
        Test = $Test
        Status = $Status
        Message = $Message
        Details = $Details
        Timestamp = Get-Date
    }
}

function Test-PowerShellEnvironment {
    param()

    Write-Host "`nTesting PowerShell Environment..." -ForegroundColor Green
    [string]$PsVersion = $PSVersionTable.PSVersion
    if ($PsVersion.Major -ge 5) {
    [string]$script:testResults.PowerShell.Version = Write-TestResult "PowerShell Version" "PASS" "Version $($PsVersion.Major).$($PsVersion.Minor).$($PsVersion.Build)"
    }
    else {
    [string]$script:testResults.PowerShell.Version: 1.0
    LastModified: 2025-09-19
    Requires 5.1+)"
    }
$ExecPolicy = Get-ExecutionPolicy -ErrorAction Stop
    if ($ExecPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")) {
    [string]$script:testResults.PowerShell.ExecutionPolicy = Write-TestResult "Execution Policy" "PASS" $ExecPolicy
    }
    else {
    [string]$script:testResults.PowerShell.ExecutionPolicy = Write-TestResult "Execution Policy" "WARN" "$ExecPolicy (May prevent script execution)"
    }
    [string]$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($IsAdmin) {
    [string]$script:testResults.PowerShell.AdminRights = Write-TestResult "Administrator Rights" "PASS" "Running as Administrator"
    }
    else {
    [string]$script:testResults.PowerShell.AdminRights = Write-TestResult "Administrator Rights" "INFO" "Not running as Administrator (OK for user-scope modules)"
    }
}

function Test-RequiredModules {
    param()

    Write-Host "`nTesting Required Modules..." -ForegroundColor Green
    [string]$RequiredModules = @(
        @{ Name = "Az"; MinVersion = "9.0.0" },
        @{ Name = "Az.Accounts"; MinVersion = "2.0.0" },
        @{ Name = "Az.CostManagement"; MinVersion = "1.0.0" },
        @{ Name = "Az.Resources"; MinVersion = "5.0.0" },
        @{ Name = "ImportExcel"; MinVersion = "7.0.0" }
    )

    foreach ($module in $RequiredModules) {
$InstalledModule = Get-Module -Name $module.Name -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

        if ($InstalledModule) {
            if ($InstalledModule.Version -ge [version]$module.MinVersion) {
    [string]$script:testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "PASS" "Version $($InstalledModule.Version)"
            }
            else {
    [string]$script:testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "WARN" "Version $($InstalledModule.Version) (Minimum: $($module.MinVersion))"
            }
        }
        else {
    [string]$script:testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "FAIL" "Not installed"
        }
    }
    [string]$OptionalModules = @("PSWriteHTML", "Pester", "PSScriptAnalyzer")
    foreach ($module in $OptionalModules) {
$InstalledModule = Get-Module -Name $module -ListAvailable
        if ($InstalledModule) {
    [string]$script:testResults.Modules[$module] = Write-TestResult "$module Module (Optional)" "PASS" "Version $($InstalledModule[0].Version)"
        }
        else {
    [string]$script:testResults.Modules[$module] = Write-TestResult "$module Module (Optional)" "INFO" "Not installed (Optional)"
        }
    }
}

function Test-AzureConnectivity {
    param()

    Write-Host "`nTesting Azure Connectivity..." -ForegroundColor Green

    try {
$context = Get-AzContext -ErrorAction Stop
        if ($context) {
    [string]$script:testResults.Azure.Connection = Write-TestResult "Azure Connection" "PASS" "Connected as $($context.Account.Id)"
    [string]$script:testResults.Azure.Subscription = Write-TestResult "Subscription Access" "PASS" "$($context.Subscription.Name) ($($context.Subscription.Id))"
        }
        else {
    [string]$script:testResults.Azure.Connection = Write-TestResult "Azure Connection" "FAIL" "Not connected to Azure"
            return
        }

        try {
$subscription = Get-AzSubscription -SubscriptionId $context.Subscription.Id -ErrorAction Stop
    [string]$script:testResults.Azure.SubscriptionAccess = Write-TestResult "Subscription Permissions" "PASS" "Read access confirmed"
        }
        catch {
    [string]$script:testResults.Azure.SubscriptionAccess = Write-TestResult "Subscription Permissions" "FAIL" "Cannot access subscription: $($_.Exception.Message)"
        }

        try {
    [string]$StartDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
    [string]$EndDate = (Get-Date).ToString("yyyy-MM-dd")
    [string]$CostData = Invoke-AzRestMethod -Path "/subscriptions/$($context.Subscription.Id)/providers/Microsoft.CostManagement/query" -Method POST -Payload @{
                type = "ActualCost"
                timeframe = "Custom"
                timePeriod = @{
                    from = $StartDate
                    to = $EndDate
                }
                dataset = @{
                    granularity = "Daily"
                    aggregation = @{
                        totalCost = @{
                            name = "PreTaxCost"
                            function = "Sum"
                        }
                    }
                }
            } -ErrorAction Stop

            if ($CostData.StatusCode -eq 200) {
    [string]$script:testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "PASS" "API access successful"
            }
            else {
    [string]$script:testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "FAIL" "API returned status: $($CostData.StatusCode)"

} catch {
    [string]$script:testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "FAIL" "API access failed: $($_.Exception.Message)"
        }

        try {
    [string]$query = "Resources | limit 1"
    [string]$ResourceData = Search-AzGraph -Query $query -ErrorAction Stop
    [string]$script:testResults.Azure.ResourceGraph = Write-TestResult "Resource Graph API" "PASS" "Query successful"
        }
        catch {
    [string]$script:testResults.Azure.ResourceGraph = Write-TestResult "Resource Graph API" "WARN" "Limited access: $($_.Exception.Message)"

} catch {
    [string]$script:testResults.Azure.Connection = Write-TestResult "Azure Connection" "FAIL" "Connection test failed: $($_.Exception.Message)"
    }
}

function Test-Configuration {
    param()

    Write-Host "`nTesting Configuration..." -ForegroundColor Green
    [string]$FullConfigPath = Join-Path $PWD $ConfigPath
    if (Test-Path $FullConfigPath) {
    [string]$script:testResults.Configuration.File = Write-TestResult "Configuration File" "PASS" "Found at $ConfigPath"

        try {
$config = Get-Content -ErrorAction Stop $FullConfigPath | ConvertFrom-Json
    [string]$script:testResults.Configuration.Parse = Write-TestResult "Configuration Parsing" "PASS" "Valid JSON format"
    [string]$RequiredSections = @("azure", "dashboard", "notifications")
            foreach ($section in $RequiredSections) {
                if ($config.$section) {
    [string]$TestResults.Configuration[$section] = Write-TestResult "Config Section: $section" "PASS" "Section exists"
                }
                else {
    [string]$TestResults.Configuration[$section] = Write-TestResult "Config Section: $section" "WARN" "Section missing"
                }
            }

            if ($config.azure.subscriptionId) {
                if ($config.azure.subscriptionId -match "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$") {
    [string]$script:testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID Format" "PASS" "Valid GUID format"
                }
                else {
    [string]$script:testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID Format" "FAIL" "Invalid GUID format"
                }
            }
            else {
    [string]$script:testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID" "WARN" "Not specified in configuration"

} catch {
    [string]$script:testResults.Configuration.Parse = Write-TestResult "Configuration Parsing" "FAIL" "Invalid JSON: $($_.Exception.Message)"
        }
    }
    else {
    [string]$script:testResults.Configuration.File = Write-TestResult "Configuration File" "WARN" "Not found at $ConfigPath (Using defaults)"
    }
    [string]$AuthPath = "config\auth.json"
    if (Test-Path $AuthPath) {
    [string]$script:testResults.Configuration.Auth = Write-TestResult "Authentication Config" "PASS" "Authentication file found"
    }
    else {
    [string]$script:testResults.Configuration.Auth = Write-TestResult "Authentication Config" "INFO" "No saved authentication (Will use interactive)"
    }
    [string]$RequiredDirs = @("scripts", "dashboards", "data", "docs")
    foreach ($dir in $RequiredDirs) {
        if (Test-Path $dir) {
    [string]$TestResults.Configuration["Dir_$dir"] = Write-TestResult "Directory: $dir" "PASS" "Exists"
        }
        else {
    [string]$TestResults.Configuration["Dir_$dir"] = Write-TestResult "Directory: $dir" "WARN" "Missing directory"
        }
    }
}

function Test-Functionality {
    param()

    Write-Host "`nTesting Core Functionality..." -ForegroundColor Green

    if ($TestData) {
    [string]$SampleDataPath = "data\templates\sample-cost-data.csv"
        if (Test-Path $SampleDataPath) {
            try {
    [string]$SampleData = Import-Csv $SampleDataPath
    [string]$script:testResults.Functionality.DataImport = Write-TestResult "Sample Data Import" "PASS" "$($SampleData.Count) records loaded"
            }
            catch {
    [string]$script:testResults.Functionality.DataImport = Write-TestResult "Sample Data Import" "FAIL" "Failed to load sample data"
            }
        }
        else {
    [string]$script:testResults.Functionality.DataImport = Write-TestResult "Sample Data" "WARN" "Sample data file not found"
        }
    }
    else {
        try {
    [string]$ScriptPath = "scripts\data-collection\Get-AzureCostData.ps1"
            if (Test-Path $ScriptPath) {
    [string]$script:testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "PASS" "Script file exists"

                if ((Get-AzContext)) {
    [string]$script:testResults.Functionality.ScriptExecution = Write-TestResult "Script Execution Test" "INFO" "Skipped (Would require live data)"
                }
                else {
    [string]$script:testResults.Functionality.ScriptExecution = Write-TestResult "Script Execution Test" "SKIP" "No Azure connection"
                }
            }
            else {
    [string]$script:testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "FAIL" "Script file missing"

} catch {
    [string]$script:testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "FAIL" "Script test failed: $($_.Exception.Message)"
        }
    }

    try {
        if (Get-Module -Name ImportExcel -ListAvailable) {
    [string]$TestPath = "test-export.xlsx"
            @{Test="Value"} | Export-Excel -Path $TestPath -AutoSize
            if (Test-Path $TestPath) {
                Remove-Item -ErrorAction Stop $TestPath -Force
    [string]$script:testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "PASS" "Export capability confirmed"
            }
        }
        else {
    [string]$script:testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "FAIL" "ImportExcel module not available"

} catch {
    [string]$script:testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "FAIL" "Export test failed: $($_.Exception.Message)"
    }
    [string]$DashboardFiles = @(
        "dashboards\Web\index.html",
        "dashboards\PowerBI\README.md",
        "dashboards\Excel\README.md"
    )

    foreach ($file in $DashboardFiles) {
        if (Test-Path $file) {
    [string]$TestResults.Functionality["Dashboard_$(Split-Path $file -Leaf)"] = Write-TestResult "Dashboard: $(Split-Path $file -Leaf)" "PASS" "File exists"
        }
        else {
    [string]$TestResults.Functionality["Dashboard_$(Split-Path $file -Leaf)"] = Write-TestResult "Dashboard: $(Split-Path $file -Leaf)" "WARN" "File missing"
        }
    }
}

function Get-OverallStatus {
    param()
    [string]$TotalTests = 0
    [string]$PassedTests = 0
    [string]$FailedTests = 0
    [string]$warnings = 0

    foreach ($category in $script:testResults.Keys) {
        if ($category -ne "Overall") {
            foreach ($test in $script:testResults[$category].Values) {
    [string]$TotalTests++
                switch ($test.Status) {
                    "PASS" { $PassedTests++ }
                    "FAIL" { $FailedTests++ }
                    "WARN" { $warnings++ }
                }
            }
        }
    }
    [string]$script:testResults.Overall = @{
        TotalTests = $TotalTests
        PassedTests = $PassedTests
        FailedTests = $FailedTests
        Warnings = $warnings
        PassRate = [math]::Round(($PassedTests / $TotalTests) * 100, 1)
        Status = if ($FailedTests -eq 0) { "PASS" } elseif ($FailedTests -le 2) { "WARN" } else { "FAIL" }
    }
}

function Show-Summary {
    param()
    [string]$overall = $script:testResults.Overall

    Write-Host "`n$('=' * 70)" -ForegroundColor Green
    Write-Host "AZURE COST MANAGEMENT DASHBOARD - SYSTEM TEST RESULTS" -ForegroundColor Green
    Write-Host "$('=' * 70)" -ForegroundColor Green

    Write-Output "`nOverall Status: " -NoNewline -ForegroundColor White
    [string]$StatusColor = switch ($overall.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
    }
    Write-Output $overall.Status -ForegroundColor $StatusColor

    Write-Host "Tests Run: $($overall.TotalTests)" -ForegroundColor Green
    Write-Host "Passed: $($overall.PassedTests)" -ForegroundColor Green
    Write-Host "Failed: $($overall.FailedTests)" -ForegroundColor Green
    Write-Host "Warnings: $($overall.Warnings)" -ForegroundColor Green
    Write-Output "Pass Rate: $($overall.PassRate)%" -ForegroundColor $(if ($overall.PassRate -ge 80) { "Green" } else { "Yellow" })

    Write-Host "`nRecommendations:" -ForegroundColor Green

    if ($overall.FailedTests -gt 0) {
        Write-Host "Critical Issues Found:" -ForegroundColor Green
        foreach ($category in $script:testResults.Keys) {
            if ($category -ne "Overall") {
                foreach ($test in $script:testResults[$category].Values) {
                    if ($test.Status -eq "FAIL") {
                        Write-Host "   - $($test.Test): $($test.Message)" -ForegroundColor Green
                    }
                }
            }
        }
        Write-Host "`n   Please resolve failed tests before proceeding." -ForegroundColor Green
    }

    if ($overall.Warnings -gt 0) {
        Write-Host "[WARN] Warnings to Consider:" -ForegroundColor Green
        foreach ($category in $script:testResults.Keys) {
            if ($category -ne "Overall") {
                foreach ($test in $script:testResults[$category].Values) {
                    if ($test.Status -eq "WARN") {
                        Write-Host "   - $($test.Test): $($test.Message)" -ForegroundColor Green
                    }
                }
            }
        }
    }

    if ($overall.Status -eq "PASS") {
        Write-Host "System Ready!" -ForegroundColor Green
        Write-Host "   Your Azure Cost Management Dashboard is properly configured." -ForegroundColor Green
        Write-Host "   Next steps:" -ForegroundColor Green
        Write-Host "   - Generate your first cost report" -ForegroundColor Green
        Write-Host "   - Configure automated reporting" -ForegroundColor Green
        Write-Host "   - Customize dashboards for your needs" -ForegroundColor Green
    }

    Write-Host "`nTest completed in $([math]::Round(((Get-Date) - $script:testStartTime).TotalSeconds, 1)) seconds" -ForegroundColor Green
}

function Export-TestResults {
    param()
    if ($ExportResults) {
    [string]$ExportPath = "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    [string]$script:testResults | ConvertTo-Json -Depth 5 | Out-File $ExportPath
        Write-Host "`n[FILE] Test results exported to: $ExportPath" -ForegroundColor Green
    }
}


try {
    [string]$script:testResults = Initialize-TestResults
    [string]$script:testStartTime = Get-Date

    Write-Host "Azure Cost Management Dashboard - System Prerequisites Test" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Test Started: $(Get-Date)" -ForegroundColor Green

    if ($TestData) {
        Write-Host "Mode: Test Data (No live Azure data will be accessed)" -ForegroundColor Green
    }
    else {
        Write-Host "Mode: Live Testing (Will test Azure connectivity and permissions)" -ForegroundColor Green
    }

    Test-PowerShellEnvironment
    Test-RequiredModules
    if (-not $TestData) {
        Test-AzureConnectivity
    }
    Test-Configuration
    Test-Functionality

    Get-OverallStatus

    Show-Summary

    Export-TestResults

    exit $(if ($script:testResults.Overall.Status -eq "FAIL") { 1 } else { 0 })
}
catch {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    throw
}
finally {
    Write-Verbose "Test execution completed"`n}
