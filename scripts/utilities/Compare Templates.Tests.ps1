#Requires -Version 7.4
#Requires -Modules Pester

<#
.SYNOPSIS
    Compare Templates Tests

.DESCRIPTION
    Pester tests for Compare-Templates.ps1 script

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

Describe "Compare-Templates" {
    BeforeAll {
        $ErrorActionPreference = 'Stop'
        $DataFolder = "$(Split-Path $PSCommandPath -Parent)/data/get-template-hash-tests"

        function Compare-Templates {
            param(
                [Parameter(Mandatory = $true)]
                [string]$TemplateFilePathExpected,

                [Parameter(Mandatory = $true)]
                [string]$TemplateFilePathActual,

                [Parameter(Mandatory = $false)]
                [switch]$RemoveGeneratorMetadata
            )

            $cmdlet = "$(Split-Path $PSCommandPath -Parent)/../ci-scripts/Compare-Templates.ps1".Replace('.Tests.ps1', '.ps1')
            . $cmdlet $TemplateFilePathExpected $TemplateFilePathActual -RemoveGeneratorMetadata:$RemoveGeneratorMetadata -WriteToHost
        }
    }

    It 'Recognizes when templates are different' {
        $same = Compare-Templates "$DataFolder/TemplateWithMetadata.json" "$DataFolder/TemplateWithMetadataWithChanges.json"
        $same | Should -Be $false
    }

    It 'Shows difference when files differ outside of generator metadata with or without using -RemoveGeneratorMetadata' {
        $same = Compare-Templates "$DataFolder/TemplateWithMetadata.json" "$DataFolder/TemplateWithMetadataWithChanges.json"
        $same | Should -Be $false

        $same = Compare-Templates "$DataFolder/TemplateWithMetadata.json" "$DataFolder/TemplateWithMetadataWithChanges.json" -RemoveGeneratorMetadata
        $same | Should -Be $false
    }

    It 'Recognizes when templates are same except for metadata' {
        $same = Compare-Templates "$DataFolder/TemplateWithMetadata.json" "$DataFolder/TemplateWithoutMetadata.json" -RemoveGeneratorMetadata
        $same | Should -Be $true
    }

    It 'Recognizes when templates are same except for metadata with nested templates' {
        $same = Compare-Templates "$DataFolder/ModularTemplateWithMetadata.json" "$DataFolder/ModularTemplateWithoutMetadata.json" -RemoveGeneratorMetadata
        $same | Should -Be $true
    }

    It 'Shows a hash difference between bicep versions only if not using -RemoveGeneratorMetadata' {
        $same = Compare-Templates "$DataFolder/TemplateWithMetadata.json" "$DataFolder/TemplateWithoutMetadata.json"
        $same | Should -Be $false

        $same = Compare-Templates "$DataFolder/TemplateWithMetadata.json" "$DataFolder/TemplateWithoutMetadata.json" -RemoveGeneratorMetadata
        $same | Should -Be $true
    }
}