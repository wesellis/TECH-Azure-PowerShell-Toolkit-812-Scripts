# New-AzureScriptFromTemplate.ps1
# Generates new Azure PowerShell scripts from templates with best practices
# Author: Wesley Ellis | Enhanced by AI
# Version: 2.0

param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Resource", "Security", "Monitoring", "Automation", "Compliance", "Cost", "Custom")]
    [string]$Template,
    
    [string]$OutputPath = ".\",
    [string]$Author = "Your Name",
    [string]$Email = "your.email@domain.com",
    [switch]$IncludeTests,
    [switch]$IncludeDocumentation
)

function Get-ScriptTemplate {
    param([string]$TemplateType)
    
    $baseTemplate = @'
<#
.SYNOPSIS
    {SYNOPSIS}

.DESCRIPTION
    {DESCRIPTION}

.PARAMETER ResourceGroupName
    The name of the Azure Resource Group

.PARAMETER SubscriptionId
    The Azure Subscription ID (optional, uses current if not specified)

.EXAMPLE
    .\{SCRIPTNAME}.ps1 -ResourceGroupName "myRG"
    
    {EXAMPLE_DESCRIPTION}

.NOTES
    Author: {AUTHOR}
    Email: {EMAIL}
    Version: 1.0
    Date: {DATE}
    
.LINK
    https://github.com/your-repo/azure-toolkit
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Dev", "Test", "Staging", "Production")]
    [string]$Environment = "Dev",
    
    [switch]$WhatIf
)

#Requires -Modules Az.Accounts, Az.Resources
#Requires -Version 7.0

# Script configuration
$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { 'Continue' } else { 'SilentlyContinue' }

# Import required modules
try {
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module Az.Resources -ErrorAction Stop
    {ADDITIONAL_IMPORTS}
} catch {
    Write-Error "Failed to import required modules: $_"
    Write-Host "Please install Azure PowerShell modules: Install-Module -Name Az -AllowClobber -Force" -ForegroundColor Yellow
    exit 1
}

# Functions
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Info"    { Write-Host $logMessage -ForegroundColor Cyan }
        "Warning" { Write-Warning $logMessage }
        "Error"   { Write-Error $logMessage }
        "Success" { Write-Host $logMessage -ForegroundColor Green }
    }
}

function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Log "Not connected to Azure. Connecting..." -Level Warning
            Connect-AzAccount
        } else {
            Write-Log "Connected to Azure as: $($context.Account.Id)" -Level Info
        }
        
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
            Write-Log "Switched to subscription: $SubscriptionId" -Level Info
        }
        
        return $true
    } catch {
        Write-Log "Failed to connect to Azure: $_" -Level Error
        return $false
    }
}

{TEMPLATE_SPECIFIC_FUNCTIONS}

# Main execution
function Main {
    Write-Log "Starting {SCRIPTNAME}" -Level Info
    Write-Log "Environment: $Environment" -Level Info
    
    # Validate connection
    if (-not (Test-AzureConnection)) {
        Write-Log "Azure connection required" -Level Error
        return
    }
    
    try {
        # Validate parameters
        if ($ResourceGroupName) {
            $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $rg) {
                Write-Log "Resource Group not found: $ResourceGroupName" -Level Error
                return
            }
            Write-Log "Using Resource Group: $ResourceGroupName" -Level Info
        }
        
        {MAIN_LOGIC}
        
        Write-Log "Script completed successfully" -Level Success
        
    } catch {
        Write-Log "Script failed: $_" -Level Error
        Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error
        throw
    } finally {
        # Cleanup
        {CLEANUP_LOGIC}
    }
}

# Entry point
if ($WhatIf) {
    Write-Log "Running in WhatIf mode - no changes will be made" -Level Warning
}

