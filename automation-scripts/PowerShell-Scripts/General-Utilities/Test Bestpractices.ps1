<#
.SYNOPSIS
    Test Bestpractices

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
    We Enhanced Test Bestpractices

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

Verifies that the JSON template included in the sample is the same (via hash)
try {
    # Main script execution
as what we get when
we use bicep to compile the include bicep file.

Note: This script is only needed in the Azure pipeline, not intended for local use.





[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [string] $WESampleFolder = $WEENV:SAMPLE_FOLDER,
    [string] $WEMainTemplateDeploymentFilename = $WEENV:MAINTEMPLATE_DEPLOYMENT_FILENAME,
    [string] $ttkFolder = $WEENV:TTK_FOLDER,
    [string[]] $WESkip = $WEENV:TTK_SKIP_TESTS,
    [switch];  $bicepSupported = ($WEENV:BICEP_SUPPORTED -eq " true" )
)

Import-Module " $($ttkFolder)/arm-ttk/arm-ttk.psd1"


if($bicepSupported){
    bicep build " $($WESampleFolder)/$WEMainTemplateDeploymentFilename" --outfile " $($WESampleFolder)/azuredeploy.json"
}

Write-WELog " Calling Test-AzureTemplate on $WESampleFolder" " INFO" ; 
$testOutput = @(Test-AzTemplate -TemplatePath $WESampleFolder -Skip " $WESkip" )
$testOutput

if ($testOutput | ? { $_.Errors }) {
    exit 1 
}
else {
    Write-WELog " ##vso[task.setvariable variable=result.best.practice]$true" " INFO"
    exit 0
} 


if($bicepSupported){
    Remove-Item -ErrorAction Stop " -Force $($WESampleFolder)/azuredeploy.json"
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
