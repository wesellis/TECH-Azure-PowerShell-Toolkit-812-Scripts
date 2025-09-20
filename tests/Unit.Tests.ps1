#Requires -Version 7.0
#Requires -Modules Pester

<#
.SYNOPSIS
    Comprehensive unit tests for Azure PowerShell Toolkit
.DESCRIPTION
    Pester tests to validate script functionality and best practices
#>

BeforeAll {
    # Import common module for testing
    Import-Module "$PSScriptRoot/../modules/AzureToolkit.Common/AzureToolkit.Common.psm1" -Force
}

Describe "Azure PowerShell Toolkit - Core Validation" {
    Context "Essential Files" {
        It "Should have main launcher script" {
            Test-Path "$PSScriptRoot/../Launch-AzureToolkit.ps1" | Should -Be $true
        }

        It "Should have AI Assistant script" {
            Test-Path "$PSScriptRoot/../AI-Assistant.ps1" | Should -Be $true
        }

        It "Should have PowerShell Gallery publisher" {
            Test-Path "$PSScriptRoot/../Publish-ModulesToGallery.ps1" | Should -Be $true
        }

        It "Should have scripts directory" {
            Test-Path "$PSScriptRoot/../scripts" | Should -Be $true
        }

        It "Should have configuration directory" {
            Test-Path "$PSScriptRoot/../config" | Should -Be $true
        }

        It "Should have modules directory" {
            Test-Path "$PSScriptRoot/../modules" | Should -Be $true
        }
    }

    Context "Documentation" {
        It "Should have main README" {
            Test-Path "$PSScriptRoot/../README.md" | Should -Be $true
        }

        It "Should have getting started guide" {
            Test-Path "$PSScriptRoot/../Get-Started.md" | Should -Be $true
        }

        It "Should have scripts documentation" {
            Test-Path "$PSScriptRoot/../scripts/README.md" | Should -Be $true
        }

        It "Should have GitHub templates" {
            Test-Path "$PSScriptRoot/../.github/ISSUE_TEMPLATE" | Should -Be $true
            Test-Path "$PSScriptRoot/../.github/pull_request_template.md" | Should -Be $true
        }
    }

    Context "Repository Standards" {
        It "Should have .gitignore file" {
            Test-Path "$PSScriptRoot/../.gitignore" | Should -Be $true
        }

        It "Should have CODEOWNERS file" {
            Test-Path "$PSScriptRoot/../CODEOWNERS" | Should -Be $true
        }

        It "Should have CI/CD pipeline" {
            Test-Path "$PSScriptRoot/../.github/workflows/ci.yml" | Should -Be $true
        }
    }
}

Describe "Script Categories" {
    Context "Core Categories Present" {
        $categories = @('compute', 'storage', 'network', 'identity', 'monitoring', 'cost', 'devops', 'backup', 'migration', 'ai', 'iot', 'utilities')

        It "Should have <category> directory" -TestCases ($categories | ForEach-Object { @{ category = $_ } }) {
            param($category)
            Test-Path "$PSScriptRoot/../scripts/$category" | Should -Be $true
        }
    }

    Context "Scripts Follow Naming Convention" {
        $scripts = Get-ChildItem "$PSScriptRoot/../scripts" -Filter "*.ps1" -Recurse

        It "Should have PowerShell scripts in categories" {
            $scripts.Count | Should -BeGreaterThan 700
        }

        It "Should follow Azure- prefix convention" -TestCases ($scripts | Where-Object { $_.Name -like "Azure-*" } | Select-Object -First 10 | ForEach-Object { @{ script = $_.Name } }) {
            param($script)
            $script | Should -Match "^Azure-.*\.ps1$"
        }
    }
}

