#Requires -Version 5.1
#Requires -Module Az.Resources
<#
.SYNOPSIS
    Test Prerequisites
.DESCRIPTION
    Test Prerequisites operation
    Author: Wes Ellis (wes@wesellis.com)
#>

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

    Author: Wes Ellis (wes@wesellis.com)#>

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

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Set dynamic defaults
if (-not $ConfigPath) {
    $ConfigPath = "config\config.json"
}

#endregion

#region Functions

function Initialize-TestResults {
    [CmdletBinding()]
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Test,

        [Parameter(Mandatory)]
        [ValidateSet('PASS', 'FAIL', 'WARN', 'INFO', 'SKIP')]
        [string]$Status,

        [Parameter()]
        [string]$Message = "",

        [Parameter()]
        [string]$Details = ""
    )

    $icon = switch ($Status) {
        'PASS' { '[OK]' }
        'FAIL' { '[FAIL]' }
        'WARN' { '[WARN]' }
        'INFO' { '[INFO]' }
        'SKIP' { '[SKIP]' }
    }

    $color = switch ($Status) {
        'PASS' { 'Green' }
        'FAIL' { 'Red' }
        'WARN' { 'Yellow' }
        'INFO' { 'Cyan' }
        'SKIP' { 'Gray' }
    }

    Write-Host "$icon $Test" -ForegroundColor $color
    if ($Message) {
        Write-Host "   $Message" -ForegroundColor $color
    }
    if ($Details -and $script:Detailed) {
        Write-Host "   Details: $Details" -ForegroundColor Gray
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
    [CmdletBinding()]
    param()

    Write-Host "`nTesting PowerShell Environment..." -ForegroundColor Cyan
    
    # PowerShell Version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        $script:testResults.PowerShell.Version = Write-TestResult "PowerShell Version" "PASS" "Version $($psVersion.Major).$($psVersion.Minor).$($psVersion.Build)"
    }
    else {
        $script:testResults.PowerShell.Version: 1.0
    LastModified: 2025-09-19
    Requires 5.1+)"
    }
    
    # Execution Policy
    $execPolicy = Get-ExecutionPolicy -ErrorAction Stop
    if ($execPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")) {
        $script:testResults.PowerShell.ExecutionPolicy = Write-TestResult "Execution Policy" "PASS" $execPolicy
    }
    else {
        $script:testResults.PowerShell.ExecutionPolicy = Write-TestResult "Execution Policy" "WARN" "$execPolicy (May prevent script execution)"
    }
    
    # Admin Rights
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($isAdmin) {
        $script:testResults.PowerShell.AdminRights = Write-TestResult "Administrator Rights" "PASS" "Running as Administrator"
    }
    else {
        $script:testResults.PowerShell.AdminRights = Write-TestResult "Administrator Rights" "INFO" "Not running as Administrator (OK for user-scope modules)"
    }
}

function Test-RequiredModules {
    [CmdletBinding()]
    param()

    Write-Host "`nTesting Required Modules..." -ForegroundColor Cyan
    
    $requiredModules = @(
        @{ Name = "Az"; MinVersion = "9.0.0" },
        @{ Name = "Az.Accounts"; MinVersion = "2.0.0" },
        @{ Name = "Az.CostManagement"; MinVersion = "1.0.0" },
        @{ Name = "Az.Resources"; MinVersion = "5.0.0" },
        @{ Name = "ImportExcel"; MinVersion = "7.0.0" }
    )
    
    foreach ($module in $requiredModules) {
        $installedModule = Get-Module -Name $module.Name -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        
        if ($installedModule) {
            if ($installedModule.Version -ge [version]$module.MinVersion) {
                $script:testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "PASS" "Version $($installedModule.Version)"
            }
            else {
                $script:testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "WARN" "Version $($installedModule.Version) (Minimum: $($module.MinVersion))"
            }
        }
        else {
            $script:testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "FAIL" "Not installed"
        }
    }
    
    # Optional modules
    $optionalModules = @("PSWriteHTML", "Pester", "PSScriptAnalyzer")
    foreach ($module in $optionalModules) {
        $installedModule = Get-Module -Name $module -ListAvailable
        if ($installedModule) {
            $script:testResults.Modules[$module] = Write-TestResult "$module Module (Optional)" "PASS" "Version $($installedModule[0].Version)"
        }
        else {
            $script:testResults.Modules[$module] = Write-TestResult "$module Module (Optional)" "INFO" "Not installed (Optional)"
        }
    }
}

