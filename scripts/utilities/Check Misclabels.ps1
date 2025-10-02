#Requires -Version 7.4

<#
.SYNOPSIS
    Check Miscellaneous Labels

.DESCRIPTION
    This script checks various properties of a sample to determine if labels need to be added:
    - Is the sample one of the 4 samples linked to by the custom deployment blade in the portal
    - Is the sample in the root of the repo
    - Does the sample name contain any uppercase characters (affects sorting in GitHub)

.PARAMETER SampleName
    Name of the sample to check

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SampleName = $ENV:SAMPLE_NAME
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

try {
    if ([string]::IsNullOrWhiteSpace($SampleName)) {
        throw "SampleName parameter is required"
    }

    Write-Output "Sample name: $SampleName"

    $PortalSamples = @(
        "101-vm-simple-linux",
        "quickstarts\microsoft.compute\vm-simple-linux",
        "101-vm-simple-windows",
        "quickstarts\microsoft.compute\vm-simple-windows",
        "201-cdn-with-web-app",
        "quickstarts\microsoft.cdn\cdn-with-web-app",
        "201-sql-database-transparent-encryption-create",
        "quickstarts\microsoft.sql\sql-database-transparent-encryption-create"
    )

    Write-Verbose "Portal samples list: $($PortalSamples -join ', ')"

    if ($PortalSamples -contains $SampleName) {
        Write-Output "Portal Sample match found..."
        Write-Output "##vso[task.setvariable variable=IsPortalSample]true"
    } else {
        Write-Verbose "Sample is not a portal sample"
        Write-Output "##vso[task.setvariable variable=IsPortalSample]false"
    }

    if (($SampleName.indexOf("\") -eq -1) -and ($SampleName.IndexOf("/") -eq -1)) {
        Write-Output "Sample is in the root of the repo..."
        Write-Output "##vso[task.setvariable variable=IsRootSample]true"
    } else {
        Write-Verbose "Sample is in a subdirectory"
        Write-Output "##vso[task.setvariable variable=IsRootSample]false"
    }

    if ($SampleName -cmatch "[A-Z]") {
        Write-Output "Sample name has UPPERCASE chars..."
        Write-Output "##vso[task.setvariable variable=SampleHasUpperCase]true"
    } else {
        Write-Verbose "Sample name is all lowercase"
        Write-Output "##vso[task.setvariable variable=SampleHasUpperCase]false"
    }

    Write-Verbose "Miscellaneous labels check completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}