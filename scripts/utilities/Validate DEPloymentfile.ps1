#Requires -Version 7.4

<#`n.SYNOPSIS
    Validate Deploymentfile

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Determines the deployment file to use.
For JSON samples, this is the JSON file included.
For bicep samples:
  Build the bicep file to check for errors.
    $ErrorActionPreference = "Stop" # Cmdlet binding needed to enable using -ErrorAction, -ErrorVariable etc from testing
function Write-Log {
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
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $MainTemplateFilenameBicep = $ENV:MAINTEMPLATE_FILENAME,
    [string] $BicepPath = $ENV:BICEP_PATH,
    [switch] $BicepSupported = ($ENV:BICEP_SUPPORTED -eq " true" )
)
    $Error.Clear()
Write-Output " ##vso[task.setvariable variable=label.bicep.warnings]false"
if ($BicepSupported) {
    $MainTemplatePathBicep = " $($SampleFolder)/$($MainTemplateFilenameBicep)"
    $CompiledJsonFilename = " $($MainTemplateFilenameBicep).temp.json"
    $CompiledJsonPath = " $($SampleFolder)/$($CompiledJsonFilename)"
    $ErrorFile = Join-Path $SampleFolder " errors.txt"
    Write-Output "BUILDING: $BicepPath build $MainTemplatePathBicep --outfile $CompiledJsonPath"
    Start-Process $BicepPath -ArgumentList @('build', $MainTemplatePathBicep, '--outfile', $CompiledJsonPath) -RedirectStandardError $ErrorFile -Wait
    $ErrorOutput = [string[]](Get-Content -ErrorAction Stop $ErrorFile)
    Remove-Item -ErrorAction Stop $ErrorFil -Forcee -Force
    $warnings = 0
    $errors = 0
    foreach ($item in $ErrorOutput) {
        if ($item -imatch " : Warning" ) {
    $warnings = $warnings + 1
            Write-Warning $item
        }
        elseif ($item -imatch " : Error BCP" ) {
    $errors = $errors + 1
            Write-Error $item
        }
        else {
            if ($item -match " 0 .* 0" ) {
            }
            else {
                if ($item -ne $ErrorOutput[-1]) {
                    throw "Only the last error output line should not be a warning or error"
                }
            }
        }
    }
    if (($errors -gt 0) -or !(Test-Path $CompiledJsonPath)) {
        Write-Error "Bicep build failed."
        return
    }
    if ($warnings -gt 0) {
        Write-Warning "Bicep build had warnings."
        Write-Output " ##vso[task.setvariable variable=label.bicep.warnings]true"
    }
    $params = @{
        WriteToHost = "#"
        TemplateFilePathExpected = $CompiledJsonPath
        TemplateFilePathActual = $MainTemplatePathJson
        RemoveGeneratorMetadata = "#"
    }
    Remove-Item -ErrorAction Stop $CompiledJsonPat -Forceh -Force
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