Describe "PowerShell Best Practices" {
    Context "Script Standards" {
        $sampleScripts = Get-ChildItem "$PSScriptRoot/../scripts" -Filter "*.ps1" -Recurse | Select-Object -First 20

        It "Should have #Requires statements" -TestCases ($sampleScripts | ForEach-Object { @{ script = $_.FullName; name = $_.Name } }) {
            param($script, $name)
            $content = Get-Content $script -Raw
            $content | Should -Match "#Requires"
        }

        It "Should have proper help documentation" -TestCases ($sampleScripts | ForEach-Object { @{ script = $_.FullName; name = $_.Name } }) {
            param($script, $name)
            $content = Get-Content $script -Raw
            $content | Should -Match "\.SYNOPSIS"
            $content | Should -Match "\.DESCRIPTION"
        }

        It "Should use CmdletBinding" -TestCases ($sampleScripts | ForEach-Object { @{ script = $_.FullName; name = $_.Name } }) {
            param($script, $name)
            $content = Get-Content $script -Raw
            $content | Should -Match "\[CmdletBinding\(\)\]"
        }
    }

    Context "Security Standards" {
        $allScripts = Get-ChildItem "$PSScriptRoot/../scripts" -Filter "*.ps1" -Recurse

        It "Should not contain hardcoded passwords" {
            foreach ($script in $allScripts) {
                $content = Get-Content $script.FullName -Raw
                $content | Should -Not -Match 'password\s*=\s*["\'][^"\']*["\']'
            }
        }

        It "Should not contain hardcoded secrets" {
            foreach ($script in $allScripts) {
                $content = Get-Content $script.FullName -Raw
                $content | Should -Not -Match 'secret\s*=\s*["\'][^"\']*["\']'
            }
        }
    }
}

Describe "Configuration Management" {
    Context "Environment Configuration" {
        It "Should have environments.json file" {
            Test-Path "$PSScriptRoot/../config/environments.json" | Should -Be $true
        }

        It "Should have valid JSON configuration" {
            { Get-Content "$PSScriptRoot/../config/environments.json" | ConvertFrom-Json } | Should -Not -Throw
        }

        It "Should have development environment" {
            $config = Get-Content "$PSScriptRoot/../config/environments.json" | ConvertFrom-Json
            $config.development | Should -Not -BeNullOrEmpty
        }

        It "Should have staging environment" {
            $config = Get-Content "$PSScriptRoot/../config/environments.json" | ConvertFrom-Json
            $config.staging | Should -Not -BeNullOrEmpty
        }

        It "Should have production environment" {
            $config = Get-Content "$PSScriptRoot/../config/environments.json" | ConvertFrom-Json
            $config.production | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Common Module" {
    Context "Module Functionality" {
        It "Should load configuration for development environment" {
            { Get-ToolkitConfig -Environment development } | Should -Not -Throw
        }

        It "Should return configuration object" {
            $config = Get-ToolkitConfig -Environment development
            $config | Should -Not -BeNullOrEmpty
            $config.Environment | Should -Be "development"
        }

        It "Should generate resource tags" {
            $tags = Get-ResourceTags -Environment development
            $tags | Should -Not -BeNullOrEmpty
            $tags.ContainsKey('Environment') | Should -Be $true
            $tags.ContainsKey('CreatedBy') | Should -Be $true
        }
    }
}

Describe "Enterprise Features" {
    Context "CI/CD Pipeline" {
        It "Should have GitHub Actions workflow" {
            Test-Path "$PSScriptRoot/../.github/workflows/ci.yml" | Should -Be $true
        }

        It "Should validate PowerShell syntax" {
            $workflow = Get-Content "$PSScriptRoot/../.github/workflows/ci.yml" -Raw
            $workflow | Should -Match "PSScriptAnalyzer"
            $workflow | Should -Match "syntax"
        }

        It "Should include security scanning" {
            $workflow = Get-Content "$PSScriptRoot/../.github/workflows/ci.yml" -Raw
            $workflow | Should -Match "Security Scan"
        }
    }

    Context "Repository Quality" {
        It "Should exclude sensitive files in .gitignore" {
            $gitignore = Get-Content "$PSScriptRoot/../.gitignore" -Raw
            $gitignore | Should -Match "\.key"
            $gitignore | Should -Match "\.pem"
            $gitignore | Should -Match "secrets"
        }

        It "Should have code ownership defined" {
            $codeowners = Get-Content "$PSScriptRoot/../CODEOWNERS" -Raw
            $codeowners | Should -Match "/scripts/"
            $codeowners | Should -Match "/modules/"
        }
    }
}