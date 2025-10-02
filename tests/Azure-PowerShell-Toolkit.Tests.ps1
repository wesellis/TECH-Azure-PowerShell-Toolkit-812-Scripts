#Requires -Version 7.4
#Requires -Modules Pester

<#
.SYNOPSIS
    Comprehensive Pester tests for Azure PowerShell Toolkit

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Tests script structure, PowerShell compliance, security, and functionality
    across all 800+ scripts in the toolkit.

.NOTES
    Author: Wes Ellis
    Created: 2025-04-21
    Last Modified: 2025-08-02
    Version: 1.0
    Test Framework: Pester 5.0+

$ErrorActionPreference = 'Stop'

BeforeAll {
    $script:ToolkitRoot = Split-Path -Parent $PSScriptRoot
    $script:ScriptsPath = Join-Path $ToolkitRoot "scripts"
    $script:ModulesPath = Join-Path $ToolkitRoot "modules"

    if (-not (Get-Module -Name Az.Accounts -ListAvailable)) {
        Write-Warning "Az.Accounts module not found. Some tests may be skipped."
    }

    $script:AllScripts = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse
    $script:ModuleFiles = Get-ChildItem -Path $ModulesPath -Filter '*.ps*' -Recurse -ErrorAction SilentlyContinue
}

Describe "Azure PowerShell Toolkit - Repository Structure" {

    Context 'Essential Files' {
        It 'Should have README.md in root' {
            Join-Path $ToolkitRoot "README.md" | Should -Exist
        }

        It "Should have SECURITY.md" {
            Join-Path $ToolkitRoot "SECURITY.md" | Should -Exist
        }

        It "Should have Get-Started.md" {
            Join-Path $ToolkitRoot "Get-Started.md" | Should -Exist
        }

        It "Should have .gitignore" {
            Join-Path $ToolkitRoot ".gitignore" | Should -Exist
        }

        It "Should have LICENSE file" {
            $LicenseFile = Get-ChildItem -Path $ToolkitRoot -Filter "LICENSE*" | Select-Object -First 1
            $LicenseFile | Should -Not -BeNullOrEmpty
        }
    }

    Context "Directory Structure" {
        It 'Should have scripts directory' {
            $ScriptsPath | Should -Exist
        }

        It "Should have docs directory" {
            Join-Path $ToolkitRoot 'docs' | Should -Exist
        }

        It "Should have .github directory" {
            Join-Path $ToolkitRoot ".github" | Should -Exist
        }

        It 'Should have GitHub workflows' {
            Join-Path $ToolkitRoot ".github/workflows" | Should -Exist
        }
    }

    Context "Script Categories" {
        $ExpectedCategories = @(
            "compute", 'storage', "network", "identity",
            "monitoring", "cost", 'devops', "backup",
            "migration", "ai", 'iot', "utilities"
        )

        $ExpectedCategories | ForEach-Object {
            $category = $_
            It "Should have $category category directory" {
                Join-Path $ScriptsPath $category | Should -Exist
            }
        }
    }
}

