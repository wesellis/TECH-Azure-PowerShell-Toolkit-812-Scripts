#Requires -Version 7.4

<#`n.SYNOPSIS
    Run Templateanalyzer

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Downloads and runs TemplateAnalyzer against the nested templates, the pre requisites template, and the main deployment template, along with their parameters files
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [string] $TtkFolder = $ENV:TTK_FOLDER,
    [ValidateScript({
        if (

Downloads and runs TemplateAnalyzer against the nested templates, the pre requisites template, and the main deployment template, along with their parameters files
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [string] $TtkFolder = $ENV:TTK_FOLDER,
    [string] $TemplateAnalyzerReleaseUrl = $ENV:TEMPLATE_ANALYZER_RELEASE_URL,
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $PrereqTemplateFilename = $ENV:PREREQ_TEMPLATE_FILENAME_JSON,
    [string] $PrereqParametersFilename = $ENV:GEN_PREREQ_PARAMETERS_FILENAME,
    [string] $MainTemplateFilename = $ENV:MAINTEMPLATE_DEPLOYMENT_FILENAME,
    [string] $MainParametersFilename = $ENV:GEN_PARAMETERS_FILENAME,
    [string] $TemplateAnalyzerOutputFilePath = $ENV:TEMPLATE_ANALYZER_OUTPUT_FILEPATH
)
    $TemplateAnalyzerFolderPath = " $TtkFolder\templateAnalyzer"
New-Item -ItemType Directory -Path $TemplateAnalyzerFolderPath -Force
Invoke-WebRequest -OutFile " $TemplateAnalyzerFolderPath\TemplateAnalyzer.zip" $TemplateAnalyzerReleaseUrl
Expand-Archive -LiteralPath " $TemplateAnalyzerFolderPath\TemplateAnalyzer.zip" -DestinationPath " $TemplateAnalyzerFolderPath"
    $TtkFolderInsideTemplateAnalyzer = " $TemplateAnalyzerFolderPath\TTK"
if (Test-Path $TtkFolderInsideTemplateAnalyzer) {
    Remove-Item -LiteralPath $TtkFolderInsideTemplateAnalyzer -Force -Recurse
}
    $TemplateAnalyzer = " $TemplateAnalyzerFolderPath\TemplateAnalyzer.exe"
function Write-Log {
function Write-Host {
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
[CmdletBinding()
try {
]
param(
    $TemplateFilePath,
    $ParametersFilePath
    )
    if ($TemplateFilePath -and (Test-Path $TemplateFilePath)) {
    $params = @{}
        if ($ParametersFilePath -and (Test-Path $ParametersFilePath)) {
    $params.Add(" p" , $ParametersFilePath)
        }
    $TestOutput = & $TemplateAnalyzer analyze-template $TemplateFilePath @params
    }
    $TestOutput = $TestOutput -join " `n"
    Write-Output $TestOutput
    $TestOutput >> $TemplateAnalyzerOutputFilePath
    if($LASTEXITCODE -eq 0)
    {
        return $true
    } elseif ($LASTEXITCODE -eq 20) {
        return $false
    } else {
        Write-Error "TemplateAnalyzer failed trying to analyze: $TemplateFilePath $ParametersFilePath"
        return $false
    }
}
    $passed = $true
    $PreReqsFolder = " $SampleFolder\prereqs"
    $PreReqsParamsFilePath = " $PreReqsFolder\$PrereqParametersFilename"
    $MainParamsFilePath = " $SampleFolder\$MainParametersFilename"
Get-ChildItem -ErrorAction Stop $SampleFolder -Recurse -Filter *.json |
    Where-Object { (Get-Content -ErrorAction Stop $_.FullName) -like " *deploymentTemplate.json#*" } |
        ForEach-Object {
            if (@($PreReqsParamsFilePath, $MainParamsFilePath).Contains($_.FullName)) {
                continue
            }
    $params = @{ " templateFilePath" = $_.FullName }
            if ($_.FullName -eq " $PreReqsFolder\$PrereqTemplateFilename" ) {
    $params.Add(" parametersFilePath" , $PreReqsParamsFilePath)
            } elseif ($_.FullName -eq " $SampleFolder\$MainTemplateFilename" ) {
    $params.Add(" parametersFilePath" , $MainParamsFilePath)
            }
    $NewAnalysisPassed = Analyze-Template @params
    $passed = $passed -and $NewAnalysisPassed
        }
Write-Output " ##vso[task.setvariable variable=template.analyzer.result]$passed"
exit [int]!$passed
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


 -and

Downloads and runs TemplateAnalyzer against the nested templates, the pre requisites template, and the main deployment template, along with their parameters files
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [string] $TtkFolder = $ENV:TTK_FOLDER,
    [string] $TemplateAnalyzerReleaseUrl = $ENV:TEMPLATE_ANALYZER_RELEASE_URL,
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $PrereqTemplateFilename = $ENV:PREREQ_TEMPLATE_FILENAME_JSON,
    [string] $PrereqParametersFilename = $ENV:GEN_PREREQ_PARAMETERS_FILENAME,
    [string] $MainTemplateFilename = $ENV:MAINTEMPLATE_DEPLOYMENT_FILENAME,
    [string] $MainParametersFilename = $ENV:GEN_PARAMETERS_FILENAME,
    [string] $TemplateAnalyzerOutputFilePath = $ENV:TEMPLATE_ANALYZER_OUTPUT_FILEPATH
)
    $TemplateAnalyzerFolderPath = " $TtkFolder\templateAnalyzer"
New-Item -ItemType Directory -Path $TemplateAnalyzerFolderPath -Force
Invoke-WebRequest -OutFile " $TemplateAnalyzerFolderPath\TemplateAnalyzer.zip" $TemplateAnalyzerReleaseUrl
Expand-Archive -LiteralPath " $TemplateAnalyzerFolderPath\TemplateAnalyzer.zip" -DestinationPath " $TemplateAnalyzerFolderPath"
    $TtkFolderInsideTemplateAnalyzer = " $TemplateAnalyzerFolderPath\TTK"
if (Test-Path $TtkFolderInsideTemplateAnalyzer) {
    Remove-Item -LiteralPath $TtkFolderInsideTemplateAnalyzer -Force -Recurse
}
    $TemplateAnalyzer = " $TemplateAnalyzerFolderPath\TemplateAnalyzer.exe"
function Write-Log {
function Write-Host {
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
[CmdletBinding()
try {
]
param(
    $TemplateFilePath,
    $ParametersFilePath
    )
    if ($TemplateFilePath -and (Test-Path $TemplateFilePath)) {
    $params = @{}
        if ($ParametersFilePath -and (Test-Path $ParametersFilePath)) {
    $params.Add(" p" , $ParametersFilePath)
        }
    $TestOutput = & $TemplateAnalyzer analyze-template $TemplateFilePath @params
    }
    $TestOutput = $TestOutput -join " `n"
    Write-Output $TestOutput
    $TestOutput >> $TemplateAnalyzerOutputFilePath
    if($LASTEXITCODE -eq 0)
    {
        return $true
    } elseif ($LASTEXITCODE -eq 20) {
        return $false
    } else {
        Write-Error "TemplateAnalyzer failed trying to analyze: $TemplateFilePath $ParametersFilePath"
        return $false
    }
}
    $passed = $true
    $PreReqsFolder = " $SampleFolder\prereqs"
    $PreReqsParamsFilePath = " $PreReqsFolder\$PrereqParametersFilename"
    $MainParamsFilePath = " $SampleFolder\$MainParametersFilename"
Get-ChildItem -ErrorAction Stop $SampleFolder -Recurse -Filter *.json |
    Where-Object { (Get-Content -ErrorAction Stop $_.FullName) -like " *deploymentTemplate.json#*" } |
        ForEach-Object {
            if (@($PreReqsParamsFilePath, $MainParamsFilePath).Contains($_.FullName)) {
                continue
            }
    $params = @{ " templateFilePath" = $_.FullName }
            if ($_.FullName -eq " $PreReqsFolder\$PrereqTemplateFilename" ) {
    $params.Add(" parametersFilePath" , $PreReqsParamsFilePath)
            } elseif ($_.FullName -eq " $SampleFolder\$MainTemplateFilename" ) {
    $params.Add(" parametersFilePath" , $MainParamsFilePath)
            }
    $NewAnalysisPassed = Analyze-Template @params
    $passed = $passed -and $NewAnalysisPassed
        }
Write-Output " ##vso[task.setvariable variable=template.analyzer.result]$passed"
exit [int]!$passed
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


 -notmatch '^https?://') {
            throw 'URL must start with http:// or https://'
        }
    $true
    })]
    [string] $TemplateAnalyzerReleaseUrl = $ENV:TEMPLATE_ANALYZER_RELEASE_URL,
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $PrereqTemplateFilename = $ENV:PREREQ_TEMPLATE_FILENAME_JSON,
    [string] $PrereqParametersFilename = $ENV:GEN_PREREQ_PARAMETERS_FILENAME,
    [string] $MainTemplateFilename = $ENV:MAINTEMPLATE_DEPLOYMENT_FILENAME,
    [string] $MainParametersFilename = $ENV:GEN_PARAMETERS_FILENAME,
    [string] $TemplateAnalyzerOutputFilePath = $ENV:TEMPLATE_ANALYZER_OUTPUT_FILEPATH
)
    $TemplateAnalyzerFolderPath = " $TtkFolder\templateAnalyzer"
New-Item -ItemType Directory -Path $TemplateAnalyzerFolderPath -Force
Invoke-WebRequest -OutFile " $TemplateAnalyzerFolderPath\TemplateAnalyzer.zip" $TemplateAnalyzerReleaseUrl
Expand-Archive -LiteralPath " $TemplateAnalyzerFolderPath\TemplateAnalyzer.zip" -DestinationPath " $TemplateAnalyzerFolderPath"
    $TtkFolderInsideTemplateAnalyzer = " $TemplateAnalyzerFolderPath\TTK"
if (Test-Path $TtkFolderInsideTemplateAnalyzer) {
    Remove-Item -LiteralPath $TtkFolderInsideTemplateAnalyzer -Force -Recurse
}
    $TemplateAnalyzer = " $TemplateAnalyzerFolderPath\TemplateAnalyzer.exe"
function Write-Log {
function Write-Host {
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
[CmdletBinding()
try {
]
param(
    $TemplateFilePath,
    $ParametersFilePath
    )
    if ($TemplateFilePath -and (Test-Path $TemplateFilePath)) {
    $params = @{}
        if ($ParametersFilePath -and (Test-Path $ParametersFilePath)) {
    $params.Add(" p" , $ParametersFilePath)
        }
    $TestOutput = & $TemplateAnalyzer analyze-template $TemplateFilePath @params
    }
    $TestOutput = $TestOutput -join " `n"
    Write-Output $TestOutput
    $TestOutput >> $TemplateAnalyzerOutputFilePath
    if($LASTEXITCODE -eq 0)
    {
        return $true
    } elseif ($LASTEXITCODE -eq 20) {
        return $false
    } else {
        Write-Error "TemplateAnalyzer failed trying to analyze: $TemplateFilePath $ParametersFilePath"
        return $false
    }
}
    $passed = $true
    $PreReqsFolder = " $SampleFolder\prereqs"
    $PreReqsParamsFilePath = " $PreReqsFolder\$PrereqParametersFilename"
    $MainParamsFilePath = " $SampleFolder\$MainParametersFilename"
Get-ChildItem -ErrorAction Stop $SampleFolder -Recurse -Filter *.json |
    Where-Object { (Get-Content -ErrorAction Stop $_.FullName) -like " *deploymentTemplate.json#*" } |
        ForEach-Object {
            if (@($PreReqsParamsFilePath, $MainParamsFilePath).Contains($_.FullName)) {
                continue
            }
    $params = @{ " templateFilePath" = $_.FullName }
            if ($_.FullName -eq " $PreReqsFolder\$PrereqTemplateFilename" ) {
    $params.Add(" parametersFilePath" , $PreReqsParamsFilePath)
            } elseif ($_.FullName -eq " $SampleFolder\$MainTemplateFilename" ) {
    $params.Add(" parametersFilePath" , $MainParamsFilePath)
            }
    $NewAnalysisPassed = Analyze-Template @params
    $passed = $passed -and $NewAnalysisPassed
        }
Write-Output " ##vso[task.setvariable variable=template.analyzer.result]$passed"
exit [int]!$passed
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
