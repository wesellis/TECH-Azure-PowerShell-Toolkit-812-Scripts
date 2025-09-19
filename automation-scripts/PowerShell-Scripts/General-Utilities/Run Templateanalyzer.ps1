#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Run Templateanalyzer

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
    We Enhanced Run Templateanalyzer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#

Downloads and runs TemplateAnalyzer against the nested templates, the pre requisites template, and the main deployment template, along with their parameters files



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [string] $ttkFolder = $WEENV:TTK_FOLDER,
    [string] $templateAnalyzerReleaseUrl = $WEENV:TEMPLATE_ANALYZER_RELEASE_URL,
    [string] $sampleFolder = $WEENV:SAMPLE_FOLDER,
    [string] $prereqTemplateFilename = $WEENV:PREREQ_TEMPLATE_FILENAME_JSON, 
    [string] $prereqParametersFilename = $WEENV:GEN_PREREQ_PARAMETERS_FILENAME,
    [string] $mainTemplateFilename = $WEENV:MAINTEMPLATE_DEPLOYMENT_FILENAME,
    [string] $mainParametersFilename = $WEENV:GEN_PARAMETERS_FILENAME,
    [string] $templateAnalyzerOutputFilePath = $WEENV:TEMPLATE_ANALYZER_OUTPUT_FILEPATH
)

#region Functions

$templateAnalyzerFolderPath = " $ttkFolder\templateAnalyzer"
New-Item -ItemType Directory -Path $templateAnalyzerFolderPath -Force
Invoke-WebRequest -OutFile " $templateAnalyzerFolderPath\TemplateAnalyzer.zip" $templateAnalyzerReleaseUrl
Expand-Archive -LiteralPath " $templateAnalyzerFolderPath\TemplateAnalyzer.zip" -DestinationPath " $templateAnalyzerFolderPath"


$ttkFolderInsideTemplateAnalyzer = " $templateAnalyzerFolderPath\TTK"
if (Test-Path $ttkFolderInsideTemplateAnalyzer) {
    Remove-Item -LiteralPath $ttkFolderInsideTemplateAnalyzer -Force -Recurse
}

$templateAnalyzer = " $templateAnalyzerFolderPath\TemplateAnalyzer.exe"
[CmdletBinding()]
function WE-Analyze-Template {
    

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
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
        $templateFilePath,
        $parametersFilePath
    )

    if ($templateFilePath -and (Test-Path $templateFilePath)) {
        $params = @{}
        if ($parametersFilePath -and (Test-Path $parametersFilePath)) {
            $params.Add(" p" , $parametersFilePath)
        } 
        $testOutput = & $templateAnalyzer analyze-template $templateFilePath @params
    }
    $testOutput = $testOutput -join " `n"

    Write-Information $testOutput
    $testOutput >> $templateAnalyzerOutputFilePath

    if($WELASTEXITCODE -eq 0)
    {
        return $true
    } elseif ($WELASTEXITCODE -eq 20) {
        return $false
    } else {
        Write-Error " TemplateAnalyzer failed trying to analyze: $templateFilePath $parametersFilePath"
        return $false
    }
}

$passed = $true
$preReqsFolder = " $sampleFolder\prereqs"
$preReqsParamsFilePath = " $preReqsFolder\$prereqParametersFilename"
$mainParamsFilePath = " $sampleFolder\$mainParametersFilename"
Get-ChildItem -ErrorAction Stop $sampleFolder -Recurse -Filter *.json |
    Where-Object { (Get-Content -ErrorAction Stop $_.FullName) -like " *deploymentTemplate.json#*" } |
        ForEach-Object {
            if (@($preReqsParamsFilePath, $mainParamsFilePath).Contains($_.FullName)) {
                continue
            }

            $params = @{ " templateFilePath" = $_.FullName }
            if ($_.FullName -eq " $preReqsFolder\$prereqTemplateFilename" ) {
                $params.Add(" parametersFilePath" , $preReqsParamsFilePath)
            } elseif ($_.FullName -eq " $sampleFolder\$mainTemplateFilename" ) {
                $params.Add(" parametersFilePath" , $mainParamsFilePath)
            }

           ;  $newAnalysisPassed = Analyze-Template @params
           ;  $passed = $passed -and $newAnalysisPassed # evaluation done in two lines to avoid PowerShell's lazy evaluation
        }

Write-WELog " ##vso[task.setvariable variable=template.analyzer.result]$passed" " INFO"
exit [int]!$passed


} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
