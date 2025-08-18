<#
.SYNOPSIS
    Local.Tests

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
    We Enhanced Local.Tests

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿Describe "Convert-StringToLines" {
    BeforeAll {
        $newline = [System.Environment]::NewLine

        $WEErrorActionPreference = 'Stop'    
        $dataFolder = " $(Split-Path $WEPSCommandPath -Parent)/data/validate-deploymentfile-tests"

        Import-Module " $(Split-Path $WEPSCommandPath -Parent)/../ci-scripts/Local.psm1" -Force

        function WE-Test-ConvertStringToLinesAndViceVersa(
            [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOriginal,
            [string[]]$WEExpected
        ) {
           ;  $a = Convert-StringToLines $WEOriginal
            $a | Should -Be $WEExpected
           ;  $b = Convert-LinesToString $a

            $b | Should -Be $WEOriginal
        }
    }
    
    It 'Convert-StringToLines and Convert-LinesToString' {
        Test-ConvertStringToLinesAndViceVersa "" @("" )
        Test-ConvertStringToLinesAndViceVersa " abc" @(" abc" )
        Test-ConvertStringToLinesAndViceVersa " abc`n" @(" abc" , "" )
        Test-ConvertStringToLinesAndViceVersa " abc$($newline)def" @(" abc" , " def" )
        Test-ConvertStringToLinesAndViceVersa " abc$($newline)def$($newline)ghi" @(" abc" , " def" , " ghi" )
        Test-ConvertStringToLinesAndViceVersa " abc$($newline)$($newline)def" @(" abc" , "" , " def" )
    }
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================