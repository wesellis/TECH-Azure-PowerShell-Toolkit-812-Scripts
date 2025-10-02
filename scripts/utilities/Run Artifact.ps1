#Requires -Version 7.4

<#
.SYNOPSIS
    Run Azure DevTest Labs Artifact

.DESCRIPTION
    Azure automation script to execute Azure DevTest Labs artifacts.
    Handles parameter passing via Base64 encoded JSON and manages
    script execution with proper error handling.

.PARAMETER ArtifactName
    Name of the artifact to run

.PARAMETER ParamsBase64
    Base64 encoded JSON string containing artifact parameters

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions
    Designed for Azure DevTest Labs artifact execution
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Exit-WithError {
    <#
    .SYNOPSIS
        Exit script with error
    .DESCRIPTION
        Throws an exception to exit the script with error status
    #>
    throw "Script execution failed"
}

function Invoke-Artifact {
    <#
    .SYNOPSIS
        Invoke an artifact script
    .DESCRIPTION
        Executes an artifact script with optional parameters passed as Base64 encoded JSON
    .PARAMETER ArtifactName
        Name of the artifact to execute
    .PARAMETER ParamsBase64
        Base64 encoded JSON parameters
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ArtifactName,

        [Parameter(Mandatory = $false)]
        [String]$ParamsBase64
    )

    # Check if running as administrator
    $currentPrincipal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        if ($env:USERNAME -eq "$($env:COMPUTERNAME)$") {
            $userInfo = "(as SYSTEM)"
        }
        else {
            $userInfo = "(as admin user '$($env:USERNAME)')"
        }
    }
    else {
        $userInfo = "(as standard user '$($env:USERNAME)')"
    }

    # Initialize script arguments
    $scriptArgs = @{}
    $paramsJson = ''

    # Process parameters if provided
    if ([String]::IsNullOrEmpty($ParamsBase64)) {
        Write-Output "=== Running $userInfo '$ArtifactName' without parameters"
    }
    else {
        try {
            # Decode Base64 parameters
            $paramsJson = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($ParamsBase64))
            $scriptArgsObj = $paramsJson | ConvertFrom-Json

            Write-Output "=== Running $userInfo '$ArtifactName' with parameters:"
            Write-Output $paramsJson

            # Convert JSON object to hashtable for splatting
            $scriptArgsObj.PSObject.Properties | ForEach-Object {
                $scriptArgs[$_.Name] = switch ($_.Value) {
                    'TrUe' { $true }
                    'FaLSe' { $false }
                    default { $_ -replace '`' }
                }
            }
        }
        catch {
            Write-Error "Failed to decode or parse parameters: $_"
            Exit-WithError
        }
    }

    # Build script path
    $scriptPath = Join-Path $PSScriptRoot "$ArtifactName\$ArtifactName.ps1"

    if (-not (Test-Path $scriptPath)) {
        Write-Error "Artifact script not found: $scriptPath"
        Exit-WithError
    }

    Write-Output "=== Invoking $scriptPath"
    if ($scriptArgs.Count -gt 0) {
        Write-Output "=== With arguments: $($scriptArgs | ConvertTo-Json -Compress)"
    }

    try {
        # Change to artifact directory
        $artifactDir = Join-Path $PSScriptRoot $ArtifactName
        if (Test-Path $artifactDir) {
            Set-Location -Path $artifactDir
            Write-Output "=== Current location: $(Get-Location)"
        }

        # Temporarily disable strict mode for artifact script
        Set-StrictMode -Off

        # Execute the artifact script
        & $scriptPath @scriptArgs

        # Re-enable strict mode
        Set-StrictMode -Version Latest

        # Check exit code
        if ((Test-Path variable:global:LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
            throw "Artifact script $scriptPath exited with code $LASTEXITCODE"
        }

        Write-Output "=== Successfully executed artifact: $ArtifactName"
    }
    catch {
        $exitCodeMsg = ""
        if ((Test-Path variable:global:LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
            $exitCodeMsg = " (exit code $LASTEXITCODE)"
        }

        Write-Error "=== Failed$exitCodeMsg to run $scriptPath"
        Write-Error "Error: $_"
        Write-Error "Stack Trace: $($_.ScriptStackTrace)"

        Exit-WithError
    }
    finally {
        # Ensure strict mode is re-enabled
        Set-StrictMode -Version Latest
    }
}

# Export functions for use
Export-ModuleMember -Function Invoke-Artifact, Exit-WithError

# Example usage:
# Invoke-Artifact -ArtifactName "windows-7zip" -ParamsBase64 "eyJ2ZXJzaW9uIjoiMjEuMDcifQ=="