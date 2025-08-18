#Requires -Version 7.0
#Requires -Modules Pester, Az.Accounts, Az.Resources

<#
.SYNOPSIS
    Comprehensive Azure Enterprise Toolkit Testing Framework
.DESCRIPTION
    Advanced testing framework for validating Azure infrastructure, security, compliance,
    and automation scripts across the enterprise toolkit.
.PARAMETER TestScope
    Scope of tests to run (All, Unit, Integration, Security, Performance, Compliance)
.PARAMETER ResourceGroupName
    Target resource group for integration tests
.PARAMETER Location
    Azure region for test resources
.PARAMETER TestEnvironment
    Test environment name (dev, test, staging)
.PARAMETER IncludeDestructive
    Include destructive tests (deletion, modification)
.PARAMETER OutputFormat
    Test output format (Console, JUnit, NUnitXml, AzureDevOps)
.PARAMETER OutputPath
    Path for test result output files
.PARAMETER Parallel
    Run tests in parallel for faster execution
.PARAMETER Tags
    Specific test tags to run
.EXAMPLE
    .\Azure-Toolkit-Test-Framework.ps1 -TestScope "All" -ResourceGroupName "test-rg" -Location "East US" -OutputFormat "JUnit"
.EXAMPLE
    .\Azure-Toolkit-Test-Framework.ps1 -TestScope "Security" -Tags @("RBAC", "Encryption") -OutputPath "C:\TestResults"
.NOTES
    Author: Wesley Ellis
    Version: 2.0
    Requires: PowerShell 7.0+, Pester 5.0+, Azure PowerShell modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Unit", "Integration", "Security", "Performance", "Compliance", "Infrastructure")]
    [string]$TestScope = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = "toolkit-test-rg-$(Get-Random -Maximum 9999)",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory = $false)]
    [string]$TestEnvironment = "test",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDestructive,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "JUnit", "NUnitXml", "AzureDevOps")]
    [string]$OutputFormat = "Console",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\TestResults",
    
    [Parameter(Mandatory = $false)]
    [switch]$Parallel,
    
    [Parameter(Mandatory = $false)]
    [string[]]$Tags = @()
)

# Initialize test environment
$ErrorActionPreference = "Stop"
$script:TestStartTime = Get-Date -ErrorAction Stop
$script:TestResults = @()

# Enhanced logging function
[CmdletBinding()]
function Write-TestLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success", "Test")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        Info = "White"
        Warning = "Yellow" 
        Error = "Red"
        Success = "Green"
        Test = "Cyan"
    }
    
    Write-Information "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

# Install and import required modules
[CmdletBinding()]
function Initialize-TestEnvironment {
    try {
        Write-TestLog "Initializing test environment..." "Info"
        
        # Check and install Pester
        $pesterModule = Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $pesterModule -or $pesterModule.Version -lt '5.0.0') {
            Write-TestLog "Installing/updating Pester module..." "Info"
            Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
        }
        
        Import-Module Pester -Force
        Import-Module Az.Accounts -Force
        Import-Module Az.Resources -Force
        
        # Create output directory
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        Write-TestLog "Test environment initialized successfully" "Success"
        
    } catch {
        Write-TestLog "Failed to initialize test environment: $($_.Exception.Message)" "Error"
        throw
    }
}

# Azure authentication and setup
[CmdletBinding()]
function Initialize-AzureTestEnvironment {
    try {
        Write-TestLog "Setting up Azure test environment..." "Info"
        
        # Ensure Azure connection
        $context = Get-AzContext -ErrorAction Stop
        if (-not $context) {
            Write-TestLog "Connecting to Azure..." "Info"
            Connect-AzAccount
        }
        
        # Create test resource group
        $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        if (-not $rg) {
            Write-TestLog "Creating test resource group: $ResourceGroupName" "Info"
            $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag @{
                Purpose = "AutomatedTesting"
                CreatedBy = "TestFramework"
                Environment = $TestEnvironment
                CreatedDate = (Get-Date).ToString("yyyy-MM-dd")
            }
        }
        
        $script:TestResourceGroup = $rg
        Write-TestLog "Azure test environment ready" "Success"
        
    } catch {
        Write-TestLog "Failed to setup Azure test environment: $($_.Exception.Message)" "Error"
        throw
    }
}

