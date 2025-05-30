<#
.SYNOPSIS
    Comprehensive test script to validate all Azure Cost Management Dashboard prerequisites and configuration.

.DESCRIPTION
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

.EXAMPLE
    .\Test-Prerequisites.ps1

.EXAMPLE
    .\Test-Prerequisites.ps1 -Detailed -ExportResults

.EXAMPLE
    .\Test-Prerequisites.ps1 -ConfigPath "config\prod-config.json" -TestData

.NOTES
    Author: Wesley Ellis
    Email: wes@wesellis.com
    Created: May 23, 2025
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "config\config.json",
    
    [Parameter(Mandatory = $false)]
    [switch]$TestData,
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportResults
)

# Initialize test results
$testResults = @{
    PowerShell = @{}
    Modules = @{}
    Azure = @{}
    Configuration = @{}
    Functionality = @{}
    Overall = @{}
}

$testStartTime = Get-Date

# Helper functions
function Write-TestResult {
    param(
        [string]$Test,
        [string]$Status,
        [string]$Message = "",
        [string]$Details = ""
    )
    
    $icon = switch ($Status) {
        "PASS" { "✅" }
        "FAIL" { "❌" }
        "WARN" { "⚠️" }
        "INFO" { "ℹ️" }
    }
    
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Cyan" }
    }
    
    Write-Host "$icon $Test" -ForegroundColor $color
    if ($Message) {
        Write-Host "   $Message" -ForegroundColor Gray
    }
    if ($Details -and $Detailed) {
        Write-Host "   Details: $Details" -ForegroundColor DarkGray
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
    Write-Host "`n🔍 Testing PowerShell Environment..." -ForegroundColor Cyan
    
    # PowerShell Version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        $testResults.PowerShell.Version = Write-TestResult "PowerShell Version" "PASS" "Version $($psVersion.Major).$($psVersion.Minor).$($psVersion.Build)"
    }
    else {
        $testResults.PowerShell.Version = Write-TestResult "PowerShell Version" "FAIL" "Version $($psVersion.Major).$($psVersion.Minor) (Requires 5.1+)"
    }
    
    # Execution Policy
    $execPolicy = Get-ExecutionPolicy
    if ($execPolicy -in @("RemoteSigned", "Unrestricted", "Bypass")) {
        $testResults.PowerShell.ExecutionPolicy = Write-TestResult "Execution Policy" "PASS" $execPolicy
    }
    else {
        $testResults.PowerShell.ExecutionPolicy = Write-TestResult "Execution Policy" "WARN" "$execPolicy (May prevent script execution)"
    }
    
    # Admin Rights
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($isAdmin) {
        $testResults.PowerShell.AdminRights = Write-TestResult "Administrator Rights" "PASS" "Running as Administrator"
    }
    else {
        $testResults.PowerShell.AdminRights = Write-TestResult "Administrator Rights" "INFO" "Not running as Administrator (OK for user-scope modules)"
    }
}

function Test-RequiredModules {
    Write-Host "`n📦 Testing Required Modules..." -ForegroundColor Cyan
    
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
                $testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "PASS" "Version $($installedModule.Version)"
            }
            else {
                $testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "WARN" "Version $($installedModule.Version) (Minimum: $($module.MinVersion))"
            }
        }
        else {
            $testResults.Modules[$module.Name] = Write-TestResult "$($module.Name) Module" "FAIL" "Not installed"
        }
    }
    
    # Optional modules
    $optionalModules = @("PSWriteHTML", "Pester", "PSScriptAnalyzer")
    foreach ($module in $optionalModules) {
        $installedModule = Get-Module -Name $module -ListAvailable
        if ($installedModule) {
            $testResults.Modules[$module] = Write-TestResult "$module Module (Optional)" "PASS" "Version $($installedModule[0].Version)"
        }
        else {
            $testResults.Modules[$module] = Write-TestResult "$module Module (Optional)" "INFO" "Not installed (Optional)"
        }
    }
}

