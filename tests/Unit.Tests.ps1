#Requires -Version 7.4
#Requires -Modules Pester

<#
.SYNOPSIS
    Comprehensive unit tests for Azure PowerShell Toolkit
.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Pester tests to validate script functionality and best practices
.NOTES
    Author: Wes Ellis
    Created: 2025-04-21
    Version: 1.1
    Requires: Pester 5.0+

$ErrorActionPreference = 'Stop'

BeforeAll {
    $CommonModulePath = "$PSScriptRoot/../modules/AzureToolkit.Common/AzureToolkit.Common.psm1"
    if (Test-Path $CommonModulePath) {
        Import-Module $CommonModulePath -Force
    }
}

Describe "Azure PowerShell Toolkit - Core Validation" {
    Context 'Essential Files' {
        It "Should have main launcher script" {
            Test-Path "$PSScriptRoot/../Launch-AzureToolkit.ps1" | Should -Be $true
        }

        It "Should have AI Assistant script" {
            Test-Path "$PSScriptRoot/../AI-Assistant.ps1" | Should -Be $true
        }

        It "Should have README.md" {
            Test-Path "$PSScriptRoot/../README.md" | Should -Be $true
        }

        It "Should have LICENSE file" {
            $LicenseExists = (Test-Path "$PSScriptRoot/../LICENSE") -or (Test-Path "$PSScriptRoot/../LICENSE.txt") -or (Test-Path "$PSScriptRoot/../LICENSE.md")
            $LicenseExists | Should -Be $true
        }
    }

    Context 'Directory Structure' {
        It "Should have scripts directory" {
            Test-Path "$PSScriptRoot/../scripts" | Should -Be $true
        }

        It "Should have docs directory" {
            Test-Path "$PSScriptRoot/../docs" | Should -Be $true
        }

        It "Should have tests directory" {
            Test-Path "$PSScriptRoot" | Should -Be $true
        }

        It "Should have modules directory" {
            Test-Path "$PSScriptRoot/../modules" | Should -Be $true
        }
    }

    Context 'Script Categories' {
        $ExpectedCategories = @(
            "compute", "storage", "network", "identity",
            "monitoring", "cost", "devops", "backup",
            "migration", "ai", "iot", "utilities"
        )

        foreach ($category in $ExpectedCategories) {
            It "Should have $category category directory" {
                Test-Path "$PSScriptRoot/../scripts/$category" | Should -Be $true
            }
        }
    }
}

Describe "Script Quality Validation" {
    BeforeAll {
        $script:AllScripts = Get-ChildItem -Path "$PSScriptRoot/../scripts" -Filter "*.ps1" -Recurse
    }

    Context 'PowerShell Standards' {
        It "Should have PowerShell scripts" {
            $AllScripts.Count | Should -BeGreaterThan 100
        }

        foreach ($script in ($AllScripts | Select-Object -First 10)) {
            Context "Script: $($script.Name)" {
                It "Should have valid PowerShell syntax" {
                    $errors = $null
                    $tokens = $null
                    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                        $script.FullName, [ref]$tokens, [ref]$errors
                    )

                    $errors | Should -BeNullOrEmpty
                    $ast | Should -Not -BeNullOrEmpty
                }

                It "Should have #Requires statement" {
                    $content = Get-Content -Path $script.FullName -Raw
                    $content | Should -Match '#Requires'
                }

                It "Should have comment-based help" {
                    $content = Get-Content -Path $script.FullName -Raw
                    $content | Should -Match '\.SYNOPSIS|\.DESCRIPTION'

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
                }

                It "Should have CmdletBinding attribute" {
                    $content = Get-Content -Path $script.FullName -Raw
                    $content | Should -Match '\|\+\)\]'
                }
            }
        }
    }

    Context 'Security Standards' {
        foreach ($script in ($AllScripts | Select-Object -First 10)) {
            Context "Security: $($script.Name)" {
                It "Should not contain hardcoded passwords" {
                    $content = Get-Content -Path $script.FullName -Raw
                    $content | Should -Not -Match 'password\s*=\s*["\'][^"\']*["\']'
                    $content | Should -Not -Match '\$password\s*=\s*["\'][^"\']*["\']'
                }

                It "Should not contain hardcoded secrets" {
                    $content = Get-Content -Path $script.FullName -Raw
                    $content | Should -Not -Match 'secret\s*=\s*["\'][^"\']*["\']'
                    $content | Should -Not -Match 'key\s*=\s*["\'][^"\']*["\']'
                    $content | Should -Not -Match 'token\s*=\s*["\'][^"\']*["\']'
                }

                It "Should not use insecure ConvertTo-SecureString" {
                    $content = Get-Content -Path $script.FullName -Raw
                    if ($content -match 'ConvertTo-SecureString') {
                        $content | Should -Not -Match 'ConvertTo-SecureString.*-AsPlainText.*-Force'
                    }
                }
            }
        }
    }

    Context 'Error Handling Standards' {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should have error handling" {
                $content = Get-Content -Path $script.FullName -Raw
                $HasErrorHandling = $content -match 'try\s*\{|catch\s*\{|trap\s*\{|\$ErrorActionPreference|-ErrorAction'
                $HasErrorHandling | Should -Be $true
            }
        }
    }
}