# Unit Tests for PowerShell Scripts
[CmdletBinding()]
function Invoke-UnitTests {
    Write-TestLog "Running unit tests..." "Test"
    
    $unitTestConfig = New-PesterConfiguration -ErrorAction Stop
    $unitTestConfig.Run.Container = New-PesterContainer -Path ".\tests\unit" -Data @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        TestEnvironment = $TestEnvironment
    }
    $unitTestConfig.Output.Verbosity = 'Detailed'
    $unitTestConfig.TestResult.Enabled = $true
    $unitTestConfig.TestResult.OutputPath = "$OutputPath\unit-test-results.xml"
    $unitTestConfig.TestResult.OutputFormat = $OutputFormat
    
    # Create sample unit tests if directory doesn't exist
    if (-not (Test-Path ".\tests\unit")) {
        New-Item -ItemType Directory -Path ".\tests\unit" -Force | Out-Null
        Create-SampleUnitTests
    }
    
    $results = Invoke-Pester -Configuration $unitTestConfig
    $script:TestResults += $results
    
    Write-TestLog "Unit tests completed: $($results.PassedCount) passed, $($results.FailedCount) failed" "Test"
}

# Integration Tests for Azure Resources
[CmdletBinding()]
function Invoke-IntegrationTests {
    Write-TestLog "Running integration tests..." "Test"
    
    $integrationTestConfig = New-PesterConfiguration -ErrorAction Stop
    $integrationTestConfig.Run.Container = New-PesterContainer -Path ".\tests\integration" -Data @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        TestEnvironment = $TestEnvironment
    }
    $integrationTestConfig.Output.Verbosity = 'Detailed'
    $integrationTestConfig.TestResult.Enabled = $true
    $integrationTestConfig.TestResult.OutputPath = "$OutputPath\integration-test-results.xml"
    $integrationTestConfig.TestResult.OutputFormat = $OutputFormat
    
    # Create sample integration tests
    if (-not (Test-Path ".\tests\integration")) {
        New-Item -ItemType Directory -Path ".\tests\integration" -Force | Out-Null
        Create-SampleIntegrationTests
    }
    
    $results = Invoke-Pester -Configuration $integrationTestConfig
    $script:TestResults += $results
    
    Write-TestLog "Integration tests completed: $($results.PassedCount) passed, $($results.FailedCount) failed" "Test"
}

# Security Tests for Azure Resources
[CmdletBinding()]
function Invoke-SecurityTests {
    Write-TestLog "Running security tests..." "Test"
    
    $securityTestConfig = New-PesterConfiguration -ErrorAction Stop
    $securityTestConfig.Run.Container = New-PesterContainer -Path ".\tests\security" -Data @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        TestEnvironment = $TestEnvironment
    }
    $securityTestConfig.Filter.Tag = "Security"
    $securityTestConfig.Output.Verbosity = 'Detailed'
    $securityTestConfig.TestResult.Enabled = $true
    $securityTestConfig.TestResult.OutputPath = "$OutputPath\security-test-results.xml"
    $securityTestConfig.TestResult.OutputFormat = $OutputFormat
    
    # Create security tests
    if (-not (Test-Path ".\tests\security")) {
        New-Item -ItemType Directory -Path ".\tests\security" -Force | Out-Null
        Create-SampleSecurityTests
    }
    
    $results = Invoke-Pester -Configuration $securityTestConfig
    $script:TestResults += $results
    
    Write-TestLog "Security tests completed: $($results.PassedCount) passed, $($results.FailedCount) failed" "Test"
}

