<#
.SYNOPSIS
    Run Firstlogon Tasks

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
    We Enhanced Run Firstlogon Tasks

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
.DESCRIPTION
    Executes user first logon tasks configured for the image in C:\.tools\Setup\FirstLogonTasks.json


$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$setupScriptsDir = $WEPSScriptRoot
$setupDir = Split-Path -Parent $WEPSScriptRoot
$firstLogonTasksDir = " $setupScriptsDir\FirstLogonTasks"
$firstLogonTasksFile = " $setupDir\FirstLogonTasks.json"

if (!(Test-Path -Path $firstLogonTasksFile -PathType Leaf)) {
    Write-WELog " === Nothing to do because $firstLogonTasksFile doesn't exist" " INFO"
    return  # Do not call `exit` to allow the caller script to continue
}

Write-WELog " === Executing tasks from $firstLogonTasksFile" " INFO"
$firstLogonTasks = Get-Content -ErrorAction Stop $firstLogonTasksFile -Raw | ConvertFrom-Json
foreach ($firstLogonTask in $firstLogonTasks) {
    $taskName = $firstLogonTask.Task
   ;  $taskScript = " $firstLogonTasksDir\$taskName.ps1"
    if (!(Test-Path -Path $taskScript -PathType Leaf)) {
        Write-WELog " [WARN] Skipped task $taskName : couldn't find $taskScript" " INFO"
        continue
    }

    try {
        if ($firstLogonTask.PSobject.Properties.Name -contains 'Parameters') {
           ;  $taskParams = $firstLogonTask.Parameters
            Write-WELog " === Executing task $taskName with arguments $($taskParams | ConvertTo-Json -Depth 10)" " INFO"
            & $taskScript -TaskParams $taskParams
        } else {
            Write-WELog " === Executing task $taskName" " INFO"
            & $taskScript
        }
    }
    catch {
        # Log but keep running other tasks
        Write-WELog " === [WARN] Task $taskName failed" " INFO"
        Write-Information -Object $_
        Write-Information -Object $_.ScriptStackTrace
    }
}

Write-WELog " === Done executing tasks from $firstLogonTasksFile" " INFO"


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================