function Test-AzureConnectivity {
    Write-Host "`n☁️ Testing Azure Connectivity..." -ForegroundColor Cyan
    
    try {
        # Test Azure connection
        $context = Get-AzContext -ErrorAction Stop
        if ($context) {
            $testResults.Azure.Connection = Write-TestResult "Azure Connection" "PASS" "Connected as $($context.Account.Id)"
            $testResults.Azure.Subscription = Write-TestResult "Subscription Access" "PASS" "$($context.Subscription.Name) ($($context.Subscription.Id))"
        }
        else {
            $testResults.Azure.Connection = Write-TestResult "Azure Connection" "FAIL" "Not connected to Azure"
            return
        }
        
        # Test Cost Management permissions
        try {
            $subscription = Get-AzSubscription -SubscriptionId $context.Subscription.Id -ErrorAction Stop
            $testResults.Azure.SubscriptionAccess = Write-TestResult "Subscription Permissions" "PASS" "Read access confirmed"
        }
        catch {
            $testResults.Azure.SubscriptionAccess = Write-TestResult "Subscription Permissions" "FAIL" "Cannot access subscription: $($_.Exception.Message)"
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
                $testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "PASS" "API access successful"
            }
            else {
                $testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "FAIL" "API returned status: $($costData.StatusCode)"
            }
        }
        catch {
            $testResults.Azure.CostManagementAPI = Write-TestResult "Cost Management API" "FAIL" "API access failed: $($_.Exception.Message)"
        }
        
        # Test Resource Graph access
        try {
            $query = "Resources | limit 1"
            $resourceData = Search-AzGraph -Query $query -ErrorAction Stop
            $testResults.Azure.ResourceGraph = Write-TestResult "Resource Graph API" "PASS" "Query successful"
        }
        catch {
            $testResults.Azure.ResourceGraph = Write-TestResult "Resource Graph API" "WARN" "Limited access: $($_.Exception.Message)"
        }
    }
    catch {
        $testResults.Azure.Connection = Write-TestResult "Azure Connection" "FAIL" "Connection test failed: $($_.Exception.Message)"
    }
}

function Test-Configuration {
    Write-Host "`n⚙️ Testing Configuration..." -ForegroundColor Cyan
    
    # Test configuration file existence
    $fullConfigPath = Join-Path $PWD $ConfigPath
    if (Test-Path $fullConfigPath) {
        $testResults.Configuration.File = Write-TestResult "Configuration File" "PASS" "Found at $ConfigPath"
        
        try {
            $config = Get-Content $fullConfigPath | ConvertFrom-Json
            $testResults.Configuration.Parse = Write-TestResult "Configuration Parsing" "PASS" "Valid JSON format"
            
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
                    $testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID Format" "PASS" "Valid GUID format"
                }
                else {
                    $testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID Format" "FAIL" "Invalid GUID format"
                }
            }
            else {
                $testResults.Configuration.SubscriptionId = Write-TestResult "Subscription ID" "WARN" "Not specified in configuration"
            }
        }
        catch {
            $testResults.Configuration.Parse = Write-TestResult "Configuration Parsing" "FAIL" "Invalid JSON: $($_.Exception.Message)"
        }
    }
    else {
        $testResults.Configuration.File = Write-TestResult "Configuration File" "WARN" "Not found at $ConfigPath (Using defaults)"
    }
    
    # Test authentication configuration
    $authPath = "config\auth.json"
    if (Test-Path $authPath) {
        $testResults.Configuration.Auth = Write-TestResult "Authentication Config" "PASS" "Authentication file found"
    }
    else {
        $testResults.Configuration.Auth = Write-TestResult "Authentication Config" "INFO" "No saved authentication (Will use interactive)"
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
    Write-Host "`n🧪 Testing Core Functionality..." -ForegroundColor Cyan
    
    if ($TestData) {
        # Test with sample data
        $sampleDataPath = "data\templates\sample-cost-data.csv"
        if (Test-Path $sampleDataPath) {
            try {
                $sampleData = Import-Csv $sampleDataPath
                $testResults.Functionality.DataImport = Write-TestResult "Sample Data Import" "PASS" "$($sampleData.Count) records loaded"
            }
            catch {
                $testResults.Functionality.DataImport = Write-TestResult "Sample Data Import" "FAIL" "Failed to load sample data"
            }
        }
        else {
            $testResults.Functionality.DataImport = Write-TestResult "Sample Data" "WARN" "Sample data file not found"
        }
    }
    else {
        # Test live data collection
        try {
            $scriptPath = "scripts\data-collection\Get-AzureCostData.ps1"
            if (Test-Path $scriptPath) {
                $testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "PASS" "Script file exists"
                
                # Test script execution (dry run)
                if ((Get-AzContext)) {
                    $testResults.Functionality.ScriptExecution = Write-TestResult "Script Execution Test" "INFO" "Skipped (Would require live data)"
                }
                else {
                    $testResults.Functionality.ScriptExecution = Write-TestResult "Script Execution Test" "SKIP" "No Azure connection"
                }
            }
            else {
                $testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "FAIL" "Script file missing"
            }
        }
        catch {
            $testResults.Functionality.CostScript = Write-TestResult "Cost Data Script" "FAIL" "Script test failed: $($_.Exception.Message)"
        }
    }
    
    # Test Excel export capability
    try {
        if (Get-Module -Name ImportExcel -ListAvailable) {
            $testPath = "test-export.xlsx"
            @{Test="Value"} | Export-Excel -Path $testPath -AutoSize
            if (Test-Path $testPath) {
                Remove-Item $testPath -Force
                $testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "PASS" "Export capability confirmed"
            }
        }
        else {
            $testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "FAIL" "ImportExcel module not available"
        }
    }
    catch {
        $testResults.Functionality.ExcelExport = Write-TestResult "Excel Export" "FAIL" "Export test failed: $($_.Exception.Message)"
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
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    $warnings = 0
    
    foreach ($category in $testResults.Keys) {
        if ($category -ne "Overall") {
            foreach ($test in $testResults[$category].Values) {
                $totalTests++
                switch ($test.Status) {
                    "PASS" { $passedTests++ }
                    "FAIL" { $failedTests++ }
                    "WARN" { $warnings++ }
                }
            }
        }
    }
    
    $testResults.Overall = @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        Warnings = $warnings
        PassRate = [math]::Round(($passedTests / $totalTests) * 100, 1)
        Status = if ($failedTests -eq 0) { "PASS" } elseif ($failedTests -le 2) { "WARN" } else { "FAIL" }
    }
}