# Performance Tests
[CmdletBinding()]
function Invoke-PerformanceTests {
    Write-TestLog "Running performance tests..." "Test"
    
    $performanceTestConfig = New-PesterConfiguration -ErrorAction Stop
    $performanceTestConfig.Run.Container = New-PesterContainer -Path ".\tests\performance" -Data @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        TestEnvironment = $TestEnvironment
    }
    $performanceTestConfig.Filter.Tag = "Performance"
    $performanceTestConfig.Output.Verbosity = 'Detailed'
    $performanceTestConfig.TestResult.Enabled = $true
    $performanceTestConfig.TestResult.OutputPath = "$OutputPath\performance-test-results.xml"
    $performanceTestConfig.TestResult.OutputFormat = $OutputFormat
    
    # Create performance tests
    if (-not (Test-Path ".\tests\performance")) {
        New-Item -ItemType Directory -Path ".\tests\performance" -Force | Out-Null
        Create-SamplePerformanceTests
    }
    
    $results = Invoke-Pester -Configuration $performanceTestConfig
    $script:TestResults += $results
    
    Write-TestLog "Performance tests completed: $($results.PassedCount) passed, $($results.FailedCount) failed" "Test"
}

# Compliance Tests
[CmdletBinding()]
function Invoke-ComplianceTests {
    Write-TestLog "Running compliance tests..." "Test"
    
    $complianceTestConfig = New-PesterConfiguration -ErrorAction Stop
    $complianceTestConfig.Run.Container = New-PesterContainer -Path ".\tests\compliance" -Data @{
        ResourceGroupName = $ResourceGroupName
        Location = $Location
        TestEnvironment = $TestEnvironment
    }
    $complianceTestConfig.Filter.Tag = "Compliance"
    $complianceTestConfig.Output.Verbosity = 'Detailed'
    $complianceTestConfig.TestResult.Enabled = $true
    $complianceTestConfig.TestResult.OutputPath = "$OutputPath\compliance-test-results.xml"
    $complianceTestConfig.TestResult.OutputFormat = $OutputFormat
    
    # Create compliance tests
    if (-not (Test-Path ".\tests\compliance")) {
        New-Item -ItemType Directory -Path ".\tests\compliance" -Force | Out-Null
        Create-SampleComplianceTests
    }
    
    $results = Invoke-Pester -Configuration $complianceTestConfig
    $script:TestResults += $results
    
    Write-TestLog "Compliance tests completed: $($results.PassedCount) passed, $($results.FailedCount) failed" "Test"
}

# Create sample unit tests
[CmdletBinding()]
function New-SampleUnitTests {
    $unitTestContent = @'
BeforeAll {
    # Import automation scripts for testing
    $script:AutomationScriptsPath = ".\automation-scripts"
}

Describe "PowerShell Script Validation" -Tag "Unit", "Validation" {
    BeforeAll {
        $scripts = Get-ChildItem -Path $script:AutomationScriptsPath -Filter "*.ps1" -Recurse
    }
    
    It "Should have valid PowerShell syntax for <Name>" -TestCases @(
        @{ Script = $scripts }
    ) -ForEach $scripts {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -ErrorAction Stop $Script.FullName -Raw), [ref]$errors)
        $errors.Count | Should -Be 0
    }
    
    It "Should have help documentation for <Name>" -TestCases @(
        @{ Script = $scripts }
    ) -ForEach $scripts {
        $content = Get-Content -ErrorAction Stop $Script.FullName -Raw
        $content | Should -Match "\.SYNOPSIS"
        $content | Should -Match "\.DESCRIPTION"
        $content | Should -Match "\.EXAMPLE"
    }
    
    It "Should have proper error handling for <Name>" -TestCases @(
        @{ Script = $scripts | Where-Object { $_.Name -notlike "*Test*" } }
    ) -ForEach ($scripts | Where-Object { $_.Name -notlike "*Test*" }) {
        $content = Get-Content -ErrorAction Stop $Script.FullName -Raw
        $content | Should -Match "try\s*\{"
        $content | Should -Match "catch\s*\{"
    }
}

