#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Windows Configure User Tasks

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Windows Configure User Tasks

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.DESCRIPTION
    Configures a set of tasks that will run when a user logs into a VM.


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)][string] $WEFirstLogonTasksBase64
)

#region Functions

$WEErrorActionPreference = " Stop"
Set-StrictMode -Version Latest

function WE-GetTaskID {
    

[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSObject] $taskObj
    )

    # By default use task's name as its ID which means that only a single (last) instance of such task will be executed on when user logs on
    $taskId = $taskObj.Task

    if ($taskObj.PSobject.Properties.Name -contains 'UniqueID') {
        $taskId = $taskObj.UniqueID
    }

    return $taskId
}

try {
    $setupDir = " c:\.tools\Setup"
    $setupScriptsDir = " $setupDir\Scripts"
    $logsDir = " $setupDir\Logs"

    if (Test-Path -Path $setupScriptsDir) {
        Write-WELog " === To avoid scripts versioning issues remove $setupScriptsDir in case it was created by the base image build" " INFO"
        Remove-Item -ErrorAction Stop $setupScriptsDi -Forcer -Force -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-WELog " === Create $setupScriptsDir before copying scripts there" " INFO"
    mkdir $setupScriptsDir -Force
    mkdir $logsDir -Force

    Write-WELog " === Copy setup scripts to $setupScriptsDir" " INFO"
    @(
    (Join-Path $WEPSScriptRoot 'customization-utils.psm1')
    (Join-Path $WEPSScriptRoot 'setup-user-tasks.ps1')
    (Join-Path $WEPSScriptRoot 'run-firstlogon-tasks.ps1')
    (Join-Path $WEPSScriptRoot 'runonce-user-tasks.ps1')
    (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-retry-utils.psm1')
    (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-run-program.psm1')
    ) | ForEach-Object { Copy-Item $_ $setupScriptsDir -Force }
    Copy-Item " $WEPSScriptRoot\FirstLogonTasks" " $setupScriptsDir\FirstLogonTasks" -Recurse -Force -Exclude '*.Tests.ps1'
    Get-ChildItem -Recurse -File -Path $setupScriptsDir | Select-Object -First 100

    # Hook the event invoked when Azure VM starts for the first time
    # - https://matt.kotsenas.com/posts/azure-setupcomplete2
    # - https://learn.microsoft.com/en-us/dynamics-nav/setupcomplete2.cmd-file-example
    # - https://learn.microsoft.com/en-us/previous-versions/dynamicsnav-2018-developer/How-to--Create-a-Microsoft-Azure-Virtual-Machine-Operating-System-Image-for-Microsoft-Dynamics-NAV
    Write-WELog " === Configure Azure VM first startup event" " INFO"
    $vmStartupScriptsDir = 'C:\Windows\OEM'
    $vmStartupScript = " $vmStartupScriptsDir\SetupComplete2.cmd"
    $vmOrigStartupScript = " $vmStartupScriptsDir\SetupComplete2FromOrigBaseImage.cmd"

    # If the base image for this VM was not created by Dev Box image templates then preserve the original SetupComplete2.cmd
    if ((!(Test-Path -Path $vmOrigStartupScript)) -and (Test-Path -Path $vmStartupScript) ) {
        Write-WELog " === Save SetupComplete2.cmd from the original base image to $vmOrigStartupScript" " INFO"
        Move-Item $vmStartupScript $vmOrigStartupScript
    }

    mkdir $vmStartupScriptsDir -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $WEPSScriptRoot 'SetupComplete2.cmd') $vmStartupScriptsDir -Force

    $firstLogonTasksFile = " $setupDir\FirstLogonTasks.json"
    if (!([string]::IsNullOrWhiteSpace($WEFirstLogonTasksBase64))) {
        $firstLogonTasks = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($WEFirstLogonTasksBase64)) | ConvertFrom-Json

        $baseImageLogonTasks = @()
        if (Test-Path -Path $firstLogonTasksFile -PathType Leaf) {
            Write-WELog " === Found following logon tasks configured for the base image in $firstLogonTasksFile" " INFO"
            Get-Content -ErrorAction Stop $firstLogonTasksFile
            $baseImageLogonTasks = Get-Content -ErrorAction Stop $firstLogonTasksFile -Raw | ConvertFrom-Json
        }

        # Only keep unique tasks that were configured for the base image
        $uniqueBaseImageLogonTasks = @()
        foreach ($baseImageLogonTask in $baseImageLogonTasks) {
            $baseImageTaskID = GetTaskID $baseImageLogonTask
            if ($null -eq ($firstLogonTasks | Where-Object { (GetTaskID $_) -eq $baseImageTaskID })) {
               ;  $uniqueBaseImageLogonTasks = $uniqueBaseImageLogonTasks + $baseImageLogonTask
            }
            else {
                Write-WELog " == Skipped base image task $($baseImageLogonTask | ConvertTo-Json -Depth 10)" " INFO"
            }
        }

       ;  $firstLogonTasks = $uniqueBaseImageLogonTasks + $firstLogonTasks
        # Always use -Depth with ConvertTo-Json to preserve object structure (otherwise arrays fo example are turned into space separated strings)
        $firstLogonTasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $firstLogonTasksFile
        Write-WELog " === Saved following tasks to run on user first logon to $firstLogonTasksFile" " INFO"
        Get-Content -ErrorAction Stop $firstLogonTasksFile
    }
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
