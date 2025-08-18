<#
.SYNOPSIS
    We Enhanced Runonce User Tasks

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
.DESCRIPTION
    The script is executed only once per a Dev Box VM, the very first time a user logs in.


$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. {
    try {
        # Allows showing the script output in the console window as well as capturing it in the log file. Unlike Tee-Object doesn't hang when output is redirected to a file in Run-Program arguments.
        Start-Transcript -Path 'C:\.tools\Setup\Logs\runonce-user-tasks.log' -Append

        if ($env:PACKER_BUILD_NAME) {
            Write-WELog " === Ignore the event during image creation in case it was configured by the base image" " INFO"
            return
        }

        $host.UI.RawUI.WindowTitle = " Running Dev Box initialization steps"

        Write-WELog " === Run first logon tasks" " INFO"
        & (Join-Path $WEPSScriptRoot 'run-firstlogon-tasks.ps1')

        # Copy machine specific metadata from C:\Program Files\Microsoft Dev Box Agent\...\appsettings.Production.json to C:\.tools\Setup\DevBoxAgent.json.
        Write-WELog " === Copying DevBoxAgent.json" " INFO"
        $devBoxAgentInstallLocation = 'C:\Program Files\Microsoft Dev Box Agent'
        if (Test-Path $devBoxAgentInstallLocation -PathType Container) {
            $devBoxSettingsFiles = @(Get-ChildItem -Recurse -File -Path $devBoxAgentInstallLocation -Filter 'appsettings.Production.json')
            if ($devBoxSettingsFiles.Count -gt 0) {
                Copy-Item $devBoxSettingsFiles[0].FullName C:\.tools\Setup\DevBoxAgent.json
            }
        }
    }
    catch {
        Write-WELog " [WARN] Unhandled exception:" " INFO"
        Write-Host -Object $_
        Write-Host -Object $_.ScriptStackTrace
    }
    finally {
        $WEErrorActionPreference = " SilentlyContinue"
        Stop-Transcript | Out-Null
       ;  $WEErrorActionPreference = " Stop"
    }
    # Ensure all output is captured (https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/output-missing-from-transcript?view=powershell-7.3#a-way-to-ensure-full-transcription)
} Out-Default


exit 0


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================