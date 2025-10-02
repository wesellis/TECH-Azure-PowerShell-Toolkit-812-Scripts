#Requires -Version 7.4

<#
.SYNOPSIS
    Run Once User Tasks for Dev Box

.DESCRIPTION
    Azure automation script executed only once per Dev Box VM, the very first time
    a user logs in. Performs initialization steps including first logon tasks
    and Dev Box Agent configuration backup.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions
    Executed once per Dev Box VM on first user logon
    Creates transcript log at C:\.tools\Setup\Logs\runonce-user-tasks.log
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Execute in script block to capture all output
& {
    try {
        # Start transcript logging
        $logPath = 'C:\.tools\Setup\Logs'
        if (-not (Test-Path $logPath)) {
            New-Item -Path $logPath -ItemType Directory -Force | Out-Null
        }

        Start-Transcript -Path "$logPath\runonce-user-tasks.log" -Append

        Write-Output "=== Starting Dev Box run-once user tasks"
        Write-Output "=== User: $env:USERNAME"
        Write-Output "=== Computer: $env:COMPUTERNAME"
        Write-Output "=== Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

        # Skip during Packer image creation
        if ($env:PACKER_BUILD_NAME) {
            Write-Output "=== Detected Packer build environment"
            Write-Output "=== Ignoring run-once tasks during image creation"
            return
        }

        # Set window title for visibility
        if ($host.UI.RawUI) {
            $host.UI.RawUI.WindowTitle = "Running Dev Box initialization steps"
        }

        # Run first logon tasks
        Write-Output "`n=== Running first logon tasks"
        $firstLogonScript = Join-Path $PSScriptRoot 'Run Firstlogon Tasks.ps1'

        if (Test-Path $firstLogonScript) {
            Write-Output "=== Executing: $firstLogonScript"
            & $firstLogonScript

            if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
                Write-Warning "First logon tasks exited with code: $LASTEXITCODE"
            }
        }
        else {
            Write-Warning "First logon script not found: $firstLogonScript"
        }

        # Copy Dev Box Agent configuration
        Write-Output "`n=== Backing up Dev Box Agent configuration"
        $DevBoxAgentInstallLocation = "${env:ProgramFiles}\Microsoft Dev Box Agent"

        if (Test-Path $DevBoxAgentInstallLocation -PathType Container) {
            Write-Output "=== Dev Box Agent found at: $DevBoxAgentInstallLocation"

            # Search for production settings file
            $DevBoxSettingsFiles = @(Get-ChildItem -Recurse -File -Path $DevBoxAgentInstallLocation -Filter 'appsettings.Production.json' -ErrorAction SilentlyContinue)

            if ($DevBoxSettingsFiles.Count -gt 0) {
                $sourceFile = $DevBoxSettingsFiles[0].FullName
                $destinationFile = 'C:\.tools\Setup\DevBoxAgent.json'

                Write-Output "=== Copying configuration from: $sourceFile"
                Write-Output "=== To: $destinationFile"

                # Ensure destination directory exists
                $destinationDir = Split-Path -Parent $destinationFile
                if (-not (Test-Path $destinationDir)) {
                    New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
                }

                Copy-Item -Path $sourceFile -Destination $destinationFile -Force
                Write-Output "=== Dev Box Agent configuration backed up successfully"
            }
            else {
                Write-Warning "No appsettings.Production.json file found in Dev Box Agent directory"
            }
        }
        else {
            Write-Warning "Dev Box Agent installation not found at: $DevBoxAgentInstallLocation"
        }

        Write-Output "`n=== Run-once user tasks completed successfully"
    }
    catch {
        Write-Error "[ERROR] Unhandled exception in run-once user tasks:"
        Write-Error "Exception: $_"
        Write-Error "Stack Trace: $($_.ScriptStackTrace)"

        # Don't rethrow to avoid blocking user logon
        # Just log the error and continue
    }
    finally {
        Write-Output "`n=== Ending transcript"
        Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    }
} | Out-Default

# Exit with success to avoid blocking logon process
exit 0