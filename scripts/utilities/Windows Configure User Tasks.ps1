#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Configure User Tasks

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Configures a set of tasks that will run when a user logs into a VM.
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string] $FirstLogonTasksBase64
)
Set-StrictMode -Version Latest
function GetTaskID {
function Write-Log {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSObject] $TaskObj
    )
    $TaskId = $TaskObj.Task
    if ($TaskObj.PSobject.Properties.Name -contains 'UniqueID') {
    $TaskId = $TaskObj.UniqueID
    }
    return $TaskId
}
try {
    $SetupDir = " c:\.tools\Setup"
    $SetupScriptsDir = " $SetupDir\Scripts"
    $LogsDir = " $SetupDir\Logs"
    if (Test-Path -Path $SetupScriptsDir) {
        Write-Output " === To avoid scripts versioning issues remove $SetupScriptsDir in case it was created by the base image build"
        Remove-Item -ErrorAction Stop $SetupScriptsDi -Forcer -Force -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Output " === Create $SetupScriptsDir before copying scripts there"
    mkdir $SetupScriptsDir -Force
    mkdir $LogsDir -Force
    Write-Output " === Copy setup scripts to $SetupScriptsDir"
    @(
    (Join-Path $PSScriptRoot 'customization-utils.psm1')
    (Join-Path $PSScriptRoot 'setup-user-tasks.ps1')
    (Join-Path $PSScriptRoot 'run-firstlogon-tasks.ps1')
    (Join-Path $PSScriptRoot 'runonce-user-tasks.ps1')
    (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-retry-utils.psm1')
    (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-run-program.psm1')
    ) | ForEach-Object { Copy-Item $_ $SetupScriptsDir -Force }
    Copy-Item " $PSScriptRoot\FirstLogonTasks" " $SetupScriptsDir\FirstLogonTasks" -Recurse -Force -Exclude '*.Tests.ps1'
    Get-ChildItem -Recurse -File -Path $SetupScriptsDir | Select-Object -First 100
    Write-Output " === Configure Azure VM first startup event"
    $VmStartupScriptsDir = 'C:\Windows\OEM'
    $VmStartupScript = " $VmStartupScriptsDir\SetupComplete2.cmd"
    $VmOrigStartupScript = " $VmStartupScriptsDir\SetupComplete2FromOrigBaseImage.cmd"
    if ((!(Test-Path -Path $VmOrigStartupScript)) -and (Test-Path -Path $VmStartupScript) ) {
        Write-Output " === Save SetupComplete2.cmd from the original base image to $VmOrigStartupScript"
        Move-Item $VmStartupScript $VmOrigStartupScript
    }
    mkdir $VmStartupScriptsDir -ErrorAction SilentlyContinue
    Copy-Item (Join-Path $PSScriptRoot 'SetupComplete2.cmd') $VmStartupScriptsDir -Force
    $FirstLogonTasksFile = " $SetupDir\FirstLogonTasks.json"
    if (!([string]::IsNullOrWhiteSpace($FirstLogonTasksBase64))) {
    $FirstLogonTasks = [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($FirstLogonTasksBase64)) | ConvertFrom-Json
    $BaseImageLogonTasks = @()
        if (Test-Path -Path $FirstLogonTasksFile -PathType Leaf) {
            Write-Output " === Found following logon tasks configured for the base image in $FirstLogonTasksFile"
            Get-Content -ErrorAction Stop $FirstLogonTasksFile
    $BaseImageLogonTasks = Get-Content -ErrorAction Stop $FirstLogonTasksFile -Raw | ConvertFrom-Json
        }
    $UniqueBaseImageLogonTasks = @()
        foreach ($BaseImageLogonTask in $BaseImageLogonTasks) {
    $BaseImageTaskID = GetTaskID $BaseImageLogonTask
            if ($null -eq ($FirstLogonTasks | Where-Object { (GetTaskID $_) -eq $BaseImageTaskID })) {
    $UniqueBaseImageLogonTasks = $UniqueBaseImageLogonTasks + $BaseImageLogonTask
            }
            else {
                Write-Output " == Skipped base image task $($BaseImageLogonTask | ConvertTo-Json -Depth 10)"
            }
        }
    $FirstLogonTasks = $UniqueBaseImageLogonTasks + $FirstLogonTasks
    $FirstLogonTasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $FirstLogonTasksFile
        Write-Output " === Saved following tasks to run on user first logon to $FirstLogonTasksFile"
        Get-Content -ErrorAction Stop $FirstLogonTasksFile

} catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