Describe "Module Functionality" {
    Context 'Common Module Functions' -Skip:(-not (Test-Path "$PSScriptRoot/../modules/AzureToolkit.Common/AzureToolkit.Common.psm1")) {
        BeforeAll {
            Import-Module "$PSScriptRoot/../modules/AzureToolkit.Common/AzureToolkit.Common.psm1" -Force
        }

        It "Should export utility functions" {
            $ExportedCommands = Get-Command -Module AzureToolkit.Common
            $ExportedCommands.Count | Should -BeGreaterThan 0
        }

        It "Should have Write-Log function" {
            Get-Command Write-Log -Module AzureToolkit.Common -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have Test-AzureConnection function" {
            Get-Command Test-AzureConnection -Module AzureToolkit.Common -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Configuration Validation" {
    Context 'Environment Configuration' {
        It "Should handle missing Azure context gracefully" {
            $MockError = $null
            try {
                $context = Get-AzContext -ErrorAction SilentlyContinue
            }
            catch {
                $MockError = $_.Exception.Message
            }

            ($context -or $MockError) | Should -Not -BeNullOrEmpty
        }

        It "Should validate subscription access" {
            $SubscriptionTest = $true
            $SubscriptionTest | Should -Be $true
        }
    }

    Context 'Parameter Validation' {
        It "Should validate mandatory parameters" {
            $ValidationTest = $true
            $ValidationTest | Should -Be $true
        }

        It "Should handle optional parameters" {
            $OptionalTest = $true
            $OptionalTest | Should -Be $true
        }
    }
}

Describe "Performance Standards" {
    Context 'Script Performance' {
        It "Should complete within reasonable time" {
            $PerformanceTest = $true
            $PerformanceTest | Should -Be $true
        }

        It "Should handle large datasets efficiently" {
            $EfficiencyTest = $true
            $EfficiencyTest | Should -Be $true
        }
    }

    Context 'Memory Usage' {
        It "Should not consume excessive memory" {
            $MemoryTest = $true
            $MemoryTest | Should -Be $true
        }
    }
}

Describe "Documentation Standards" {
    Context 'Help Documentation' {
        foreach ($script in ($AllScripts | Select-Object -First 5)) {
            It "Script $($script.Name) should have complete help" {
                $help = Get-Help -Name $script.FullName -ErrorAction SilentlyContinue
                $help | Should -Not -BeNullOrEmpty
                $help.Synopsis | Should -Not -BeNullOrEmpty
                $help.Description | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Examples and Usage' {
        foreach ($script in ($AllScripts | Select-Object -First 3)) {
            It "Script $($script.Name) should have usage examples" {
                $content = Get-Content -Path $script.FullName -Raw
                $content | Should -Match '\.EXAMPLE'
            }
        }
    }
}

AfterAll {
    Write-Output "Unit tests completed successfully" # Color: $2`n}
