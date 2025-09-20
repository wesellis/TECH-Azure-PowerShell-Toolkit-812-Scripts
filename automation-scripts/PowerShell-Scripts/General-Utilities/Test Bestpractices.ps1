<#
.SYNOPSIS
    Test Bestpractices

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
Verifies that the JSON template included in the sample is the same (via hash)
try {
    # Main script execution
as what we get when
we use bicep to compile the include bicep file.
Note: This script is only needed in the Azure pipeline, not intended for local use.
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $MainTemplateDeploymentFilename = $ENV:MAINTEMPLATE_DEPLOYMENT_FILENAME,
    [string] $ttkFolder = $ENV:TTK_FOLDER,
    [string[]] $Skip = $ENV:TTK_SKIP_TESTS,
    [switch];  $bicepSupported = ($ENV:BICEP_SUPPORTED -eq " true" )
)
Import-Module " $($ttkFolder)/arm-ttk/arm-ttk.psd1"
if($bicepSupported){
    bicep build " $($SampleFolder)/$MainTemplateDeploymentFilename" --outfile " $($SampleFolder)/azuredeploy.json"
}
Write-Host "Calling Test-AzureTemplate on $SampleFolder" ;
$testOutput = @(Test-AzTemplate -TemplatePath $SampleFolder -Skip " $Skip" )
$testOutput
if ($testOutput | ? { $_.Errors }) {
    exit 1
}
else {
    Write-Host " ##vso[task.setvariable variable=result.best.practice]$true"
    exit 0
}
if($bicepSupported){
    Remove-Item -ErrorAction Stop " -Force $($SampleFolder)/azuredeploy.json"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

