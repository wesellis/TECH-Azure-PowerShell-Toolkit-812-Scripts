#Requires -Version 7.4

<#`n.SYNOPSIS
    Test Bestpractices

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Verifies that the JSON template included in the sample is the same (via hash)
try {
as what we get when
we use bicep to compile the include bicep file.
Note: This script is only needed in the Azure pipeline, not intended for local use.
function Write-Host {
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $MainTemplateDeploymentFilename = $ENV:MAINTEMPLATE_DEPLOYMENT_FILENAME,
    [string] $TtkFolder = $ENV:TTK_FOLDER,
    [string[]] $Skip = $ENV:TTK_SKIP_TESTS,
    [switch];  $BicepSupported = ($ENV:BICEP_SUPPORTED -eq " true" )
)
Import-Module " $($TtkFolder)/arm-ttk/arm-ttk.psd1"
if($BicepSupported){
    bicep build " $($SampleFolder)/$MainTemplateDeploymentFilename" --outfile " $($SampleFolder)/azuredeploy.json"
}
Write-Output "Calling Test-AzureTemplate on $SampleFolder" ;
    $TestOutput = @(Test-AzTemplate -TemplatePath $SampleFolder -Skip " $Skip" )
    $TestOutput
if ($TestOutput | ? { $_.Errors }) {
    exit 1
}
else {
    Write-Output " ##vso[task.setvariable variable=result.best.practice]$true"
    exit 0
}
if($BicepSupported){
    Remove-Item -ErrorAction Stop " -Force $($SampleFolder)/azuredeploy.json"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
