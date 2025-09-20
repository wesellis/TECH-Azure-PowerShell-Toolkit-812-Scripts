<#
.SYNOPSIS
    $script = $script -replace '{DESCRIPTION}', $template
.DESCRIPTION
    $script = $script -replace '{SCRIPTNAME}', $ScriptName
#>
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

Write-Host "Script created: $scriptPath" -ForegroundColor Green

# Generate test file if requested
if ($IncludeTests) {
    $testFileName = $scriptFileName -replace '\.ps1$', '.Tests.ps1'
    $testPath = Join-Path $OutputPath $testFileName
    $testContent = New-PesterTest -ScriptName ($ScriptName -replace '\.ps1$', '')
    $testContent | Out-File $testPath -Encoding UTF8
    Write-Host "Test file created: $testPath" -ForegroundColor Green
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
    Write-Host "Documentation created: $docPath" -ForegroundColor Green
}

Write-Host "`nScript generation complete!" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review and customize the generated script" -ForegroundColor White
Write-Host "2. Update the synopsis and description" -ForegroundColor White
Write-Host "3. Add your specific logic" -ForegroundColor White
if ($IncludeTests) {
    Write-Host "4. Run tests: Invoke-Pester $testPath" -ForegroundColor White
}

