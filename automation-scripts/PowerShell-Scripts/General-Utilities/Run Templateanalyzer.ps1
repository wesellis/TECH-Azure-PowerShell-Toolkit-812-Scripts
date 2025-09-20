<#
.SYNOPSIS
    Run Templateanalyzer

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
Downloads and runs TemplateAnalyzer against the nested templates, the pre requisites template, and the main deployment template, along with their parameters files
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
    [string] $ttkFolder = $ENV:TTK_FOLDER,
    [string] $templateAnalyzerReleaseUrl = $ENV:TEMPLATE_ANALYZER_RELEASE_URL,
    [string] $sampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $prereqTemplateFilename = $ENV:PREREQ_TEMPLATE_FILENAME_JSON,
    [string] $prereqParametersFilename = $ENV:GEN_PREREQ_PARAMETERS_FILENAME,
    [string] $mainTemplateFilename = $ENV:MAINTEMPLATE_DEPLOYMENT_FILENAME,
    [string] $mainParametersFilename = $ENV:GEN_PARAMETERS_FILENAME,
    [string] $templateAnalyzerOutputFilePath = $ENV:TEMPLATE_ANALYZER_OUTPUT_FILEPATH
)
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
function Analyze-Template {
function Write-Host {
    [CmdletBinding()]
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
    Write-Host $testOutput
    $testOutput >> $templateAnalyzerOutputFilePath
    if($LASTEXITCODE -eq 0)
    {
        return $true
    } elseif ($LASTEXITCODE -eq 20) {
        return $false
    } else {
        Write-Error "TemplateAnalyzer failed trying to analyze: $templateFilePath $parametersFilePath"
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
$newAnalysisPassed = Analyze-Template @params
$passed = $passed -and $newAnalysisPassed # evaluation done in two lines to avoid PowerShell's lazy evaluation
        }
Write-Host " ##vso[task.setvariable variable=template.analyzer.result]$passed"
exit [int]!$passed
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

