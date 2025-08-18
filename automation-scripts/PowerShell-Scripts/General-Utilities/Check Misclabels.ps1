<#
.SYNOPSIS
    Check Misclabels

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
    We Enhanced Check Misclabels

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

    This script will check a few misc things on the PR to see if labels need to be added (by a subsequent task)
try {
    # Main script execution
- is the sample being changed one of the 4 samples linked to by the custom deployment blade in the portal
    - is the sample in the root of the repo
    - does the sample name (i.e. path from root) contain any uppercase chars (affects sorting in GH)


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string]$sampleName = $WEENV:SAMPLE_NAME
)

Write-WELog " Sample name: $sampleName" " INFO"

; 
$WEPortalSamples = @(
    " 101-vm-simple-linux" ,
    " quickstarts\microsoft.compute\vm-simple-linux" ,
    " 101-vm-simple-windows" ,
    " quickstarts\microsoft.compute\vm-simple-windows" ,
    " 201-cdn-with-web-app" ,
    " quickstarts\microsoft.cdn\cdn-with-web-app" ,
    " 201-sql-database-transparent-encryption-create" ,
    " quickstarts\microsoft.sql\sql-database-transparent-encryption-create"
)
$WEPortalSamples | out-string

if($WEPortalSamples -contains " $sampleName" ){
    Write-WELog " Portal Sample match..." " INFO"
    Write-WELog " ##vso[task.setvariable variable=IsPortalSample]true" " INFO"
}


if(($sampleName.indexOf(" \" ) -eq -1) -and ($sampleName.IndexOf(" /" ) -eq -1)){
    Write-WELog " Sample is in the root of the repo..." " INFO"
    Write-WELog " ##vso[task.setvariable variable=IsRootSample]true" " INFO"
} else {
    Write-WELog " ##vso[task.setvariable variable=IsRootSample]false" " INFO"
}


if($sampleName -cmatch " [A-Z]" ){
    Write-WELog " Sample name has UPPERCASE chars..." " INFO"
    Write-WELog " ##vso[task.setvariable variable=SampleHasUpperCase]true" " INFO"
} else {
    Write-WELog " ##vso[task.setvariable variable=SampleHasUpperCase]false" " INFO"    
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
