<#
.SYNOPSIS
    Validate Deploymentfile.Tests
.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Describe "Validate-DeploymentFile" {
    BeforeAll {
        $ErrorActionPreference = 'Stop'
        $dataFolder = " $(Split-Path $PSCommandPath -Parent)/data/validate-deploymentfile-tests"
        Import-Module " $(Split-Path $PSCommandPath -Parent)/../ci-scripts/Local.psm1" -Force
        function Validate-DeploymentFile(
            [string][Parameter(Mandatory = $true)]$SampleFolder,
            [string][Parameter(Mandatory = $true)]$TemplateFileName,
            [switch]$isPR
        ) {
            $bicepSupported = $templateFileName.EndsWith('.bicep')
            $cmdlet = " $(Split-Path $PSCommandPath -Parent)/../ci-scripts/Validate-DeploymentFile.ps1"
            $ErrorActionPreference = 'ContinueSilently'
            $err = $null
            $warn = $null
            $Error.Clear()
            $params = @{
                SampleFolder = $SampleFolder
                WarningVariable = "warn 6>&1 2>$null 3>$null # Write-Host $buildHostOutput $ErrorActionPreference = 'Stop' $vars = Find-VarsFromWriteHostOutput $buildHostOutput $labelBicepWarnings = $vars["LABEL_BICEP_WARNINGS" ]"
                MainTemplateFilenameJson = "($bicepSupported ? 'azuredeploy.json' : $templateFileName)"
                eq = "True" $hasErrors = $err.Count"
                ErrorVariable = "err"
                gt = "0"
                BicepVersion = "1.2.3"
                BicepPath = "($ENV:BICEP_PATH ? $ENV:BICEP_PATH : 'bicep')"
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
$folder = " $dataFolder/json-success"
        $params = @{
            Be = $false }
            SampleFolder = $folder
            TemplateFileName = " azuredeploy.json" $hasErrors | Should"
        }
        $hasErrors, @params
}\n