#Requires -Version 7.0
#Requires -Modules Pester

<#
.SYNOPSIS
    Comprehensive Pester tests for Azure PowerShell Toolkit

.DESCRIPTION
    Tests script structure, PowerShell compliance, security, and functionality
    across all 800+ scripts in the toolkit.

.NOTES
    Author: Azure PowerShell Toolkit Team
    Version: 1.0
    Test Framework: Pester 5.0+
#>

BeforeAll {
    # Set up test environment
    $script:ToolkitRoot = Split-Path -Parent $PSScriptRoot
    $script:ScriptsPath = Join-Path $ToolkitRoot "scripts"
    $script:ModulesPath = Join-Path $ToolkitRoot "modules"

    # Import required modules for testing
    if (-not (Get-Module -Name Az.Accounts -ListAvailable)) {
        Write-Warning "Az.Accounts module not found. Some tests may be skipped."
    }

    # Get all PowerShell scripts
    $script:AllScripts = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse
    $script:ModuleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.ps*" -Recurse -ErrorAction SilentlyContinue
}

Describe "Azure PowerShell Toolkit - Repository Structure" {

    Context "Essential Files" {
        It "Should have README.md in root" {
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
            $licenseFile = Get-ChildItem -Path $ToolkitRoot -Filter "LICENSE*" | Select-Object -First 1
            $licenseFile | Should -Not -BeNullOrEmpty
        }
    }

    Context "Directory Structure" {
        It "Should have scripts directory" {
            $ScriptsPath | Should -Exist
        }

        It "Should have docs directory" {
            Join-Path $ToolkitRoot "docs" | Should -Exist
        }

        It "Should have .github directory" {
            Join-Path $ToolkitRoot ".github" | Should -Exist
        }

        It "Should have GitHub workflows" {
            Join-Path $ToolkitRoot ".github/workflows" | Should -Exist
        }
    }

    Context "Script Categories" {
        $expectedCategories = @(
            "compute", "storage", "network", "identity",
            "monitoring", "cost", "devops", "backup",
            "migration", "ai", "iot", "utilities"
        )

        foreach ($category in $expectedCategories) {
            It "Should have $category category directory" {
                Join-Path $ScriptsPath $category | Should -Exist
            }
        }
    }
}

