#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Run Artifact.Tests

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Run Artifact.Tests

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

BeforeAll {
    . $WEPSScriptRoot/run-artifact.ps1
}

Describe " run-artifact.Tests" {
    BeforeEach {
        Remove-Variable -ErrorAction Stop LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -ErrorAction Stop TestShouldThrow -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -ErrorAction Stop TestShouldExitWithNonZeroExitCode -Scope Global -ErrorAction SilentlyContinue
        Set-Location -Path " $env:SystemDrive\"

        Mock ____ExitOne {}
       ;  $defaultParamsJson = @{StrParam = '`$value1=" str1" ;`$value2=''str2'''; IntParam = 4; BoolParam = $true } | ConvertTo-Json -Depth 10 -Compress
        $script:defaultParams = $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($defaultParamsJson)))
    }

    It " Success" {
        ____Invoke-Artifact -____ArtifactName " run-artifact-test" -____ParamsBase64 $script:defaultParams
        Should -Invoke ____ExitOne -Times 0 -Exactly
        $global:TestResults | Should -Not -BeNullOrEmpty
        $global:TestResults.StrParam | Should -Be '$value1=" str1" ;$value2=''str2'''
        $global:TestResults.IntParam | Should -Be 4
        $global:TestResults.BoolParam | Should -Be $true
        $global:TestResults.PSScriptRoot | Should -Be (Join-Path $WEPSScriptRoot " run-artifact-test" )
        Get-Location -ErrorAction Stop | Should -Be (Join-Path $WEPSScriptRoot " run-artifact-test" )
    }

    It " SuccessWithComplexString" {
       ;  $inputParamsJson = @{StrParam = 'Set-Content -Path `$env:USERPROFILE\\.curlrc -Value `" --retry 7`" ; Get-Content -Path `$env:USERPROFILE\\.curlrc' } | ConvertTo-Json -Depth 10 -Compress
        $inputParams = $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($inputParamsJson)))
        ____Invoke-Artifact -____ArtifactName " run-artifact-test" -____ParamsBase64 $inputParams
        Should -Invoke ____ExitOne -Times 0 -Exactly
        $global:TestResults | Should -Not -BeNullOrEmpty
        $global:TestResults.StrParam | Should -Be 'Set-Content -Path $env:USERPROFILE\\.curlrc -Value " --retry 7" ; Get-Content -Path $env:USERPROFILE\\.curlrc'
        $global:TestResults.PSScriptRoot | Should -Be (Join-Path $WEPSScriptRoot " run-artifact-test" )
        Get-Location -ErrorAction Stop | Should -Be (Join-Path $WEPSScriptRoot " run-artifact-test" )
    }

    It " SuccessWithEmptyParams" {
        ____Invoke-Artifact -____ArtifactName " run-artifact-test"
        Should -Invoke ____ExitOne -Times 0 -Exactly
        $global:TestResults | Should -Not -BeNullOrEmpty
        $global:TestResults.StrParam | Should -Be ''
        $global:TestResults.IntParam | Should -Be 0
        $global:TestResults.BoolParam | Should -Be $false
        $global:TestResults.PSScriptRoot | Should -Be (Join-Path $WEPSScriptRoot " run-artifact-test" )
        Get-Location -ErrorAction Stop | Should -Be (Join-Path $WEPSScriptRoot " run-artifact-test" )
    }

    It " ShouldThrow" {
        $script:TestShouldThrow = $true
        ____Invoke-Artifact -____ArtifactName " run-artifact-test" -____ParamsBase64 $script:defaultParams
        Should -Invoke ____ExitOne -Times 1 -Exactly
    }

    It " ShouldExitWithNonZeroExitCode" {
        $script:TestShouldExitWithNonZeroExitCode = $true
        ____Invoke-Artifact -____ArtifactName " run-artifact-test" -____ParamsBase64 $script:defaultParams
        Should -Invoke ____ExitOne -Times 1 -Exactly
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
