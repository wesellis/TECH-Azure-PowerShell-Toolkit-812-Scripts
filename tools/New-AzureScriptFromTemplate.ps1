#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    $script = $script -replace '{DESCRIPTION}', $template
.DESCRIPTION
    $script = $script -replace '{SCRIPTNAME}', $ScriptName\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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

function Write-Log {
    [CmdletBinding()]
[string]$ScriptName)

    return @"

BeforeAll {
    `$script:ScriptPath = Join-Path `$PSScriptRoot "$ScriptName.ps1"

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

Write-Output "Azure Script Generator" # Color: $2
Write-Output "=====================" # Color: $2

$ScriptFileName = if ($ScriptName -match '\.ps1$') { $ScriptName } else { "$ScriptName.ps1" }
$ScriptPath = Join-Path $OutputPath $ScriptFileName

Write-Output "Generating script: $ScriptFileName" # Color: $2
Write-Output "Template: $Template" # Color: $2
Write-Output "Output path: $OutputPath" # Color: $2

$ScriptContent = Get-ScriptTemplate -TemplateType $Template
$ScriptContent | Out-File $ScriptPath -Encoding UTF8

Write-Output "Script created: $ScriptPath" # Color: $2

if ($IncludeTests) {
    $TestFileName = $ScriptFileName -replace '\.ps1$', '.Tests.ps1'
    $TestPath = Join-Path $OutputPath $TestFileName
    $TestContent = New-PesterTest -ScriptName ($ScriptName -replace '\.ps1$', '')
    $TestContent | Out-File $TestPath -Encoding UTF8
    Write-Output "Test file created: $TestPath" # Color: $2
}

if ($IncludeDocumentation) {
    $DocFileName = $ScriptFileName -replace '\.ps1$', '.md'
    $DocPath = Join-Path $OutputPath $DocFileName

    $DocContent = @"

This script implements $Template operations for Azure.

- PowerShell 7.0 or higher
- Azure PowerShell modules (Az)
- Azure subscription with appropriate permissions

- **ResourceGroupName**: The Azure Resource Group name
- **SubscriptionId**: Azure Subscription ID (optional)
- **Environment**: Target environment (Dev/Test/Staging/Production)
- **WhatIf**: Preview changes without applying them


``````powershell
.\$ScriptFileName -ResourceGroupName "myRG"

.\$ScriptFileName -ResourceGroupName "myRG" -SubscriptionId "12345-67890"

.\$ScriptFileName -ResourceGroupName "myRG" -WhatIf
``````

- **Name**: $Author
- **Email**: $Email
- **Date**: $(Get-Date -Format "yyyy-MM-dd")
"@

    $DocContent | Out-File $DocPath -Encoding UTF8
    Write-Output "Documentation created: $DocPath" # Color: $2
}

Write-Output "`nScript generation complete!" # Color: $2
Write-Output "Next steps:" # Color: $2
Write-Output "1. Review and customize the generated script" # Color: $2
Write-Output "2. Update the synopsis and description" # Color: $2
Write-Output "3. Add your specific logic" # Color: $2
if ($IncludeTests) {
    Write-Output "4. Run tests: Invoke-Pester $TestPath" # Color: $2
}\n