function Show-Summary {
    $overall = $testResults.Overall
    
    Write-Host "`n" + "="*70 -ForegroundColor Cyan
    Write-Host "AZURE COST MANAGEMENT DASHBOARD - SYSTEM TEST RESULTS" -ForegroundColor Cyan
    Write-Host "="*70 -ForegroundColor Cyan
    
    Write-Host "`nOverall Status: " -NoNewline
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
    Write-Host "`nRecommendations:" -ForegroundColor Cyan
    
    if ($overall.FailedTests -gt 0) {
        Write-Host "❌ Critical Issues Found:" -ForegroundColor Red
        foreach ($category in $testResults.Keys) {
            if ($category -ne "Overall") {
                foreach ($test in $testResults[$category].Values) {
                    if ($test.Status -eq "FAIL") {
                        Write-Host "   • $($test.Test): $($test.Message)" -ForegroundColor Red
                    }
                }
            }
        }
        Write-Host "`n   Please resolve failed tests before proceeding." -ForegroundColor Red
    }
    
    if ($overall.Warnings -gt 0) {
        Write-Host "⚠️ Warnings to Consider:" -ForegroundColor Yellow
        foreach ($category in $testResults.Keys) {
            if ($category -ne "Overall") {
                foreach ($test in $testResults[$category].Values) {
                    if ($test.Status -eq "WARN") {
                        Write-Host "   • $($test.Test): $($test.Message)" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
    
    if ($overall.Status -eq "PASS") {
        Write-Host "✅ System Ready!" -ForegroundColor Green
        Write-Host "   Your Azure Cost Management Dashboard is properly configured." -ForegroundColor Green
        Write-Host "   Next steps:" -ForegroundColor White
        Write-Host "   • Generate your first cost report" -ForegroundColor White
        Write-Host "   • Configure automated reporting" -ForegroundColor White
        Write-Host "   • Customize dashboards for your needs" -ForegroundColor White
    }
    
    Write-Host "`nTest completed in $([math]::Round(((Get-Date) - $testStartTime).TotalSeconds, 1)) seconds" -ForegroundColor Gray
}

function Export-TestResults {
    if ($ExportResults) {
        $exportPath = "test-results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $testResults | ConvertTo-Json -Depth 5 | Out-File $exportPath
        Write-Host "`n📄 Test results exported to: $exportPath" -ForegroundColor Blue
    }
}

# Main execution
try {
    Write-Host "Azure Cost Management Dashboard - System Prerequisites Test" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "Test Started: $(Get-Date)" -ForegroundColor Gray
    
    if ($TestData) {
        Write-Host "Mode: Test Data (No live Azure data will be accessed)" -ForegroundColor Yellow
    }
    else {
        Write-Host "Mode: Live Testing (Will test Azure connectivity and permissions)" -ForegroundColor Yellow
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
    exit $(if ($testResults.Overall.Status -eq "FAIL") { 1 } else { 0 })
}
catch {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    exit 1
}
