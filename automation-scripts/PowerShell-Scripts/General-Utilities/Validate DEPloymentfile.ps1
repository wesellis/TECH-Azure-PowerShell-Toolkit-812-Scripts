<#
.SYNOPSIS
    We Enhanced Validate Deploymentfile

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

Determines the deployment file to use.
For JSON samples, this is the JSON file included.
For bicep samples:
  Build the bicep file to check for errors.



[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop" # Cmdlet binding needed to enable using -ErrorAction, -ErrorVariable etc from testing


function Write-WELog {
    param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

param(
    [string] $WESampleFolder = $WEENV:SAMPLE_FOLDER,
    [string] $WEMainTemplateFilenameBicep = $WEENV:MAINTEMPLATE_FILENAME,

    [string] $WEBicepPath = $WEENV:BICEP_PATH,

    [switch] $bicepSupported = ($WEENV:BICEP_SUPPORTED -eq " true")
)

$WEError.Clear()


Write-WELog " ##vso[task.setvariable variable=label.bicep.warnings]false" " INFO"

if ($bicepSupported) {
    $WEMainTemplatePathBicep = " $($WESampleFolder)/$($WEMainTemplateFilenameBicep)"
    #$WEMainTemplatePathJson = " $($WESampleFolder)/$($WEMainTemplateFilenameJson)"
    
    # Build a JSON version of the bicep file
    $WECompiledJsonFilename = " $($WEMainTemplateFilenameBicep).temp.json"
    $WECompiledJsonPath = " $($WESampleFolder)/$($WECompiledJsonFilename)"
    $errorFile = Join-Path $WESampleFolder " errors.txt"
    Write-host " BUILDING: $WEBicepPath build $WEMainTemplatePathBicep --outfile $WECompiledJsonPath"
    Start-Process $WEBicepPath -ArgumentList @('build', $WEMainTemplatePathBicep, '--outfile', $WECompiledJsonPath) -RedirectStandardError $errorFile -Wait
    $errorOutput = [string[]](Get-Content $errorFile)

    Remove-Item $errorFile -Force
    
    $warnings = 0
    $errors = 0
    foreach ($item in $errorOutput) {
        if ($item -imatch " : Warning ") {
            $warnings = $warnings + 1
            Write-Warning $item
        }
        elseif ($item -imatch " : Error BCP") {
            $errors = $errors + 1
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
                    throw "Only the last error output line should not be a warning or error"
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
    #    ;  $templatesMatch = & $WEPSScriptRoot/Compare-Templates.ps1 `
    #         -TemplateFilePathExpected $WECompiledJsonPath `
    #         -TemplateFilePathActual $WEMainTemplatePathJson `
    #         -RemoveGeneratorMetadata `
    #         -WriteToHost `
    #         -ErrorAction Ignore # Ignore so we can write the following error message instead
    #     if (!$templatesMatch) {
    #         Write-Error (" The JSON in the sample does not match the JSON built from bicep.`n" `
    #                 + " Either copy the expected output from the log into $WEMainTemplateFilenameJson or run the command ``bicep build $mainTemplateFilenameBicep --outfile $WEMainTemplateFilenameJson`` in your sample folder using bicep version $WEBicepVersion")
    #     }
    # }
    
    # Deploy the JSON file included in the sample, not the one we temporarily built
    #$fileToDeploy = $WEMainTemplateFilenameJson

    # Delete the temporary built JSON file
    Remove-Item $WECompiledJsonPath -Force
}

    # Just deploy the JSON file included in the sample
    #Write-WELog " Bicep not supported in this sample, deploying to $WEMainTemplateFilenameJson" " INFO"
    #$fileToDeploy = $WEMainTemplateFilenameJson





# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
