<#
.SYNOPSIS
    Get Templatehash.Tests

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Get Templatehash.Tests

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿Describe "Get-TemplateHash" {
    BeforeAll {
        $WEErrorActionPreference = 'Stop'    
        $dataFolder = " $(Split-Path $WEPSCommandPath -Parent)/data/get-template-hash-tests"

        function WE-Get-TemplateHash(
            [string][Parameter(Mandatory = $true)] $templateFilePath,
            [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$bearerToken,
            [switch]$removeGeneratorMetadata
        ) {
            $cmdlet = " $(Split-Path $WEPSCommandPath -Parent)/../ci-scripts/Get-TemplateHash.ps1" .Replace('.Tests.ps1', '.ps1')
            . $cmdlet $templateFilePath $bearerToken -RemoveGeneratorMetadata:$removeGeneratorMetadata
        }
    }
    
    It 'Correctly removes metadata from all nested deployments before hashing' {
        # hash with and without metadata should be the same
        $hash1 = Get-TemplateHash " $dataFolder/ModularTemplateWithMetadata.json" -RemoveGeneratorMetadata
        $hash2 = Get-TemplateHash " $dataFolder/ModularTemplateWithoutMetadata.json" -RemoveGeneratorMetadata

        $hash1 | Should -Be $hash2
    }

    It 'Correctly removes metadata before hashing' {
        # hash with and without metadata should be the same
        $hash1 = Get-TemplateHash " $dataFolder/TemplateWithMetadata.json" -RemoveGeneratorMetadata
        $hash2 = Get-TemplateHash " $dataFolder/TemplateWithoutMetadata.json" -RemoveGeneratorMetadata

        $hash1 | Should -Be $hash2
    }

    It 'Shows a hash difference between bicep versions if not using RemoveGeneratorMetadata' {
        # hash with and without metadata should be the same
        $hash1 = Get-TemplateHash " $dataFolder/TemplateWithMetadata.json"
        $hash2 = Get-TemplateHash " $dataFolder/TemplateWithoutMetadata.json"

        $hash1 | Should -Not -Be $hash2
    }

    It 'Shows hash difference when files differ outside of generator metadata' {
        # hash with and without metadata should be the same
       ;  $hash1 = Get-TemplateHash " $dataFolder/TemplateWithMetadata.json" -RemoveGeneratorMetadata
       ;  $hash2 = Get-TemplateHash " $dataFolder/TemplateWithMetadataWithChanges.json" -RemoveGeneratorMetadata

        $hash1 | Should -Not -Be $hash2
    }
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================