Describe "Module Dependencies" -Tag "Unit", "Dependencies" {
    It "Should have required modules available" {
        $requiredModules = @("Az.Accounts", "Az.Resources", "Az.Storage")
        foreach ($module in $requiredModules) {
            Get-Module -ListAvailable -Name $module | Should -Not -BeNullOrEmpty
        }
    }
}
'@
    
    $unitTestContent | Out-File -FilePath ".\tests\unit\ScriptValidation.Tests.ps1" -Encoding UTF8
}

# Create sample integration tests
[CmdletBinding()]
function New-SampleIntegrationTests {
    $integrationTestContent = @'
BeforeAll {
    param($ResourceGroupName, $Location, $TestEnvironment)
    $script:ResourceGroupName = $ResourceGroupName
    $script:Location = $Location
    $script:TestEnvironment = $TestEnvironment
}

Describe "Azure Resource Creation" -Tag "Integration", "Azure" {
    It "Should create a storage account successfully" {
        $storageAccountName = "testst$(Get-Random -Maximum 99999)"
        $script = ".\automation-scripts\Data-Storage\Azure-StorageAccount-Provisioning-Tool.ps1"
        
        if (Test-Path $script) {
            { & $script -ResourceGroupName $script:ResourceGroupName -StorageAccountName $storageAccountName -Location $script:Location -SkuName "Standard_LRS" } | Should -Not -Throw
            
            # Verify resource exists
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $script:ResourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue
            $storageAccount | Should -Not -BeNullOrEmpty
            
            # Cleanup
            Remove-AzStorageAccount -ResourceGroupName $script:ResourceGroupName -Name $storageAccountName -Force
        }
    }
    
    It "Should create a virtual machine successfully" {
        $vmName = "test-vm-$(Get-Random -Maximum 999)"
        $script = ".\automation-scripts\Compute-Management\Azure-VM-Provisioning-Tool.ps1"
        
        if (Test-Path $script) {
            { & $script -ResourceGroupName $script:ResourceGroupName -VMName $vmName -Location $script:Location -Size "Standard_B1s" -AdminUsername "testadmin" -AdminPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) } | Should -Not -Throw
            
            # Verify resource exists
            $vm = Get-AzVM -ResourceGroupName $script:ResourceGroupName -Name $vmName -ErrorAction SilentlyContinue
            $vm | Should -Not -BeNullOrEmpty
            
            # Cleanup if destructive tests are enabled
            if ($script:IncludeDestructive) {
                Remove-AzVM -ResourceGroupName $script:ResourceGroupName -Name $vmName -Force
            }
        }
    }
}

Describe "Network Resources" -Tag "Integration", "Network" {
    It "Should create a virtual network successfully" {
        $vnetName = "test-vnet-$(Get-Random -Maximum 999)"
        $script = ".\automation-scripts\Network-Security\Azure-VNet-Provisioning-Tool.ps1"
        
        if (Test-Path $script) {
            { & $script -ResourceGroupName $script:ResourceGroupName -VNetName $vnetName -Location $script:Location -AddressPrefix "10.0.0.0/16" } | Should -Not -Throw
            
            # Verify resource exists
            $vnet = Get-AzVirtualNetwork -ResourceGroupName $script:ResourceGroupName -Name $vnetName -ErrorAction SilentlyContinue
            $vnet | Should -Not -BeNullOrEmpty
        }
    }
}
'@
    
    $integrationTestContent | Out-File -FilePath ".\tests\integration\AzureResources.Tests.ps1" -Encoding UTF8
}

