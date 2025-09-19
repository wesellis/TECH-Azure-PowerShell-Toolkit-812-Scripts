#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Validate Deploymentfile.Tests

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
    We Enhanced Validate Deploymentfile.Tests

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


﻿Describe "Validate-DeploymentFile" {
    BeforeAll {
        $WEErrorActionPreference = 'Stop'
        $dataFolder = " $(Split-Path $WEPSCommandPath -Parent)/data/validate-deploymentfile-tests"

        Import-Module " $(Split-Path $WEPSCommandPath -Parent)/../ci-scripts/Local.psm1" -Force
        
        function WE-Validate-DeploymentFile(
            [string][Parameter(Mandatory = $true)]$WESampleFolder,
            [string][Parameter(Mandatory = $true)]$WETemplateFileName,
            [switch]$isPR
        ) {
            $bicepSupported = $templateFileName.EndsWith('.bicep')
            $cmdlet = " $(Split-Path $WEPSCommandPath -Parent)/../ci-scripts/Validate-DeploymentFile.ps1"
            $WEErrorActionPreference = 'ContinueSilently'
            $err = $null
            $warn = $null
            $WEError.Clear()
            $params = @{
                SampleFolder = $WESampleFolder
                WarningVariable = "warn 6>&1 2>$null 3>$null # Write-Information $buildHostOutput $WEErrorActionPreference = 'Stop' $vars = Find-VarsFromWriteHostOutput $buildHostOutput $labelBicepWarnings = $vars[" LABEL_BICEP_WARNINGS" ]"
                MainTemplateFilenameJson = "($bicepSupported ? 'azuredeploy.json' : $templateFileName)"
                eq = " True" $hasErrors = $err.Count"
                ErrorVariable = "err"
                gt = "0"
                BicepVersion = "1.2.3"
                BicepPath = "($WEENV:BICEP_PATH ? $WEENV:BICEP_PATH : 'bicep')"
                ErrorAction = "SilentlyContinue"
                BuildReason = "($isPR ? 'PullRequest' : 'SomethingOtherThanPullRequest')"
                MainTemplateFilenameBicep = "($bicepSupported ? $templateFileName : 'main.bicep')"
            }
            $buildHostOutput @params

            $hasErrors, $hasWarnings, $labelBicepWarnings
        }
    }

    It 'bicep has no errors' {
        $folder = " $dataFolder/bicep-success"
        $params = @{
            Be = $false }
            SampleFolder = $folder
            TemplateFileName = " main.bicep" $hasErrors | Should"
        }
        $hasErrors, @params

    It 'bicep has errors and warnings' {
        $folder = " $dataFolder/bicep-error"
        $params = @{
            Be = $false # We only show the label if the build succeeds (no errors) }
            SampleFolder = $folder
            TemplateFileName = " main.bicep" $hasErrors | Should"
        }
        $hasErrors, @params

    It 'bicep has linter warnings' {
        $folder = " $dataFolder/bicep-linter-warnings"
        $params = @{
            Be = $true }
            SampleFolder = $folder
            TemplateFileName = " main.bicep" $hasErrors | Should"
        }
        $hasErrors, @params

    It 'bicep has compiler warnings' {
        $folder = " $dataFolder/bicep-compiler-warnings"
        $params = @{
            Be = $true }
            SampleFolder = $folder
            TemplateFileName = " main.bicep" $hasErrors | Should"
        }
        $hasErrors, @params

    It 'not bicep' {
       ;  $folder = " $dataFolder/json-success"
        $params = @{
            Be = $false }
            SampleFolder = $folder
            TemplateFileName = " azuredeploy.json" $hasErrors | Should"
        }
        $hasErrors, @params
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
