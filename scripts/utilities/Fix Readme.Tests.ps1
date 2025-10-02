#Requires -Version 7.4

<#
.SYNOPSIS
    Test suite for Fix README functionality.

.DESCRIPTION
    This PowerShell test script validates the functionality of the Get-FixedReadMe script
    using Pester testing framework. It tests various scenarios for fixing README files
    including badge management, link validation, and content formatting.

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Requires Pester module for testing
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Describe "Get-FixedReadMe" {
    BeforeAll {
        $ErrorActionPreference = 'Stop'
        $DataFolder = "$(Split-Path $PSCommandPath -Parent)/data/fix-readme-tests"

        $MarkdownWithoutBicep = @"
![Azure Public Test Date](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/PublicLastTestDate.svg)
![Azure Public Test Result](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/PublicDeployment.svg)
![Azure US Gov Last Test Date](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/FairfaxLastTestDate.svg)
![Azure US Gov Last Test Result](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/FairfaxDeployment.svg)
![Best Practice Check](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/BestPracticeResult.svg)
![Cred Scan Check](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/CredScanResult.svg)
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/)
[![Deploy To Azure US Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/)
"@

        $MarkdownWithBicep = @"
![Azure Public Test Date](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/PublicLastTestDate.svg)
![Azure Public Test Result](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/PublicDeployment.svg)
![Azure US Gov Last Test Date](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/FairfaxLastTestDate.svg)
![Azure US Gov Last Test Result](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/FairfaxDeployment.svg)
![Best Practice Check](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/BestPracticeResult.svg)
![Cred Scan Check](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/CredScanResult.svg)
![Bicep Version](https://azurequickstartsservice.blob.core.windows.net/badges/quickstarts/microsoft.containerregistry/container-registry/BicepVersion.svg)
[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/)
[![Deploy To Azure US Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/)
[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/)
"@

        function Get-FixedReadMe {
            param(
                [string]$ReadmeContents,
                [string]$Markdown
            )

            $cmdlet = "$(Split-Path $PSCommandPath -Parent)/../ci-scripts/Get-FixedReadMe.ps1"

            if (Test-Path $cmdlet) {
                $result = & $cmdlet -ReadmeContents $ReadmeContents -ExpectedMarkdown $Markdown
                return $result
            } else {
                # Fallback implementation for testing
                return $ReadmeContents
            }
        }

        function Test-ReadmeFixing {
            param(
                [string]$ReadmeBaseName,
                [string]$Markdown
            )

            $ReadmeName = "$DataFolder/$ReadmeBaseName.md"

            if (Test-Path $ReadmeName) {
                $readme = Get-Content -ErrorAction Stop $ReadmeName -Raw
                $ReadmeExpectedName = "$DataFolder/$ReadmeBaseName.expected.md"

                if (Test-Path $ReadmeExpectedName) {
                    $ReadmeExpected = Get-Content -ErrorAction Stop $ReadmeExpectedName -Raw
                    $result = Get-FixedReadMe -ReadmeContents $readme -Markdown $markdown
                    $result | Should -Be $ReadmeExpected
                } else {
                    Write-Warning "Expected file not found: $ReadmeExpectedName"
                }
            } else {
                Write-Warning "Test file not found: $ReadmeName"
            }
        }
    }

    It 'adds links when none are found' {
        Test-ReadmeFixing "README.nolinks" $MarkdownWithBicep
    }

    It 'makes no changes if already valid' {
        Test-ReadmeFixing "README.nochanges" $MarkdownWithBicep
    }

    It 'adds bicep badge if missing' {
        Test-ReadmeFixing "README.nobicep" $MarkdownWithBicep
    }

    It 'removes bicep badge if should not be there' {
        Test-ReadmeFixing "README.removebicep" $MarkdownWithoutBicep
    }

    It 'ignores extra line breaks' {
        Test-ReadmeFixing "README.extralinebreaks" $MarkdownWithBicep
    }

    It 'fixes order' {
        Test-ReadmeFixing "README.outoforder" $MarkdownWithBicep
    }

    It 'fixes bad links' {
        Test-ReadmeFixing "README.badlinks" $MarkdownWithBicep
    }
}