# Create sample security tests
[CmdletBinding()]
function New-SampleSecurityTests {
    $securityTestContent = @'
BeforeAll {
    param($ResourceGroupName, $Location, $TestEnvironment)
    $script:ResourceGroupName = $ResourceGroupName
    $script:Location = $Location
}

Describe "Security Configuration Tests" -Tag "Security", "Compliance" {
    It "Should have encryption enabled for storage accounts" {
        $storageAccounts = Get-AzStorageAccount -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue
        
        foreach ($account in $storageAccounts) {
            $account.Encryption.Services.Blob.Enabled | Should -Be $true
            $account.EnableHttpsTrafficOnly | Should -Be $true
        }
    }
    
    It "Should have proper RBAC assignments" {
        $roleAssignments = Get-AzRoleAssignment -ResourceGroupName $script:ResourceGroupName
        $roleAssignments | Should -Not -BeNullOrEmpty
        
        # Check for overly permissive roles
        $dangerousRoles = $roleAssignments | Where-Object { $_.RoleDefinitionName -in @("Owner", "Contributor") -and $_.SignInName -like "*@*" }
        $dangerousRoles.Count | Should -BeLessOrEqual 2 # Allow limited number of admin accounts
    }
    
    It "Should have network security groups configured" {
        $nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue
        
        foreach ($nsg in $nsgs) {
            # Check for overly permissive rules
            $openRules = $nsg.SecurityRules | Where-Object { 
                $_.SourceAddressPrefix -eq "*" -and 
                $_.DestinationPortRange -contains "*" -and 
                $_.Access -eq "Allow" 
            }
            $openRules.Count | Should -Be 0
        }
    }
    
    It "Should have diagnostic settings enabled" {
        $resources = Get-AzResource -ResourceGroupName $script:ResourceGroupName
        
        foreach ($resource in $resources) {
            $diagnostics = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction SilentlyContinue
            if ($resource.ResourceType -in @("Microsoft.Storage/storageAccounts", "Microsoft.Compute/virtualMachines", "Microsoft.KeyVault/vaults")) {
                $diagnostics | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Key Vault Security" -Tag "Security", "KeyVault" {
    It "Should have proper access policies" {
        $keyVaults = Get-AzKeyVault -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue
        
        foreach ($vault in $keyVaults) {
            $vault.EnablePurgeProtection | Should -Be $true
            $vault.EnableSoftDelete | Should -Be $true
            $vault.EnableRbacAuthorization | Should -Be $true
        }
    }
}
'@
    
    $securityTestContent | Out-File -FilePath ".\tests\security\SecurityCompliance.Tests.ps1" -Encoding UTF8
}

# Create sample performance tests
[CmdletBinding()]
function New-SamplePerformanceTests {
    $performanceTestContent = @'
BeforeAll {
    param($ResourceGroupName, $Location, $TestEnvironment)
    $script:ResourceGroupName = $ResourceGroupName
    $script:Location = $Location
}

Describe "Performance Tests" -Tag "Performance" {
    It "Should create resources within acceptable time limits" {
        $startTime = Get-Date -ErrorAction Stop
        
        # Test storage account creation performance
        $storageAccountName = "perftest$(Get-Random -Maximum 99999)"
        $script = ".\automation-scripts\Data-Storage\Azure-StorageAccount-Provisioning-Tool.ps1"
        
        if (Test-Path $script) {
            & $script -ResourceGroupName $script:ResourceGroupName -StorageAccountName $storageAccountName -Location $script:Location -SkuName "Standard_LRS"
            
            $endTime = Get-Date -ErrorAction Stop
            $duration = ($endTime - $startTime).TotalSeconds
            
            # Storage account should be created within 2 minutes
            $duration | Should -BeLessOrEqual 120
            
            # Cleanup
            Remove-AzStorageAccount -ResourceGroupName $script:ResourceGroupName -Name $storageAccountName -Force
        }
    }
    
    It "Should handle bulk operations efficiently" {
        # Test bulk resource group creation
        $startTime = Get-Date -ErrorAction Stop
        
        $testResourceGroups = @()
        for ($i = 1; $i -le 5; $i++) {
            $rgName = "perf-test-rg-$i-$(Get-Random -Maximum 999)"
            $testResourceGroups += $rgName
            New-AzResourceGroup -Name $rgName -Location $script:Location -Force | Out-Null
        }
        
        $endTime = Get-Date -ErrorAction Stop
        $duration = ($endTime - $startTime).TotalSeconds
        
        # Should create 5 resource groups within 1 minute
        $duration | Should -BeLessOrEqual 60
        
        # Cleanup
        foreach ($rgName in $testResourceGroups) {
            Remove-AzResourceGroup -Name $rgName -Force -AsJob | Out-Null
        }
    }
}
'@
    
    $performanceTestContent | Out-File -FilePath ".\tests\performance\Performance.Tests.ps1" -Encoding UTF8
}

# Create sample compliance tests
[CmdletBinding()]
function New-SampleComplianceTests {
    $complianceTestContent = @'
BeforeAll {
    param($ResourceGroupName, $Location, $TestEnvironment)
    $script:ResourceGroupName = $ResourceGroupName
}

Describe "Compliance Tests" -Tag "Compliance", "Governance" {
    It "Should have required tags on all resources" {
        $resources = Get-AzResource -ResourceGroupName $script:ResourceGroupName
        $requiredTags = @("Environment", "Application", "Owner")
        
        foreach ($resource in $resources) {
            foreach ($tag in $requiredTags) {
                $resource.Tags.Keys | Should -Contain $tag
            }
        }
    }
    
    It "Should comply with naming conventions" {
        $resources = Get-AzResource -ResourceGroupName $script:ResourceGroupName
        
        foreach ($resource in $resources) {
            # Resource names should not contain spaces or special characters
            $resource.Name | Should -Match "^[a-zA-Z0-9\-_]+$"
            
            # Resource names should have appropriate prefixes based on type
            switch ($resource.ResourceType) {
                "Microsoft.Storage/storageAccounts" {
                    $resource.Name | Should -Match "^(st|storage)"
                }
                "Microsoft.Compute/virtualMachines" {
                    $resource.Name | Should -Match "^(vm|server)"
                }
                "Microsoft.KeyVault/vaults" {
                    $resource.Name | Should -Match "^(kv|vault)"
                }
            }
        }
    }
    
    It "Should have backup policies configured" {
        $vms = Get-AzVM -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue
        
        if ($vms) {
            # Check if Recovery Services Vault exists
            $recoveryVaults = Get-AzRecoveryServicesVault -ResourceGroupName $script:ResourceGroupName -ErrorAction SilentlyContinue
            $recoveryVaults | Should -Not -BeNullOrEmpty
        }
    }
    
    It "Should have monitoring enabled" {
        $resources = Get-AzResource -ResourceGroupName $script:ResourceGroupName
        $monitorableResources = $resources | Where-Object { 
            $_.ResourceType -in @(
                "Microsoft.Compute/virtualMachines",
                "Microsoft.Storage/storageAccounts",
                "Microsoft.Web/sites",
                "Microsoft.Sql/servers/databases"
            )
        }
        
        foreach ($resource in $monitorableResources) {
            $diagnostics = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction SilentlyContinue
            $diagnostics | Should -Not -BeNullOrEmpty
        }
    }
}
'@
    
    $complianceTestContent | Out-File -FilePath ".\tests\compliance\Governance.Tests.ps1" -Encoding UTF8
}

# Generate test report
[CmdletBinding()]
function New-TestReport -ErrorAction Stop {
    try {
        Write-TestLog "Generating test report..." "Info"
        
        $totalTests = ($script:TestResults | ForEach-Object { $_.TotalCount }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $passedTests = ($script:TestResults | ForEach-Object { $_.PassedCount }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $failedTests = ($script:TestResults | ForEach-Object { $_.FailedCount }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $skippedTests = ($script:TestResults | ForEach-Object { $_.SkippedCount }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        
        $testDuration = (Get-Date) - $script:TestStartTime
        
        $report = @{
            TestRun = @{
                StartTime = $script:TestStartTime
                EndTime = Get-Date -ErrorAction Stop
                Duration = $testDuration.ToString()
                Environment = $TestEnvironment
                Scope = $TestScope
            }
            Summary = @{
                TotalTests = $totalTests
                PassedTests = $passedTests
                FailedTests = $failedTests
                SkippedTests = $skippedTests
                SuccessRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }
            }
            Details = $script:TestResults
        }
        
        # Save report
        $reportPath = "$OutputPath\test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
        
        # Console summary
        Write-TestLog "Test Summary:" "Info"
        Write-TestLog "  Total Tests: $totalTests" "Info"
        Write-TestLog "  Passed: $passedTests" "Success"
        Write-TestLog "  Failed: $failedTests" $(if ($failedTests -gt 0) { "Error" } else { "Info" })
        Write-TestLog "  Skipped: $skippedTests" "Warning"
        Write-TestLog "  Success Rate: $($report.Summary.SuccessRate)%" $(if ($report.Summary.SuccessRate -ge 95) { "Success" } elseif ($report.Summary.SuccessRate -ge 80) { "Warning" } else { "Error" })
        Write-TestLog "  Duration: $($testDuration.ToString())" "Info"
        Write-TestLog "  Report saved to: $reportPath" "Info"
        
    } catch {
        Write-TestLog "Failed to generate test report: $($_.Exception.Message)" "Error"
    }
}

# Cleanup test resources
[CmdletBinding()]
function Remove-TestResources -ErrorAction Stop {
    if ($IncludeDestructive) {
        try {
            Write-TestLog "Cleaning up test resources..." "Info"
            
            # Remove test resource group
            if ($script:TestResourceGroup) {
                Remove-AzResourceGroup -Name $ResourceGroupName -Force -AsJob | Out-Null
                Write-TestLog "Test resource group cleanup initiated" "Success"
            }
            
        } catch {
            Write-TestLog "Failed to cleanup test resources: $($_.Exception.Message)" "Warning"
        }
    } else {
        Write-TestLog "Skipping resource cleanup (use -IncludeDestructive to enable)" "Info"
    }
}

# Main execution
try {
    Write-TestLog "Starting Azure Enterprise Toolkit Test Framework" "Info"
    Write-TestLog "Test Scope: $TestScope" "Info"
    Write-TestLog "Environment: $TestEnvironment" "Info"
    Write-TestLog "Output Format: $OutputFormat" "Info"
    
    # Initialize environment
    Initialize-TestEnvironment
    Initialize-AzureTestEnvironment
    
    # Run tests based on scope
    switch ($TestScope) {
        "All" {
            Invoke-UnitTests
            Invoke-IntegrationTests
            Invoke-SecurityTests
            Invoke-PerformanceTests
            Invoke-ComplianceTests
        }
        "Unit" { Invoke-UnitTests }
        "Integration" { Invoke-IntegrationTests }
        "Security" { Invoke-SecurityTests }
        "Performance" { Invoke-PerformanceTests }
        "Compliance" { Invoke-ComplianceTests }
    }
    
    # Generate report
    New-TestReport -ErrorAction Stop
    
    # Cleanup if requested
    Remove-TestResources -ErrorAction Stop
    
    Write-TestLog "Test framework execution completed" "Success"
    
    # Set exit code based on test results
    $totalFailed = ($script:TestResults | ForEach-Object { $_.FailedCount }) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    if ($totalFailed -gt 0) {
        Write-TestLog "Tests failed - exiting with error code" "Error"
        exit 1
    }
    
} catch {
    Write-TestLog "Test framework execution failed: $($_.Exception.Message)" "Error"
    exit 1
}