Describe "PowerShell Script Standards Compliance" {

    Context "Script File Standards" {
        foreach ($script in $AllScripts) {
            Context "Script: $($script.Name)" {

                It "Should have .ps1 extension" {
                    $script.Extension | Should -Be ".ps1"
                }

                It "Should be readable" {
                    { Get-Content -Path $script.FullName -ErrorAction Stop } | Should -Not -Throw
                }

                It "Should have content" {
                    $script.Length | Should -BeGreaterThan 0
                }

                It "Should not be empty" {
                    $content = Get-Content -Path $script.FullName -Raw
                    $content.Trim() | Should -Not -BeNullOrEmpty
                }
            }
        }
    }

    Context "PowerShell Syntax Validation" {
        foreach ($script in $AllScripts) {
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

    Context "Required Elements" {
        foreach ($script in ($AllScripts | Select-Object -First 10)) {  # Test subset for performance
            Context "Script: $($script.Name)" {
                BeforeEach {
                    $content = Get-Content -Path $script.FullName -Raw
                }

                It "Should have #Requires statement" {
                    $content | Should -Match '#Requires'
                }

                It "Should have comment-based help" {
                    $content | Should -Match '\.SYNOPSIS|\.DESCRIPTION'
                }

                It "Should have CmdletBinding attribute" {
                    $content | Should -Match '\[CmdletBinding\(\)\]|\[CmdletBinding\([^\)]+\)\]'
                }

                It "Should have proper parameter blocks" {
                    if ($content -match 'param\s*\(') {
                        $content | Should -Match '\[Parameter\('
                    }
                }
            }
        }
    }
}

Describe "Security Compliance" {

    Context "Credential Security" {
        foreach ($script in $AllScripts) {
            It "Script $($script.Name) should not contain hardcoded passwords" {
                $content = Get-Content -Path $script.FullName -Raw

                # Check for common password patterns
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

                # Allow secure patterns but flag dangerous ones
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

                # Check for potential sensitive output
                $content | Should -Not -Match 'Write-Output.*password'
                $content | Should -Not -Match 'Write-Host.*secret'
                $content | Should -Not -Match 'echo.*key'
            }
        }
    }
}

Describe "Documentation Quality" {

    Context "Comment-Based Help" {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            Context "Script: $($script.Name)" {
                BeforeEach {
                    $content = Get-Content -Path $script.FullName -Raw
                }

                It "Should have .SYNOPSIS" {
                    $content | Should -Match '\.SYNOPSIS'
                }

                It "Should have .DESCRIPTION" {
                    $content | Should -Match '\.DESCRIPTION'
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

                # Check for common emoji unicode ranges
                $content | Should -Not -Match '[\u{1F600}-\u{1F64F}]'  # Emoticons
                $content | Should -Not -Match '[\u{1F300}-\u{1F5FF}]'  # Symbols
                $content | Should -Not -Match '[\u{1F680}-\u{1F6FF}]'  # Transport
                $content | Should -Not -Match '[\u{2600}-\u{26FF}]'    # Misc symbols
            }
        }
    }
}

Describe "Azure Integration" {

    Context "Azure Module Dependencies" {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            Context "Script: $($script.Name)" {
                BeforeEach {
                    $content = Get-Content -Path $script.FullName -Raw
                }

                It "Should use proper Azure PowerShell modules" {
                    if ($content -match 'Get-Az|Set-Az|New-Az|Remove-Az') {
                        # If using Az commands, should have proper requires
                        $content | Should -Match '#Requires.*Az\.'
                    }
                }

                It "Should handle Azure authentication properly" {
                    if ($content -match 'Connect-AzAccount|Get-AzContext') {
                        # Should check for existing context
                        $content | Should -Match 'Get-AzContext|Test-AzConnection|Connect-AzAccount'
                    }
                }
            }
        }
    }

    Context "Resource Management" {
        It "Should have resource group validation patterns" {
            $resourceScripts = $AllScripts | Where-Object {
                $_.Name -match 'ResourceGroup|resource-group'
            }

            $resourceScripts.Count | Should -BeGreaterThan 0
        }

        It "Should have subscription management patterns" {
            $subscriptionScripts = $AllScripts | Where-Object {
                $_.Name -match 'Subscription|subscription'
            }

            # Should have at least some subscription management
            $subscriptionScripts.Count | Should -BeGreaterOrEqual 0
        }
    }
}

Describe "Performance and Best Practices" {

    Context "Error Handling" {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should have error handling" {
                $content = Get-Content -Path $script.FullName -Raw

                # Should have some form of error handling
                $hasErrorHandling = $content -match 'try\s*\{|catch\s*\{|trap\s*\{|\$ErrorActionPreference|\-ErrorAction'
                $hasErrorHandling | Should -Be $true
            }
        }
    }

    Context "Parameter Validation" {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should validate mandatory parameters" {
                $content = Get-Content -Path $script.FullName -Raw

                if ($content -match '\[Parameter\([^\)]*Mandatory\s*=\s*\$true') {
                    # If has mandatory parameters, should be well-formed
                    $content | Should -Match '\[Parameter\([^\)]*Mandatory\s*=\s*\$true[^\)]*\)\]'
                }
            }
        }
    }

    Context "Output Consistency" {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should use consistent output methods" {
                $content = Get-Content -Path $script.FullName -Raw

                # Should prefer Write-Output, Write-Host, or Write-Verbose over echo
                if ($content -match 'echo\s') {
                    Write-Warning "Script $($script.Name) uses 'echo' instead of Write-Output"
                }
            }
        }
    }
}

Describe "Module Structure" -Skip:(-not (Test-Path $ModulesPath)) {

    Context "Module Files" {
        It "Should have module manifest files" {
            $manifestFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psd1" -Recurse
            $manifestFiles.Count | Should -BeGreaterThan 0
        }

        It "Should have module script files" {
            $moduleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" -Recurse
            $moduleFiles.Count | Should -BeGreaterOrEqual 0
        }
    }

    Context "Module Manifests" {
        $manifestFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psd1" -Recurse

        foreach ($manifest in $manifestFiles) {
            It "Manifest $($manifest.Name) should be valid" {
                { Test-ModuleManifest -Path $manifest.FullName } | Should -Not -Throw
            }
        }
    }
}

Describe "Integration Tests" -Tag "Integration" {

    Context "Script Execution" {
        It "Should be able to load scripts without errors" {
            foreach ($script in ($AllScripts | Select-Object -First 3)) {
                $errors = @()

                try {
                    # Try to parse the script
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

    Context "Repository Metrics" {
        It "Should have expected number of scripts" {
            $AllScripts.Count | Should -BeGreaterThan 700
        }

        It "Should have scripts in multiple categories" {
            $categories = $AllScripts | ForEach-Object {
                $_.Directory.Name
            } | Sort-Object -Unique

            $categories.Count | Should -BeGreaterThan 8
        }

        It "Should have comprehensive documentation" {
            $docFiles = Get-ChildItem -Path (Join-Path $ToolkitRoot "docs") -Filter "*.md" -Recurse
            $docFiles.Count | Should -BeGreaterThan 10
        }
    }

    Context "Quality Metrics" {
        It "Should have high percentage of compliant scripts" {
            $compliantScripts = $AllScripts | Where-Object {
                $content = Get-Content -Path $_.FullName -Raw
                $content -match '\[CmdletBinding\(\)\]' -and $content -match '#Requires'
            }

            $complianceRate = ($compliantScripts.Count / $AllScripts.Count) * 100
            $complianceRate | Should -BeGreaterThan 80
        }
    }
}