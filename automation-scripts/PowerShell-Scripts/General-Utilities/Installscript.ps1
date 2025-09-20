<#
.SYNOPSIS
    Installscript

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    $UserName
)
#region Functions
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux  -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
Set-ExecutionPolicy -ErrorAction Stop Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object -ErrorAction Stop System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
New-LocalGroup -Name docker-users -Description "Users of Docker Desktop"
Add-LocalGroupMember -Group 'docker-users' -Member $UserName
choco install wsl-ubuntu-2204 docker-desktop dbeaver mobaxterm azure-cli choco install -y
$trig = New-ScheduledTaskTrigger -AtLogOn ;
$task = New-ScheduledTaskAction -Execute "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Register-ScheduledTask -TaskName start-docker -Force -Action $task -Trigger $trig -User $UserName
Restart-Computer -Force
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n