#Requires -Version 7.4

<#`n.SYNOPSIS
    Run a process

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
  Run a process and validate that the process started and completed without any errors
  .PARAMETER command
  The command that will be run
  .PARAMETER arguments
  The arguments required to run the supplied command
$ErrorActionPreference = 'Stop'

$ErrLog = [System.IO.Path]::GetTempFileName()
$process = Start-Process -FilePath $command -ArgumentList $arguments -RedirectStandardError $ErrLog -PassThru -Wait
    if (!$process) {
        Write-Error "ERROR command failed to start: $command $arguments"
        return;
    }
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        Write-Output "Error running: $command $arguments"
        Write-Output "Exit code: $($process.ExitCode)"
        Write-Output " **ERROR**"
        Get-Content -Path $ErrLog
        throw "Exit code from process was nonzero"
    }
}
$Arch = $null
$dotnet_sdk_version = $null
$InstallDir = $null
try {
    if ($false -eq [System.String]::IsNullOrWhiteSpace($architecture)) {
        $Arch = $architecture
    }
    else {
        $Arch = " <auto>"
    }
    if ($false -eq [System.String]::IsNullOrWhiteSpace($InstallLocation)) {
        $InstallDir = $InstallLocation
    }
    else {
        $InstallDir = " c:\program files\dotnet"
    }
    if ($false -eq [System.String]::IsNullOrWhiteSpace($DotnetSdkVersion)) {
        $dotnet_sdk_version = $DotnetSdkVersion
    }
    elseif ($false -eq [System.String]::IsNullOrWhiteSpace($GlobalJsonPath)) {
        Write-Output "Attempting to read global.json"
        $GlobalJsonFullPath = ""
        if ($GlobalJsonPath.EndsWith(" global.json" )) {
            $GlobalJsonFullPath = $GlobalJsonPath
        }
        else {
            $GlobalJsonFullPath = [System.IO.Path]::Combine($GlobalJsonPath, "global.json" )
        }
        if ($true -eq [System.IO.File]::Exists($GlobalJsonFullPath)) {
            Write-Output "Reading from global.json"
            Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-json-utils.psm1')
            $dotnet_sdk_version = (Get-JsonFromFile -ErrorAction Stop $GlobalJsonFullPath).sdk.version
            Write-Output "Found version $dotnet_sdk_version"
        }
        else {
            Write-Output " global.json not found, setting version to latest"
            $dotnet_sdk_version = "Latest"
        }
    }
    Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-retry-utils.psm1')
    Write-Information Downloading dotnet-install script
$ScriptLocation = [System.IO.Path]::Combine($env:TEMP, 'dotnet-install.ps1')
    ProcessRunner -command curl -arguments " -SsL https://dot.net/v1/dotnet-install.ps1 -o $ScriptLocation"
    RunWithRetries -retryAttempts 10 -waitBeforeRetrySeconds 2 -exponentialBackoff -runBlock {
        & " $ScriptLocation" -Version $dotnet_sdk_version -InstallDir $InstallDir -Architecture $Arch -Runtime $runtime
    }
    & ([System.IO.Path]::Combine($InstallDir, "dotnet.exe" )) --list-sdks
    & ([System.IO.Path]::Combine($InstallDir, "dotnet.exe" )) --list-runtimes
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
