#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Validate Deploymentfile

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
    We Enhanced Validate Deploymentfile

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
function Write-WELog {
    [CmdletBinding()]
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
param(
    [string] $WESampleFolder = $WEENV:SAMPLE_FOLDER,
    [string] $WEMainTemplateFilenameBicep = $WEENV:MAINTEMPLATE_FILENAME,

    [string] $WEBicepPath = $WEENV:BICEP_PATH,

    [switch] $bicepSupported = ($WEENV:BICEP_SUPPORTED -eq " true" )
)

#region Functions

$WEError.Clear()


Write-WELog " ##vso[task.setvariable variable=label.bicep.warnings]false" " INFO"

if ($bicepSupported) {
    $WEMainTemplatePathBicep = " $($WESampleFolder)/$($WEMainTemplateFilenameBicep)"
    #$WEMainTemplatePathJson = " $($WESampleFolder)/$($WEMainTemplateFilenameJson)"
    
    # Build a JSON version of the bicep file
    $WECompiledJsonFilename = " $($WEMainTemplateFilenameBicep).temp.json"
    $WECompiledJsonPath = " $($WESampleFolder)/$($WECompiledJsonFilename)"
    $errorFile = Join-Path $WESampleFolder " errors.txt"
    Write-Information " BUILDING: $WEBicepPath build $WEMainTemplatePathBicep --outfile $WECompiledJsonPath"
    Start-Process $WEBicepPath -ArgumentList @('build', $WEMainTemplatePathBicep, '--outfile', $WECompiledJsonPath) -RedirectStandardError $errorFile -Wait
    $errorOutput = [string[]](Get-Content -ErrorAction Stop $errorFile)

    Remove-Item -ErrorAction Stop $errorFil -Forcee -Force
    
    $warnings = 0
    $errors = 0
    foreach ($item in $errorOutput) {
        if ($item -imatch " : Warning " ) {
            $warnings = $warnings + 1
            Write-Warning $item
        }
        elseif ($item -imatch " : Error BCP" ) {
           ;  $errors = $errors + 1
            Write-Error $item
        }
        else {
            # Build succeeded: 0 Warning(s), 0 Error(s) [possibly localized]
            if ($item -match " 0 .* 0 " ) {
                # Succeeded
            }
            else {
                # This should only occur on the last line (the error/warnings summary line)
                if ($item -ne $errorOutput[-1]) {
                    throw " Only the last error output line should not be a warning or error"
                }
            }
        }
    }

    if (($errors -gt 0) -or !(Test-Path $WECompiledJsonPath)) {
        # Can't continue, fail pipeline
        Write-Error " Bicep build failed."
        return
    }    

    if ($warnings -gt 0) {
        # Can't continue, fail pipeline
        Write-Warning " Bicep build had warnings."
        Write-WELog " ##vso[task.setvariable variable=label.bicep.warnings]true" " INFO"
    }    







    # If this is a PR, compare it against the JSON file included in the sample
    # if ($isPR) {
    $params = @{
        WriteToHost = "#"
        TemplateFilePathExpected = $WECompiledJsonPath #
        TemplateFilePathActual = $WEMainTemplatePathJson #
        RemoveGeneratorMetadata = "#"
    }
    # @params

    # Delete the temporary built JSON file
    Remove-Item -ErrorAction Stop $WECompiledJsonPat -Forceh -Force
}

    # Just deploy the JSON file included in the sample
    #Write-WELog " Bicep not supported in this sample, deploying to $WEMainTemplateFilenameJson" " INFO"
    #$fileToDeploy = $WEMainTemplateFilenameJson






} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
