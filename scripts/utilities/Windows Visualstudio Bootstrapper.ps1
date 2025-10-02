#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Visualstudio Bootstrapper

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] $WorkLoads,
    [String] $Sku,
    [String] $VSBootstrapperURL,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $InstallationDirectory,
    [bool] $SkipNgenAfterInstall = $false
)
function Write-Log {
    param(
        [string] $WorkLoads
    )
    switch ($WorkLoads) {
        'all' {
    $WorkLoads = '--all --includeRecommended --includeOptional'
        }
        'minimal' {
    $WorkLoads = '--add Microsoft.VisualStudio.Workload.CoreEditor --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeCrossPlat --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.Office --add Microsoft.VisualStudio.Workload.Universal --add Microsoft.VisualStudio.Workload.VisualStudioExtension --includeRecommended --includeOptional'
        }
        'reduced' {
    $WorkLoads = '--add Microsoft.VisualStudio.Workload.CoreEditor --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeCrossPlat --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.Office --add Microsoft.VisualStudio.Workload.Universal --add Microsoft.VisualStudio.Workload.VisualStudioExtension --add Microsoft.VisualStudio.Workload.Webcrossplat --includeRecommended --includeOptional'
        }
        'coreeditor' {
    $WorkLoads = '--add Microsoft.VisualStudio.Workload.CoreEditor'
        }
        default {
    $WorkLoads = $WorkLoads
        }
    }
    return $WorkLoads
}
function Run-WindowedApplication {
    param(
        [Parameter(Position = 0)][String]$command,
        [int[]]$AllowableExitStatuses = @(0),
        [int[]]$RetryableExitStatuses = @(),
        [Parameter(ValueFromRemainingArguments = $true)][String[]]$arguments
    )
    if (!$AllowableExitStatuses.Contains(0)) {
    $AllowableExitStatuses = $AllowableExitStatuses + 0
    }
    $MaxRetries = 10
    $retry = 0
    while ($retry -le $MaxRetries) {
    $OutLog = [System.Guid]::NewGuid().ToString("N" )
    $ErrLog = [System.Guid]::NewGuid().ToString("N" )
    $StartArgs = @{
            FilePath               = $command
            PassThru               = $true
            NoNewWindow            = $true
            Wait                   = $true
            RedirectStandardOutput = $OutLog
            RedirectStandardError  = $ErrLog
        }
        if ($arguments) {
    $StartArgs["ArgumentList" ] = $arguments
        }
    $proc = Start-Process @startArgs
        if (Test-Path $OutLog) {
            Get-Content -ErrorAction Stop $OutLog | Out-Host
            Remove-Item -ErrorAction Stop $OutLo -Forceg -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path $ErrLog) {
            Get-Content -ErrorAction Stop $ErrLog | Out-Host
            Remove-Item -ErrorAction Stop $ErrLo -Forceg -Force -ErrorAction SilentlyContinue
        }
        if ($RetryableExitStatuses.Contains($proc.ExitCode)) {
            Write-Output "Retry-able exit code spotted: $($proc.ExitCode)"
            Start-Sleep -Seconds 10
    $retry = $retry + 1
            Write-Output "Retry $retry/$MaxRetries"
            continue
        }
        if (!$AllowableExitStatuses.Contains($proc.ExitCode)) {
    $errorlogs = Get-ChildItem -Path $env:TEMP | Where-Object { $_.Name -like " *dd_setup*" -and $_.Name -like " *_errors*" }
    $BootstrapperErrorLogs = Get-ChildItem -Path $env:TEMP | Where-Object { $_.Name -like " *dd_boot*" }
            foreach ($errorlog in $errorlogs) { Get-Content -Path $errorlog.FullName | Write-Output }
            foreach ($BootstrapperErrorLog in $BootstrapperErrorLogs) { Get-Content -Path $BootstrapperErrorLog.FullName | Write-Output }
            throw "Commmand exit code: $($proc.ExitCode) - $command $arguments"
        }
        return
    }
}
    $RandomBootStrapperName = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
    $VsSetupPath = " $env:Temp\$RandomBootStrapperName.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $VSBootstrapperURL -OutFile $VsSetupPath
Write-Output " downloading $sku bootstrapper complete"
Write-Output "Configuring workloads"
    $WorkLoads = Configure-WorkLoads -WorkLoads $WorkLoads
Write-Output $WorkLoads
if ($WorkLoads -eq "" ) {
    $Arguments = ('--quiet', '--norestart', '--wait' )
}
else {
    $Arguments = ($WorkLoads, '--quiet', '--norestart', '--wait' )
}
if (![System.String]::IsNullOrWhiteSpace($InstallationDirectory)) {
    Write-Output "Installing To: $InstallationDirectory"
    $Arguments = $Arguments + " --installPath "" $InstallationDirectory"""
}
Run-WindowedApplication -AllowableExitStatuses @(0, 3010) -RetryableExitStatuses 1618 $VsSetupPath $Arguments
    $item = Get-ChildItem -ErrorAction Stop 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\' -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "Visual Studio 20*" -and $_.Attributes -like '*Archive*' }
if ($null -ne $item) {
    Copy-Item $item.FullName -Destination '${env:SystemDrive}\Users\Public\Desktop' -Force -ErrorAction SilentlyContinue
}
if (!$SkipNgenAfterInstall) {
    $timestamp = Get-Date -Format " yyyyMMddHHmmss"
    @('Framework', 'Framework64') | ForEach-Object {
        try {
    $OutFile = Join-Path $env:TEMP " ngen-$timestamp-$_.log"
    $ErrFile = Join-Path $env:TEMP " ngen-$timestamp-$_.err"
    $command = "C:\Windows\Microsoft.NET\$_\v4.0.30319
gen.exe"
    $options = $('eqi')
    $CmdLine = " $command $($options -join ' ')"
            Write-Output "Running $CmdLine"
            Start-Process -FilePath $command -ArgumentList $options -Wait -NoNewWindow -RedirectStandardOutput $OutFile -RedirectStandardError $ErrFile
            Write-Output "Running $CmdLine completed"
            if (0 -ne $LASTEXITCODE) {
                Write-Output "Running $CmdLine completed with exit code $LASTEXITCODE"

} catch {
            Write-Output "Running $CmdLine completed with error"
        }
    }
`n}
