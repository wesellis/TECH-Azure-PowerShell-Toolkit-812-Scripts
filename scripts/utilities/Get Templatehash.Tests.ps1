#Requires -Version 7.4

<#
.SYNOPSIS
    Get Template Hash Tests

.DESCRIPTION
    Pester tests for Get-TemplateHash Azure automation script

    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

Describe "Get-TemplateHash" {
    BeforeAll {
        $ErrorActionPreference = 'Stop'
        $DataFolder = "$(Split-Path $PSCommandPath -Parent)/data/get-template-hash-tests"
        function Get-TemplateHash(
            [Parameter(Mandatory = $true)]
            [string]$TemplateFilePath,

            [Parameter()]
            [ValidateNotNullOrEmpty()]
            $BearerToken,

            [switch]$RemoveGeneratorMetadata
        ) {
            $cmdlet = "$(Split-Path $PSCommandPath -Parent)/../ci-scripts/Get-TemplateHash.ps1".Replace('.Tests.ps1', '.ps1')
            . $cmdlet $TemplateFilePath $BearerToken -RemoveGeneratorMetadata:$RemoveGeneratorMetadata
        }
    }

    It 'Correctly removes metadata from all nested deployments before hashing' {
        $hash1 = Get-TemplateHash -ErrorAction Stop "$DataFolder/ModularTemplateWithMetadata.json" -RemoveGeneratorMetadata
        $hash2 = Get-TemplateHash -ErrorAction Stop "$DataFolder/ModularTemplateWithoutMetadata.json" -RemoveGeneratorMetadata
        $hash1 | Should -Be $hash2
    }

    It 'Correctly removes metadata before hashing' {
        $hash1 = Get-TemplateHash -ErrorAction Stop "$DataFolder/TemplateWithMetadata.json" -RemoveGeneratorMetadata
        $hash2 = Get-TemplateHash -ErrorAction Stop "$DataFolder/TemplateWithoutMetadata.json" -RemoveGeneratorMetadata
        $hash1 | Should -Be $hash2
    }

    It 'Shows a hash difference between bicep versions if not using RemoveGeneratorMetadata' {
        $hash1 = Get-TemplateHash -ErrorAction Stop "$DataFolder/TemplateWithMetadata.json"
        $hash2 = Get-TemplateHash -ErrorAction Stop "$DataFolder/TemplateWithoutMetadata.json"
        $hash1 | Should -Not -Be $hash2
    }

    It 'Shows hash difference when files differ outside of generator metadata' {
        $hash1 = Get-TemplateHash -ErrorAction Stop "$DataFolder/TemplateWithMetadata.json" -RemoveGeneratorMetadata
        $hash2 = Get-TemplateHash -ErrorAction Stop "$DataFolder/TemplateWithMetadataWithChanges.json" -RemoveGeneratorMetadata
        $hash1 | Should -Not -Be $hash2
    }
}