Main
'@

    $templates = @{
        Resource = @{
            Synopsis = "Manages Azure resources"
            Description = "This script creates, updates, or manages Azure resources with best practices"
            AdditionalImports = "Import-Module Az.Network -ErrorAction Stop"
            TemplateFunctions = @'
function New-ResourceWithTags {
    param(
        [string]$Name,
        [string]$ResourceGroup,
        [hashtable]$Tags = @{}
    )
    
    $defaultTags = @{
        Environment = $Environment
        ManagedBy = "PowerShell"
        CreatedDate = (Get-Date -Format "yyyy-MM-dd")
        Owner = $env:USERNAME
    }
    
    $allTags = $defaultTags + $Tags
    
    # Resource creation logic here
    Write-Log "Creating resource: $Name with tags" -Level Info
}
'@
            MainLogic = @'
        # Example: Create or update resources
        if ($PSCmdlet.ShouldProcess("Azure Resources", "Create/Update")) {
            # Your resource management logic here
            Write-Log "Processing resources..." -Level Info
            
            # Example resource creation
            # New-ResourceWithTags -Name "myResource" -ResourceGroup $ResourceGroupName
        }
'@
        }
        
        Security = @{
            Synopsis = "Implements Azure security controls"
            Description = "This script configures and validates Azure security settings"
            AdditionalImports = "Import-Module Az.Security -ErrorAction Stop`nImport-Module Az.KeyVault -ErrorAction Stop"
            TemplateFunctions = @'
function Test-SecurityCompliance {
    param([string]$ResourceGroup)
    
    Write-Log "Checking security compliance for: $ResourceGroup" -Level Info
    
    $issues = @()
    
    # Check for encrypted storage
    $storageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroup
    foreach ($storage in $storageAccounts) {
        if (-not $storage.Encryption.Services.Blob.Enabled) {
            $issues += "Storage account $($storage.StorageAccountName) does not have encryption enabled"
        }
    }
    
    return $issues
}
'@
            MainLogic = @'
        # Security validation and remediation
        Write-Log "Running security assessment..." -Level Info
        
        $complianceIssues = Test-SecurityCompliance -ResourceGroup $ResourceGroupName
        
        if ($complianceIssues.Count -gt 0) {
            Write-Log "Security issues found:" -Level Warning
            $complianceIssues | ForEach-Object { Write-Log "  - $_" -Level Warning }
        } else {
            Write-Log "No security issues found" -Level Success
        }
'@
        }
        
        Monitoring = @{
            Synopsis = "Configures Azure monitoring and alerting"
            Description = "This script sets up monitoring, metrics, and alerts for Azure resources"
            AdditionalImports = "Import-Module Az.Monitor -ErrorAction Stop"
            TemplateFunctions = @'
function New-MetricAlert {
    param(
        [string]$AlertName,
        [string]$ResourceId,
        [string]$MetricName,
        [double]$Threshold
    )
    
    Write-Log "Creating metric alert: $AlertName" -Level Info
    
    # Alert creation logic
}
'@
            MainLogic = @'
        # Configure monitoring
        Write-Log "Configuring monitoring..." -Level Info
        
        # Example: Set up alerts
        # New-MetricAlert -AlertName "HighCPU" -ResourceId $resourceId -MetricName "CPU" -Threshold 80
'@
        }
        
        Automation = @{
            Synopsis = "Automates Azure operations"
            Description = "This script automates common Azure tasks and workflows"
            AdditionalImports = "Import-Module Az.Automation -ErrorAction Stop"
            TemplateFunctions = @'
function Start-AutomationWorkflow {
    param([string]$WorkflowName)
    
    Write-Log "Starting automation workflow: $WorkflowName" -Level Info
    
    # Workflow logic
}
'@
            MainLogic = @'
        # Automation logic
        Write-Log "Starting automation tasks..." -Level Info
        
        # Your automation logic here
'@
        }
        
        Compliance = @{
            Synopsis = "Validates Azure compliance requirements"
            Description = "This script checks and enforces compliance policies"
            AdditionalImports = "Import-Module Az.PolicyInsights -ErrorAction Stop"
            TemplateFunctions = @'
function Test-CompliancePolicy {
    param([string]$PolicyName)
    
    Write-Log "Testing compliance policy: $PolicyName" -Level Info
    
    # Policy validation logic
}
'@
            MainLogic = @'
        # Compliance validation
        Write-Log "Checking compliance..." -Level Info
        
        # Your compliance logic here
'@
        }
        
        Cost = @{
            Synopsis = "Analyzes and optimizes Azure costs"
            Description = "This script provides cost analysis and optimization recommendations"
            AdditionalImports = "Import-Module Az.Billing -ErrorAction Stop"
            TemplateFunctions = @'
function Get-CostAnalysis {
    param([string]$ResourceGroup)
    
    Write-Log "Analyzing costs for: $ResourceGroup" -Level Info
    
    # Cost analysis logic
}
'@
            MainLogic = @'
        # Cost analysis
        Write-Log "Analyzing costs..." -Level Info
        
        # Your cost optimization logic here
'@
        }
        
        Custom = @{
            Synopsis = "Custom Azure automation script"
            Description = "This script performs custom Azure operations"
            AdditionalImports = ""
            TemplateFunctions = "# Add your custom functions here"
            MainLogic = "        # Add your custom logic here`n        Write-Log \"Executing custom operations...\" -Level Info"
        }
    }
    
    $template = $templates[$TemplateType]
    
    $script = $baseTemplate
    $script = $script -replace '{SYNOPSIS}', $template.Synopsis
    $script = $script -replace '{DESCRIPTION}', $template.Description
    $script = $script -replace '{SCRIPTNAME}', $ScriptName
    $script = $script -replace '{AUTHOR}', $Author
    $script = $script -replace '{EMAIL}', $Email
    $script = $script -replace '{DATE}', (Get-Date -Format "yyyy-MM-dd")
    $script = $script -replace '{ADDITIONAL_IMPORTS}', $template.AdditionalImports
    $script = $script -replace '{TEMPLATE_SPECIFIC_FUNCTIONS}', $template.TemplateFunctions
    $script = $script -replace '{MAIN_LOGIC}', $template.MainLogic
    $script = $script -replace '{EXAMPLE_DESCRIPTION}', "Executes the $TemplateType operations"
    $script = $script -replace '{CLEANUP_LOGIC}', "# Add cleanup logic if needed"
    
    return $script
}

