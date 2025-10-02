#Requires -Version 7.4

<#`n.SYNOPSIS
    Invoke Gitcommandsv2

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
function Write-Log {
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param([Parameter()]
    [ValidateNotNullOrEmpty()]
    $Path)
    if (!(Test-Path $Path)) {
        Write-Warning "Required path not found: $Path"
        return $false
    }
    return $true
}
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
& "C:\Program Files\Git\mingw64\bin\git.exe" status
& "C:\Program Files\Git\mingw64\bin\git.exe" fetch
& "C:\Program Files\Git\mingw64\bin\git.exe" add -A
    $commit_message = $null;
    $commit_message = Read-Host -Prompt 'Please enter commit message'
& "C:\Program Files\Git\mingw64\bin\git.exe" commit -m $commit_message
& "C:\Program Files\Git\mingw64\bin\git.exe" push
& "C:\Program Files\Git\mingw64\bin\git.exe" pull
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
