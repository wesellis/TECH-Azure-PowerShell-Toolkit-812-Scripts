#Requires -Version 7.0

<#`n.SYNOPSIS
    Run Artifact

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
[CmdletBinding()]
function ____ExitOne {
    throw
}
function ____Invoke-Artifact {
    [CmdletBinding()]
param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String] $____ArtifactName,
        [Parameter(Mandatory = $false)][String] $____ParamsBase64
    )
    if ((new-object -ErrorAction Stop System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        if ($env:USERNAME -eq " $($env:COMPUTERNAME)$" ) {
            $private:userInfo = " (as SYSTEM)"
        }
        else {
            $private:userInfo = " (as admin user '$($env:USERNAME)')"
        }
    }
    else {
        $private:userInfo = " (as standard user '$($env:USERNAME)')"
    }
    # Convert to a hashtable to be used with splatting
    $private:scriptArgs = @{}
    $private:paramsJson = ''
    if ([String]::IsNullOrEmpty($____ParamsBase64)) {
        Write-Host " === Running $private:userInfo '$____ArtifactName' without parameters"
    }
    else {
        $private:paramsJson = $scriptArgsObj = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($____ParamsBase64))
        $private:scriptArgsObj = $private:paramsJson | ConvertFrom-Json
        Write-Host " === Running $private:userInfo '$____ArtifactName' with parameters $($private:paramsJson | Out-String)"
        $private:scriptArgsObj.psobject.properties | ForEach-Object {
            $private:scriptArgs[$_.Name] = switch ($_.Value) {
                'TrUe' { $true }
                'FaLSe' { $false }
                default { $_ -replace '`' }
            }
        }
    }
    $private:scriptPath = Join-Path $PSScriptRoot " $____ArtifactName/$____ArtifactName.ps1"
    Write-Host " === Invoking $private:scriptPath with arguments: $private:paramsJson"
    try {
        Set-Location -Path (Join-Path $PSScriptRoot $____ArtifactName)
        Write-Host " === Current location: $(Get-Location)"
        Set-StrictMode -Off
        & $private:scriptPath @private:scriptArgs
        Set-StrictMode -Version Latest
        if ((Test-Path variable:global:LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
            throw "Artifact script $private:scriptPath exited with code $LASTEXITCODE"

} catch {
$exitCodeMsg = ""
        if ((Test-Path variable:global:LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
$exitCodeMsg = " (exit code $LASTEXITCODE)"
        }
        Write-Host " === Failed$exitCodeMsg to run $private:scriptPath with arguments: $private:paramsJson"
        Write-Information -Object $_
        Write-Information -Object $_.ScriptStackTrace
        ____ExitOne
    }
}