function New-PesterTest {
    param([string]$ScriptName)
    
    return @"
# $ScriptName.Tests.ps1
# Pester tests for $ScriptName

BeforeAll {
    `$script:ScriptPath = Join-Path `$PSScriptRoot "$ScriptName.ps1"
    
    # Mock Azure cmdlets
    Mock Connect-AzAccount { }
    Mock Get-AzContext { @{ Account = @{ Id = "test@example.com" } } }
    Mock Get-AzResourceGroup { @{ ResourceGroupName = "TestRG" } }
}

Describe "$ScriptName Tests" {
    Context "Parameter Validation" {
        It "Should accept valid parameters" {
            { & `$script:ScriptPath -ResourceGroupName "TestRG" -WhatIf } | Should -Not -Throw
        }
        
        It "Should validate environment parameter" {
            { & `$script:ScriptPath -Environment "Invalid" -WhatIf } | Should -Throw
        }
    }
    
    Context "Azure Connection" {
        It "Should verify Azure connection" {
            & `$script:ScriptPath -WhatIf
            Should -Invoke Get-AzContext -Times 1
        }
    }
    
    Context "Error Handling" {
        It "Should handle missing resource group" {
            Mock Get-AzResourceGroup { `$null }
            { & `$script:ScriptPath -ResourceGroupName "NonExistent" } | Should -Throw
        }
    }
}
"@
}

# Main execution
Write-Host "Azure Script Generator" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

$scriptFileName = if ($ScriptName -match '\.ps1$') { $ScriptName } else { "$ScriptName.ps1" }
$scriptPath = Join-Path $OutputPath $scriptFileName

Write-Host "Generating script: $scriptFileName" -ForegroundColor Yellow
Write-Host "Template: $Template" -ForegroundColor Yellow
Write-Host "Output path: $OutputPath" -ForegroundColor Yellow

# Generate script
$scriptContent = Get-ScriptTemplate -TemplateType $Template
$scriptContent | Out-File $scriptPath -Encoding UTF8

Write-Host "✅ Script created: $scriptPath" -ForegroundColor Green

# Generate test file if requested
if ($IncludeTests) {
    $testFileName = $scriptFileName -replace '\.ps1$', '.Tests.ps1'
    $testPath = Join-Path $OutputPath $testFileName
    $testContent = New-PesterTest -ScriptName ($ScriptName -replace '\.ps1$', '')
    $testContent | Out-File $testPath -Encoding UTF8
    Write-Host "✅ Test file created: $testPath" -ForegroundColor Green
}

# Generate documentation if requested
if ($IncludeDocumentation) {
    $docFileName = $scriptFileName -replace '\.ps1$', '.md'
    $docPath = Join-Path $OutputPath $docFileName
    
    $docContent = @"
# $ScriptName Documentation

## Overview
This script implements $Template operations for Azure.

## Requirements
- PowerShell 7.0 or higher
- Azure PowerShell modules (Az)
- Azure subscription with appropriate permissions

## Parameters
- **ResourceGroupName**: The Azure Resource Group name
- **SubscriptionId**: Azure Subscription ID (optional)
- **Environment**: Target environment (Dev/Test/Staging/Production)
- **WhatIf**: Preview changes without applying them

## Usage Examples

``````powershell
# Basic usage
.\$scriptFileName -ResourceGroupName "myRG"

# With specific subscription
.\$scriptFileName -ResourceGroupName "myRG" -SubscriptionId "12345-67890"

# Preview mode
.\$scriptFileName -ResourceGroupName "myRG" -WhatIf
``````

## Author
- **Name**: $Author
- **Email**: $Email
- **Date**: $(Get-Date -Format "yyyy-MM-dd")
"@
    
    $docContent | Out-File $docPath -Encoding UTF8
    Write-Host "✅ Documentation created: $docPath" -ForegroundColor Green
}

Write-Host "`nScript generation complete!" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review and customize the generated script" -ForegroundColor White
Write-Host "2. Update the synopsis and description" -ForegroundColor White
Write-Host "3. Add your specific logic" -ForegroundColor White
if ($IncludeTests) {
    Write-Host "4. Run tests: Invoke-Pester $testPath" -ForegroundColor White
}