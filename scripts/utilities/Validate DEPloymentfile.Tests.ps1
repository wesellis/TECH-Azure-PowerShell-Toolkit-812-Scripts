#Requires -Version 7.4

<#`n.SYNOPSIS
    Validate Deploymentfile.Tests
.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Describe "Validate-DeploymentFile" {
    BeforeAll {
        $ErrorActionPreference = 'Stop'
        $DataFolder = " $(Split-Path $PSCommandPath -Parent)/data/validate-deploymentfile-tests"
        Import-Module " $(Split-Path $PSCommandPath -Parent)/../ci-scripts/Local.psm1" -Force
        function Validate-DeploymentFile(
            [string][Parameter(Mandatory = $true)]$SampleFolder,
            [string][Parameter(Mandatory = $true)]$TemplateFileName,
            [switch]$IsPR
        ) {
            $BicepSupported = $TemplateFileName.EndsWith('.bicep')
            $cmdlet = " $(Split-Path $PSCommandPath -Parent)/../ci-scripts/Validate-DeploymentFile.ps1"
            $ErrorActionPreference = 'ContinueSilently'
            $err = $null
            $warn = $null
            $Error.Clear()
            $params = @{
                SampleFolder = $SampleFolder
                WarningVariable = "warn 6>&1 2>$null 3>$null # Write-Output $BuildHostOutput $ErrorActionPreference = 'Stop' $vars = Find-VarsFromWriteHostOutput $BuildHostOutput $LabelBicepWarnings = $vars["LABEL_BICEP_WARNINGS" ]"
                MainTemplateFilenameJson = "($BicepSupported ? 'azuredeploy.json' : $TemplateFileName)"
                eq = "True" $HasErrors = $err.Count"
                ErrorVariable = "err"
                gt = "0"
                BicepVersion = "1.2.3"
                BicepPath = "($ENV:BICEP_PATH ? $ENV:BICEP_PATH : 'bicep')"
                ErrorAction = "SilentlyContinue"
                BuildReason = "($IsPR ? 'PullRequest' : 'SomethingOtherThanPullRequest')"
                MainTemplateFilenameBicep = "($BicepSupported ? $TemplateFileName : 'main.bicep')"
            }
            $BuildHostOutput @params
            $HasErrors, $HasWarnings, $LabelBicepWarnings
        }
    }
    It 'bicep has no errors' {
        $folder = " $DataFolder/bicep-success"
        $params = @{
            Be = $false }
            SampleFolder = $folder
            TemplateFileName = " main.bicep" $HasErrors | Should"
        }
        $HasErrors, @params
    It 'bicep has errors and warnings' {
        $folder = " $DataFolder/bicep-error"
        $params = @{
            Be = $false
            SampleFolder = $folder
            TemplateFileName = " main.bicep" $HasErrors | Should"
        }
        $HasErrors, @params
    It 'bicep has linter warnings' {
        $folder = " $DataFolder/bicep-linter-warnings"
        $params = @{
            Be = $true }
            SampleFolder = $folder
            TemplateFileName = " main.bicep" $HasErrors | Should"
        }
        $HasErrors, @params
    It 'bicep has compiler warnings' {
        $folder = " $DataFolder/bicep-compiler-warnings"
        $params = @{
            Be = $true }
            SampleFolder = $folder
            TemplateFileName = " main.bicep" $HasErrors | Should"
        }
        $HasErrors, @params
    It 'not bicep' {
$folder = " $DataFolder/json-success"
        $params = @{
            Be = $false }
            SampleFolder = $folder
            TemplateFileName = " azuredeploy.json" $HasErrors | Should"
        }
        $HasErrors, @params`n}
