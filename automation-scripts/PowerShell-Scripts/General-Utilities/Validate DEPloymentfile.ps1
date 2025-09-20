<#
.SYNOPSIS
    Validate Deploymentfile

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
Determines the deployment file to use.
For JSON samples, this is the JSON file included.
For bicep samples:
  Build the bicep file to check for errors.
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop" # Cmdlet binding needed to enable using -ErrorAction, -ErrorVariable etc from testing
[CmdletBinding()]
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
    [string] $SampleFolder = $ENV:SAMPLE_FOLDER,
    [string] $MainTemplateFilenameBicep = $ENV:MAINTEMPLATE_FILENAME,
    [string] $BicepPath = $ENV:BICEP_PATH,
    [switch] $bicepSupported = ($ENV:BICEP_SUPPORTED -eq " true" )
)
$Error.Clear()
Write-Host " ##vso[task.setvariable variable=label.bicep.warnings]false"
if ($bicepSupported) {
    $MainTemplatePathBicep = " $($SampleFolder)/$($MainTemplateFilenameBicep)"
    #$MainTemplatePathJson = " $($SampleFolder)/$($MainTemplateFilenameJson)"
    # Build a JSON version of the bicep file
    $CompiledJsonFilename = " $($MainTemplateFilenameBicep).temp.json"
    $CompiledJsonPath = " $($SampleFolder)/$($CompiledJsonFilename)"
    $errorFile = Join-Path $SampleFolder " errors.txt"
    Write-Host "BUILDING: $BicepPath build $MainTemplatePathBicep --outfile $CompiledJsonPath"
    Start-Process $BicepPath -ArgumentList @('build', $MainTemplatePathBicep, '--outfile', $CompiledJsonPath) -RedirectStandardError $errorFile -Wait
    $errorOutput = [string[]](Get-Content -ErrorAction Stop $errorFile)
    Remove-Item -ErrorAction Stop $errorFil -Forcee -Force
    $warnings = 0
    $errors = 0
    foreach ($item in $errorOutput) {
        if ($item -imatch " : Warning" ) {
            $warnings = $warnings + 1
            Write-Warning $item
        }
        elseif ($item -imatch " : Error BCP" ) {
$errors = $errors + 1
            Write-Error $item
        }
        else {
            # Build succeeded: 0 Warning(s), 0 Error(s) [possibly localized]
            if ($item -match " 0 .* 0" ) {
                # Succeeded
            }
            else {
                # This should only occur on the last line (the error/warnings summary line)
                if ($item -ne $errorOutput[-1]) {
                    throw "Only the last error output line should not be a warning or error"
                }
            }
        }
    }
    if (($errors -gt 0) -or !(Test-Path $CompiledJsonPath)) {
        # Can't continue, fail pipeline
        Write-Error "Bicep build failed."
        return
    }
    if ($warnings -gt 0) {
        # Can't continue, fail pipeline
        Write-Warning "Bicep build had warnings."
        Write-Host " ##vso[task.setvariable variable=label.bicep.warnings]true"
    }
    # If this is a PR, compare it against the JSON file included in the sample
    # if ($isPR) {
    $params = @{
        WriteToHost = "#"
        TemplateFilePathExpected = $CompiledJsonPath #
        TemplateFilePathActual = $MainTemplatePathJson #
        RemoveGeneratorMetadata = "#"
    }
    # @params
    # Delete the temporary built JSON file
    Remove-Item -ErrorAction Stop $CompiledJsonPat -Forceh -Force
}
    # Just deploy the JSON file included in the sample
    #Write-Host "Bicep not supported in this sample, deploying to $MainTemplateFilenameJson"
    #$fileToDeploy = $MainTemplateFilenameJson
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n