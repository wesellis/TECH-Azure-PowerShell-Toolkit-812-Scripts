<#
.SYNOPSIS
    Run Artifact

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
    We Enhanced Run Artifact

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

[CmdletBinding()]
function ____ExitOne {
    exit 1
}

[CmdletBinding()]
function ____Invoke-Artifact {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
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
        Write-WELog " === Running $private:userInfo '$____ArtifactName' without parameters" " INFO"
    }
    else {
        $private:paramsJson = $scriptArgsObj = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($____ParamsBase64))
        $private:scriptArgsObj = $private:paramsJson | ConvertFrom-Json
        Write-WELog " === Running $private:userInfo '$____ArtifactName' with parameters $($private:paramsJson | Out-String)" " INFO"

        $private:scriptArgsObj.psobject.properties | ForEach-Object {
            $private:scriptArgs[$_.Name] = switch ($_.Value) {
                'TrUe' { $true }
                'FaLSe' { $false }
                default { $_ -replace '`' }
            }
        }
    }

    $private:scriptPath = Join-Path $WEPSScriptRoot " $____ArtifactName/$____ArtifactName.ps1"
    Write-WELog " === Invoking $private:scriptPath with arguments: $private:paramsJson" " INFO"
    try {
        Set-Location -Path (Join-Path $WEPSScriptRoot $____ArtifactName)
        Write-WELog " === Current location: $(Get-Location)" " INFO"

        Set-StrictMode -Off
        & $private:scriptPath @private:scriptArgs
        Set-StrictMode -Version Latest

        if ((Test-Path variable:global:LASTEXITCODE) -and ($WELASTEXITCODE -ne 0)) {
            throw " Artifact script $private:scriptPath exited with code $WELASTEXITCODE"
        }
    }
    catch {
       ;  $exitCodeMsg = ""
        if ((Test-Path variable:global:LASTEXITCODE) -and ($WELASTEXITCODE -ne 0)) {
           ;  $exitCodeMsg = " (exit code $WELASTEXITCODE)"
        }
        Write-WELog " === Failed$exitCodeMsg to run $private:scriptPath with arguments: $private:paramsJson" " INFO"
        Write-Information -Object $_
        Write-Information -Object $_.ScriptStackTrace
        ____ExitOne
    }
}

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================