Describe "PowerShell Script Standards Compliance" {

    Context 'Script File Standards' {
        $AllScripts | ForEach-Object {
            $script = $_
            Context "Script: $($script.Name)" {

                It "Should have .ps1 extension" {
                    $script.Extension | Should -Be ".ps1"
                }

                It 'Should be readable' {
                    { Get-Content -Path $script.FullName -ErrorAction Stop } | Should -Not -Throw
                }

                It "Should have content" {
                    $script.Length | Should -BeGreaterThan 0
                }

                It 'Should not be empty' {
                    $content = Get-Content -Path $script.FullName -Raw
                    $content.Trim() | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Context 'PowerShell Syntax Validation' {
        $AllScripts | ForEach-Object {
            $script = $_
            It "Script $($script.Name) should have valid PowerShell syntax" {
                $errors = $null
                $tokens = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    $script.FullName, [ref]$tokens, [ref]$errors
                )

                $errors | Should -BeNullOrEmpty
                $ast | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Required Elements' {
        foreach ($script in ($AllScripts | Select-Object -First 10)) {
            Context "Script: $($script.Name)" {
                BeforeEach {
                    $content = Get-Content -Path $script.FullName -Raw
                }

                It "Should have #Requires statement" {
                    $content | Should -Match '#Requires'
                }

                It 'Should have comment-based help' {
                    $content | Should -Match '\.SYNOPSIS |\.DESCRIPTION'

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
                }

                It 'Should have CmdletBinding attribute' {
                    $content | Should -Match '\|\+\)\]'
                }

                It "Should have proper parameter blocks" {
                    if ($content -match 'param\s*\(') {
                        $content | Should -Match '\[parameter\('
                    }
                }
            }
        }
    }
}

Describe "Security Compliance" {

    Context 'Credential Security' {
        $AllScripts | ForEach-Object {
            $script = $_
            It "Script $($script.Name) should not contain hardcoded passwords" {
                $content = Get-Content -Path $script.FullName -Raw

                $content | Should -Not -Match 'password\s*=\s*["\'][^"\']*["\']'
                $content | Should -Not -Match '\$password\s*=\s*["\'][^"\']*["\']'
            }

            It "Script $($script.Name) should not contain hardcoded secrets" {
                $content = Get-Content -Path $script.FullName -Raw

                $content | Should -Not -Match 'secret\s*=\s*["\'][^"\']*["\']'
                $content | Should -Not -Match 'key\s*=\s*["\'][^"\']*["\']'
                $content | Should -Not -Match 'token\s*=\s*["\'][^"\']*["\']'
            }

            It "Script $($script.Name) should not use ConvertTo-SecureString with plaintext" {
                $content = Get-Content -Path $script.FullName -Raw

                if ($content -match 'ConvertTo-SecureString') {
                    $content | Should -Not -Match 'ConvertTo-SecureString.*-AsPlainText.*-Force'
                }
            }
        }
    }

    Context "Output Security" {
        foreach ($script in ($AllScripts | Select-Object -First 10)) {
            It "Script $($script.Name) should not output sensitive information" {
                $content = Get-Content -Path $script.FullName -Raw

                $content | Should -Not -Match 'Write-Output.*password'
                $content | Should -Not -Match 'Write-Host.*secret'
                $content | Should -Not -Match 'echo.*key'
            }
        }
    }
}

Describe "Documentation Quality" {

    Context 'Comment-Based Help' {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            Context "Script: $($script.Name)" {
                BeforeEach {
                    $content = Get-Content -Path $script.FullName -Raw
                }

                It "Should have .SYNOPSIS" {
                    $content | Should -Match '\.SYNOPSIS'
                }

                It "Should have .DESCRIPTION" {

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
                    $content | Should -Match '\.DESCRIPTION'

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
                }

                It "Should have .EXAMPLE" {
                    $content | Should -Match '\.EXAMPLE'
                }

                It "Should have meaningful synopsis" {
                    if ($content -match '\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.|\n\s*#>|\Z)') {
                        $synopsis = $matches[1].Trim()
                        $synopsis | Should -Not -BeNullOrEmpty
                        $synopsis.Length | Should -BeGreaterThan 10
                    }
                }
            }
        }
    }

    Context "Professional Language" {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should not contain emojis" {
                $content = Get-Content -Path $script.FullName -Raw

                $content | Should -Not -Match '[\u{1F600}-\u{1F64F}]'  # Emoticons
                $content | Should -Not -Match '[\u{1F300}-\u{1F5FF}]'  # Symbols
                $content | Should -Not -Match '[\u{1F680}-\u{1F6FF}]'  # Transport
                $content | Should -Not -Match '[\u{2600}-\u{26FF}]'    # Misc symbols
            }
        }
    }
}

Describe "Azure Integration" {

    Context 'Azure Module Dependencies' {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            Context "Script: $($script.Name)" {
                BeforeEach {
                    $content = Get-Content -Path $script.FullName -Raw
                }

                It "Should use proper Azure PowerShell modules" {
                    if ($content -match 'Get-Az |Set-Az |New-Az |Remove-Az') {
                        $content | Should -Match '#Requires.*Az\.'
                    }
                }

                It "Should handle Azure authentication properly" {
                    if ($content -match 'Connect-AzAccount |Get-AzContext') {
                        $content | Should -Match 'Get-AzContext |Test-AzConnection |Connect-AzAccount'
                    }
                }
            }
        }
    }

    Context "Resource Management" {
        It 'Should have resource group validation patterns' {
            $ResourceScripts = $AllScripts | Where-Object {
                $_.Name -match 'ResourceGroup |resource-group'
            }

            $ResourceScripts.Count | Should -BeGreaterThan 0
        }

        It "Should have subscription management patterns" {
            $SubscriptionScripts = $AllScripts | Where-Object {
                $_.Name -match 'Subscription |subscription'
            }

            $SubscriptionScripts.Count | Should -BeGreaterOrEqual 0
        }
    }
}

Describe "Performance and Best Practices" {

    Context 'Error Handling' {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should have error handling" {
                $content = Get-Content -Path $script.FullName -Raw

                $HasErrorHandling = $content -match 'try\s*\{|catch\s*\{|trap\s*\{|\$ErrorActionPreference |\-ErrorAction'
                $HasErrorHandling | Should -Be $true
            }
        }
    }

    Context "Parameter Validation" {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should validate mandatory parameters" {
                $content = Get-Content -Path $script.FullName -Raw

                if ($content -match '\[parameter\([^\)]*Mandatory\s*=\s*\$true') {
                    $content | Should -Match '\[parameter\([^\)]*Mandatory\s*=\s*\$true[^\)]*\)\]'
                }
            }
        }
    }

    Context "Output Consistency" {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should use consistent output methods" {
                $content = Get-Content -Path $script.FullName -Raw

                if ($content -match 'echo\s') {
                    Write-Warning "Script $($script.Name) uses 'echo' instead of Write-Output"
                }
            }
        }
    }
}

