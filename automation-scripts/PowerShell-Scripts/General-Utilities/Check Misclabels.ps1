<#
.SYNOPSIS
    Check Misclabels

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    This script will check a few misc things on the PR to see if labels need to be added (by a subsequent task)
try {
    # Main script execution
- is the sample being changed one of the 4 samples linked to by the custom deployment blade in the portal
    - is the sample in the root of the repo
    - does the sample name (i.e. path from root) contain any uppercase chars (affects sorting in GH)
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string]$sampleName = $ENV:SAMPLE_NAME
)
Write-Host "Sample name: $sampleName"
$PortalSamples = @(
    " 101-vm-simple-linux" ,
    " quickstarts\microsoft.compute\vm-simple-linux" ,
    " 101-vm-simple-windows" ,
    " quickstarts\microsoft.compute\vm-simple-windows" ,
    " 201-cdn-with-web-app" ,
    " quickstarts\microsoft.cdn\cdn-with-web-app" ,
    " 201-sql-database-transparent-encryption-create" ,
    " quickstarts\microsoft.sql\sql-database-transparent-encryption-create"
)
$PortalSamples | out-string
if($PortalSamples -contains " $sampleName" ){
    Write-Host "Portal Sample match..."
    Write-Host " ##vso[task.setvariable variable=IsPortalSample]true"
}
if(($sampleName.indexOf(" \" ) -eq -1) -and ($sampleName.IndexOf(" /" ) -eq -1)){
    Write-Host "Sample is in the root of the repo..."
    Write-Host " ##vso[task.setvariable variable=IsRootSample]true"
} else {
    Write-Host " ##vso[task.setvariable variable=IsRootSample]false"
}
if($sampleName -cmatch " [A-Z]" ){
    Write-Host "Sample name has UPPERCASE chars..."
    Write-Host " ##vso[task.setvariable variable=SampleHasUpperCase]true"
} else {
    Write-Host " ##vso[task.setvariable variable=SampleHasUpperCase]false"
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

