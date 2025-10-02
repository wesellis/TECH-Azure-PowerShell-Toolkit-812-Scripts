#Requires -Version 7.4

<#
.SYNOPSIS
    Run First Logon Tasks

.DESCRIPTION
    Azure automation script that executes user first logon tasks configured
    for the image in C:\.tools\Setup\FirstLogonTasks.json. Processes tasks
    sequentially with error handling for each task.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions
    Tasks are defined in JSON configuration file
    Each task can have optional parameters
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Define paths
$SetupScriptsDir = $PSScriptRoot
$SetupDir = Split-Path -Parent $PSScriptRoot
$FirstLogonTasksDir = "$SetupScriptsDir\FirstLogonTasks"
$FirstLogonTasksFile = "$SetupDir\FirstLogonTasks.json"

try {
    # Check if configuration file exists
    if (!(Test-Path -Path $FirstLogonTasksFile -PathType Leaf)) {
        Write-Output "=== Nothing to do because $FirstLogonTasksFile doesn't exist"
        return
    }

    Write-Output "=== Executing tasks from $FirstLogonTasksFile"

    # Load tasks from JSON file
    $FirstLogonTasksContent = Get-Content -Path $FirstLogonTasksFile -Raw -ErrorAction Stop
    $FirstLogonTasks = $FirstLogonTasksContent | ConvertFrom-Json

    if (-not $FirstLogonTasks) {
        Write-Warning "No tasks found in $FirstLogonTasksFile"
        return
    }

    $totalTasks = @($FirstLogonTasks).Count
    $completedTasks = 0
    $failedTasks = 0

    Write-Output "=== Found $totalTasks task(s) to execute"

    # Process each task
    foreach ($FirstLogonTask in $FirstLogonTasks) {
        $TaskName = $FirstLogonTask.Task
        $TaskScript = "$FirstLogonTasksDir\$TaskName.ps1"

        Write-Output "`n=== Processing task: $TaskName"

        # Validate task script exists
        if (!(Test-Path -Path $TaskScript -PathType Leaf)) {
            Write-Warning "[WARN] Skipped task $TaskName : couldn't find $TaskScript"
            $failedTasks++
            continue
        }

        try {
            # Execute task with or without parameters
            if ($FirstLogonTask.PSObject.Properties.Name -contains 'Parameters') {
                $TaskParams = $FirstLogonTask.Parameters
                Write-Output "=== Executing task $TaskName with parameters:"
                Write-Output ($TaskParams | ConvertTo-Json -Depth 10)

                # Convert parameters to hashtable for splatting
                $paramHash = @{}
                $TaskParams.PSObject.Properties | ForEach-Object {
                    $paramHash[$_.Name] = $_.Value
                }

                & $TaskScript @paramHash
            }
            else {
                Write-Output "=== Executing task $TaskName without parameters"
                & $TaskScript
            }

            # Check exit code
            if ((Test-Path variable:LASTEXITCODE) -and ($LASTEXITCODE -ne 0)) {
                throw "Task exited with code $LASTEXITCODE"
            }

            $completedTasks++
            Write-Output "=== Task $TaskName completed successfully"
        }
        catch {
            $failedTasks++
            Write-Warning "[WARN] Task $TaskName failed: $_"
            Write-Verbose "Error details: $($_.Exception.Message)"
            Write-Verbose "Stack trace: $($_.ScriptStackTrace)"

            # Continue with next task despite failure
            continue
        }
    }

    # Summary
    Write-Output "`n=== Task execution summary:"
    Write-Output "    Total tasks: $totalTasks"
    Write-Output "    Completed: $completedTasks"
    Write-Output "    Failed/Skipped: $failedTasks"

    if ($failedTasks -gt 0) {
        Write-Warning "Some tasks failed. Please review the warnings above."
    }

    Write-Output "=== Done executing tasks from $FirstLogonTasksFile"
}
catch {
    Write-Error "Failed to process first logon tasks: $_"
    throw
}

# Example FirstLogonTasks.json format:
<#
[
    {
        "Task": "ConfigureDesktop",
        "Parameters": {
            "Theme": "Dark",
            "Resolution": "1920x1080"
        }
    },
    {
        "Task": "InstallTools"
    }
]
#>