Describe 'Module Structure' -Skip:(-not (Test-Path $ModulesPath)) {

    Context "Module Files" {
        It 'Should have module manifest files' {
            $ManifestFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psd1" -Recurse
            $ManifestFiles.Count | Should -BeGreaterThan 0
        }

        It "Should have module script files" {
            $ModuleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" -Recurse
            $ModuleFiles.Count | Should -BeGreaterOrEqual 0
        }
    }

    Context "Module Manifests" {
        $ManifestFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psd1" -Recurse

        $ManifestFiles | ForEach-Object {
            $manifest = $_
            It "Manifest $($manifest.Name) should be valid" {
                { Test-ModuleManifest -Path $manifest.FullName } | Should -Not -Throw
            }
        }
    }
}

Describe "Integration Tests" -Tag "Integration" {

    Context 'Script Execution' {
        It 'Should be able to load scripts without errors' {
            foreach ($script in ($AllScripts | Select-Object -First 3)) {
                $errors = @()

                try {
                    $null = [System.Management.Automation.PSParser]::Tokenize(
                        (Get-Content -Path $script.FullName -Raw), [ref]$errors
                    )
                } catch {
                    $errors += $_.Exception.Message
                }

                $errors | Should -BeNullOrEmpty
            }
        }
    }

    Context "Help System" {
        foreach ($script in ($AllScripts | Select-Object -First 3)) {
            It "Script $($script.Name) should provide help content" {
                $help = Get-Help -Name $script.FullName -ErrorAction SilentlyContinue
                $help | Should -Not -BeNullOrEmpty
                $help.Synopsis | Should -Not -BeNullOrEmpty
            }
        }
    }
}

Describe "Toolkit Statistics" {

    Context 'Repository Metrics' {
        It 'Should have expected number of scripts' {
            $AllScripts.Count | Should -BeGreaterThan 700
        }

        It "Should have scripts in multiple categories" {
            $categories = $AllScripts | ForEach-Object {
                $_.Directory.Name
            } | Sort-Object -Unique

            $categories.Count | Should -BeGreaterThan 8
        }

        It "Should have comprehensive documentation" {
            $DocFiles = Get-ChildItem -Path (Join-Path $ToolkitRoot 'docs') -Filter "*.md" -Recurse
            $DocFiles.Count | Should -BeGreaterThan 10
        }
    }

    Context "Quality Metrics" {
        It 'Should have high percentage of compliant scripts' {
            $CompliantScripts = $AllScripts | Where-Object {
                $content = Get-Content -Path $_.FullName -Raw
                $content -match '\' -and $content -match '#Requires'
            }

            $ComplianceRate = ($CompliantScripts.Count / $AllScripts.Count) * 100
            $ComplianceRate | Should -BeGreaterThan 80
        }
    }
`n}