function Test-AzureConnectivity {
    [CmdletBinding()]
    param()

    Write-Host "`nTesting Azure Connectivity..." -ForegroundColor Cyan
    
    try {
        # Test Azure connection
        $context = Get-AzContext -ErrorAction Stop
        if ($context) {
            $script:testResults.Azure.Connection = Write-TestResult "Azure Connection" "PASS" "Connected as $($context.Account.Id)"
            $script:testResults.Azure.Subscription = Write-TestResult "Subscription Access" "PASS" "$($context.Subscription.Name) ($($context.Subscription.Id))"
        }
        else {
            $script:testResults.Azure.Connection = Write-TestResult "Azure Connection" "FAIL" "Not connected to Azure"
            return
        }
        
        # Test Cost Management permissions
        try {
            $subscription = Get-AzSubscription -SubscriptionId $context.Subscription.Id -ErrorAction Stop
            $script:testResults.Azure.SubscriptionAccess = Write-TestResult "Subscription Permissions" "PASS" "Read access confirmed"
        }
        catch {
            $script:testResults.Azure.SubscriptionAccess = Write-TestResult "Subscription Permissions" "FAIL" "Cannot access subscription: $($_.Exception.Message)"
        }
        
        # Test Cost Management API access
        try {
            $startDate = (Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
            $endDate = (Get-Date).ToString("yyyy-MM-dd")
            
            $costData = Invoke-AzRestMethod -Path "/subscriptions/$($context.Subscription.Id)/providers/Microsoft.CostManagement/query" -Method POST -Payload @{
                type = "ActualCost"
                timeframe = "Custom"
                timePeriod = @{
                    from = $startDate
                    to = $endDate
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
            
            if ($costData.StatusCode -eq 200) {
                $script:testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "PASS" "API access successful"
            }
            else {
                $script:testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "FAIL" "API returned status: $($costData.StatusCode)"
            
} catch {
            $script:testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "FAIL" "API access failed: $($_.Exception.Message)"
        }
        
        # Test Resource Graph access
        try {
            $query = "Resources | limit 1"
            $resourceData = Search-AzGraph -Query $query -ErrorAction Stop
            $script:testResults.Azure.ResourceGraph = Write-TestResult "Resource Graph API" "PASS" "Query successful"
        }
        catch {
            $script:testResults.Azure.ResourceGraph = Write-TestResult "Resource Graph API" "WARN" "Limited access: $($_.Exception.Message)"
        
} catch {
        $script:testResults.Azure.Connection = Write-TestResult "Azure Connection" "FAIL" "Connection test failed: $($_.Exception.Message)"
    }
}

function Test-Configuration {
    [CmdletBinding()]
    param()

    Write-Host "`nTesting Configuration..." -ForegroundColor Cyan
    
    # Test configuration file existence
    $fullConfigPath = Join-Path $PWD $ConfigPath
    if (Test-Path $fullConfigPath) {
        $script:testResults.Configuration.File = Write-TestResult "Configuration File" "PASS" "Found at $ConfigPath"
        
        try {
            $config = Get-Content -ErrorAction Stop $fullConfigPath | ConvertFrom-Json
            $script:testResults.Configuration.Parse = Write-TestResult "Configuration Parsing" "PASS" "Valid JSON format"
            
            # Validate required sections
            $requiredSections = @("azure", "dashboard", "notifications")
            foreach ($section in $requiredSections) {
                if ($config.$section) {
                    $testResults.Configuration[$section] = Write-TestResult "Config Section: $section" "PASS" "Section exists"
                }
                else {
                    $testResults.Configuration[$section] = Write-TestResult "Config Section: $section" "WARN" "Section missing"
                }
            }
            
            # Validate Azure configuration
            if ($config.azure.subscriptionId) {
                if ($config.azure.subscriptionId -match "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$") {
                    $script:testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID Format" "PASS" "Valid GUID format"
                }
                else {
                    $script:testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID Format" "FAIL" "Invalid GUID format"
                }
            }
            else {
                $script:testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID" "WARN" "Not specified in configuration"
            
} catch {
            $script:testResults.Configuration.Parse = Write-TestResult "Configuration Parsing" "FAIL" "Invalid JSON: $($_.Exception.Message)"
        }
    }
    else {
        $script:testResults.Configuration.File = Write-TestResult "Configuration File" "WARN" "Not found at $ConfigPath (Using defaults)"
    }
    
    # Test authentication configuration
    $authPath = "config\auth.json"
    if (Test-Path $authPath) {
        $script:testResults.Configuration.Auth = Write-TestResult "Authentication Config" "PASS" "Authentication file found"
    }
    else {
        $script:testResults.Configuration.Auth = Write-TestResult "Authentication Config" "INFO" "No saved authentication (Will use interactive)"
    }
    
    # Test directory structure
    $requiredDirs = @("scripts", "dashboards", "data", "docs")
    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            $testResults.Configuration["Dir_$dir"] = Write-TestResult "Directory: $dir" "PASS" "Exists"
        }
        else {
            $testResults.Configuration["Dir_$dir"] = Write-TestResult "Directory: $dir" "WARN" "Missing directory"
        }
    }
}

function Test-Functionality {
    [CmdletBinding()]
    param()

    Write-Host "`nTesting Core Functionality..." -ForegroundColor Cyan
    
    if ($TestData) {
        # Test with sample data
        $sampleDataPath = "data\templates\sample-cost-data.csv"
        if (Test-Path $sampleDataPath) {
            try {
                $sampleData = Import-Csv $sampleDataPath
                $script:testResults.Functionality.DataImport = Write-TestResult "Sample Data Import" "PASS" "$($sampleData.Count) records loaded"
            }
            catch {
                $script:testResults.Functionality.DataImport = Write-TestResult "Sample Data Import" "FAIL" "Failed to load sample data"
            }
        }
        else {
            $script:testResults.Functionality.DataImport = Write-TestResult "Sample Data" "WARN" "Sample data file not found"
        }
    }
    else {
        # Test live data collection
        try {
            $scriptPath = "scripts\data-collection\Get-AzureCostData.ps1"
            if (Test-Path $scriptPath) {
                $script:testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "PASS" "Script file exists"
                
                # Test script execution (dry run)
                if ((Get-AzContext)) {
                    $script:testResults.Functionality.ScriptExecution = Write-TestResult "Script Execution Test" "INFO" "Skipped (Would require live data)"
                }
                else {
                    $script:testResults.Functionality.ScriptExecution = Write-TestResult "Script Execution Test" "SKIP" "No Azure connection"
                }
            }
            else {
                $script:testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "FAIL" "Script file missing"
            
} catch {
            $script:testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "FAIL" "Script test failed: $($_.Exception.Message)"
        }
    }
    
    # Test Excel export capability
    try {
        if (Get-Module -Name ImportExcel -ListAvailable) {
            $testPath = "test-export.xlsx"
            @{Test="Value"} | Export-Excel -Path $testPath -AutoSize
            if (Test-Path $testPath) {
                Remove-Item -ErrorAction Stop $testPath -Force
                $script:testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "PASS" "Export capability confirmed"
            }
        }
        else {
            $script:testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "FAIL" "ImportExcel module not available"
        
} catch {
        $script:testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "FAIL" "Export test failed: $($_.Exception.Message)"
    }
    
    # Test dashboard files
    $dashboardFiles = @(
        "dashboards\Web\index.html",
        "dashboards\PowerBI\README.md",
        "dashboards\Excel\README.md"
    )
    
    foreach ($file in $dashboardFiles) {
        if (Test-Path $file) {
            $testResults.Functionality["Dashboard_$(Split-Path $file -Leaf)"] = Write-TestResult "Dashboard: $(Split-Path $file -Leaf)" "PASS" "File exists"
        }
        else {
            $testResults.Functionality["Dashboard_$(Split-Path $file -Leaf)"] = Write-TestResult "Dashboard: $(Split-Path $file -Leaf)" "WARN" "File missing"
        }
    }
}

function Get-OverallStatus {
    [CmdletBinding()]
    param()
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    $warnings = 0
    
    foreach ($category in $script:testResults.Keys) {
        if ($category -ne "Overall") {
            foreach ($test in $script:testResults[$category].Values) {
                $totalTests++
                switch ($test.Status) {
                    "PASS" { $passedTests++ }
                    "FAIL" { $failedTests++ }
                    "WARN" { $warnings++ }
                }
            }
        }
    }
    
    $script:testResults.Overall = @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        Warnings = $warnings
        PassRate = [math]::Round(($passedTests / $totalTests) * 100, 1)
        Status = if ($failedTests -eq 0) { "PASS" } elseif ($failedTests -le 2) { "WARN" } else { "FAIL" }
    }
}

function Show-Summary {
    [CmdletBinding()]
    param()
    $overall = $script:testResults.Overall
    
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "AZURE COST MANAGEMENT DASHBOARD - SYSTEM TEST RESULTS" -ForegroundColor White
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
    
    Write-Host "`nOverall Status: " -NoNewline -ForegroundColor White
    $statusColor = switch ($overall.Status) {
        "PASS" { "Green" }
        "WARN" { "Yellow" }
        "FAIL" { "Red" }
    }
    Write-Host $overall.Status -ForegroundColor $statusColor
    
    Write-Host "Tests Run: $($overall.TotalTests)" -ForegroundColor White
    Write-Host "Passed: $($overall.PassedTests)" -ForegroundColor Green
    Write-Host "Failed: $($overall.FailedTests)" -ForegroundColor Red
    Write-Host "Warnings: $($overall.Warnings)" -ForegroundColor Yellow
    Write-Host "Pass Rate: $($overall.PassRate)%" -ForegroundColor $(if ($overall.PassRate -ge 80) { "Green" } else { "Yellow" })
    
    # Recommendations based on results
    Write-Host "`nRecommendations:" -ForegroundColor White
    
    if ($overall.FailedTests -gt 0) {
        Write-Host "Critical Issues Found:" -ForegroundColor Red
        foreach ($category in $script:testResults.Keys) {
            if ($category -ne "Overall") {
                foreach ($test in $script:testResults[$category].Values) {
                    if ($test.Status -eq "FAIL") {
                        Write-Host "   - $($test.Test): $($test.Message)" -ForegroundColor Red
                    }
                }
            }
        }
        Write-Host "`n   Please resolve failed tests before proceeding." -ForegroundColor Red
    }
    
    if ($overall.Warnings -gt 0) {
        Write-Host "[WARN] Warnings to Consider:" -ForegroundColor Yellow
        foreach ($category in $script:testResults.Keys) {
            if ($category -ne "Overall") {
                foreach ($test in $script:testResults[$category].Values) {
                    if ($test.Status -eq "WARN") {
                        Write-Host "   - $($test.Test): $($test.Message)" -ForegroundColor Red
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
    
    Write-Host "`nTest completed in $([math]::Round(((Get-Date) - $script:testStartTime).TotalSeconds, 1)) seconds" -ForegroundColor Gray
}

function Export-TestResults {
    [CmdletBinding()]
    param()
    if ($ExportResults) {
        $exportPath = "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $script:testResults | ConvertTo-Json -Depth 5 | Out-File $exportPath
        Write-Host "`n[FILE] Test results exported to: $exportPath" -ForegroundColor Green
    }
}

#endregion

#region Main-Execution
try {
    # Initialize test results
    $script:testResults = Initialize-TestResults
    $script:testStartTime = Get-Date

    Write-Host "Azure Cost Management Dashboard - System Prerequisites Test" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor White
    Write-Host "Test Started: $(Get-Date)" -ForegroundColor Gray

    if ($TestData) {
        Write-Host "Mode: Test Data (No live Azure data will be accessed)" -ForegroundColor Yellow
    }
    else {
        Write-Host "Mode: Live Testing (Will test Azure connectivity and permissions)" -ForegroundColor Green
    }

    # Run all tests
    Test-PowerShellEnvironment
    Test-RequiredModules
    if (-not $TestData) {
        Test-AzureConnectivity
    }
    Test-Configuration
    Test-Functionality

    # Calculate overall results
    Get-OverallStatus

    # Show summary
    Show-Summary

    # Export results if requested
    Export-TestResults

    # Exit with appropriate code
    exit $(if ($script:testResults.Overall.Status -eq "FAIL") { 1 } else { 0 })
}
catch {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    throw
}
finally {
    # Cleanup if needed
    Write-Verbose "Test execution completed"
}

#endregion\n