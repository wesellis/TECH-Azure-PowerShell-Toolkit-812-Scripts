<#
.SYNOPSIS
    Windows Visualstudio Bootstrapper

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
    We Enhanced Windows Visualstudio Bootstrapper

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string] $WEWorkLoads,
    [String] $WESku,
    [String] $WEVSBootstrapperURL,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $WEInstallationDirectory,
    [bool] $WESkipNgenAfterInstall = $false
)

[CmdletBinding()]
function WE-Configure-WorkLoads {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
    param(
        [string] $WEWorkLoads
    )

    switch ($WEWorkLoads) {
        'all' {
            $WEWorkLoads = '--all --includeRecommended --includeOptional'
        }

        'minimal' {
            $WEWorkLoads = '--add Microsoft.VisualStudio.Workload.CoreEditor --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeCrossPlat --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.Office --add Microsoft.VisualStudio.Workload.Universal --add Microsoft.VisualStudio.Workload.VisualStudioExtension --includeRecommended --includeOptional'
        }

        'reduced' {
            $WEWorkLoads = '--add Microsoft.VisualStudio.Workload.CoreEditor --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NativeCrossPlat --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.Office --add Microsoft.VisualStudio.Workload.Universal --add Microsoft.VisualStudio.Workload.VisualStudioExtension --add Microsoft.VisualStudio.Workload.Webcrossplat --includeRecommended --includeOptional'
        }

        'coreeditor' {
            $WEWorkLoads = '--add Microsoft.VisualStudio.Workload.CoreEditor'
        }
        default {
            $WEWorkLoads = $WEWorkLoads
        }
    }
    
    return $WEWorkLoads
}

$WEErrorActionPreference = 'Stop'

[CmdletBinding()]
function WE-Run-WindowedApplication {
    param(
        [Parameter(Position = 0)][String]$command,
        [int[]]$WEAllowableExitStatuses = @(0),
        [int[]]$WERetryableExitStatuses = @(),
        [Parameter(ValueFromRemainingArguments = $true)][String[]]$arguments
    )

    if (!$WEAllowableExitStatuses.Contains(0)) {
        $WEAllowableExitStatuses = $WEAllowableExitStatuses + 0
    }

    $maxRetries = 10
    $retry = 0
    while ($retry -le $maxRetries) {
        $outLog = [System.Guid]::NewGuid().ToString(" N" )
        $errLog = [System.Guid]::NewGuid().ToString(" N" )

        $startArgs = @{
            FilePath               = $command
            PassThru               = $true
            NoNewWindow            = $true
            Wait                   = $true
            RedirectStandardOutput = $outLog
            RedirectStandardError  = $errLog
        }

        if ($arguments) {
            $startArgs[" ArgumentList" ] = $arguments
        }

        $proc = Start-Process @startArgs

        if (Test-Path $outLog) {
            Get-Content -ErrorAction Stop $outLog | Out-Host
            Remove-Item -ErrorAction Stop $outLo -Forceg -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path $errLog) {
            Get-Content -ErrorAction Stop $errLog | Out-Host
            Remove-Item -ErrorAction Stop $errLo -Forceg -Force -ErrorAction SilentlyContinue
        }

        if ($WERetryableExitStatuses.Contains($proc.ExitCode)) {
            Write-WELog " Retry-able exit code spotted: $($proc.ExitCode)" " INFO"
            Start-Sleep -Seconds 10

            $retry = $retry + 1
            Write-WELog " Retry $retry/$maxRetries" " INFO"

            continue
        }

        if (!$WEAllowableExitStatuses.Contains($proc.ExitCode)) {
            $errorlogs = Get-ChildItem -Path $env:TEMP | Where-Object { $_.Name -like " *dd_setup*" -and $_.Name -like " *_errors*" }
            $bootstrapperErrorLogs = Get-ChildItem -Path $env:TEMP | Where-Object { $_.Name -like " *dd_boot*" }

            foreach ($errorlog in $errorlogs) { Get-Content -Path $errorlog.FullName | Write-Output }
            
            foreach ($bootstrapperErrorLog in $bootstrapperErrorLogs) { Get-Content -Path $bootstrapperErrorLog.FullName | Write-Output }
            throw " Commmand exit code: $($proc.ExitCode) - $command $arguments"
        }

        return
    }
}

$randomBootStrapperName = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
    
$vsSetupPath = " $env:Temp\$randomBootStrapperName.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Invoke-WebRequest -Uri $WEVSBootstrapperURL -OutFile $vsSetupPath

Write-WELog " downloading $sku bootstrapper complete" " INFO"

Write-WELog " Configuring workloads" " INFO"
$WEWorkLoads = Configure-WorkLoads -WorkLoads $WEWorkLoads
Write-Information $WEWorkLoads


if ($WEWorkLoads -eq "" ) {
    $WEArguments = ('--quiet', '--norestart', '--wait' )
}
else {
    $WEArguments = ($WEWorkLoads, '--quiet', '--norestart', '--wait' )
}

if (![System.String]::IsNullOrWhiteSpace($WEInstallationDirectory)) {
    Write-WELog " Installing To: $WEInstallationDirectory" " INFO"

    $WEArguments = $WEArguments + " --installPath "" $WEInstallationDirectory"""
}

Run-WindowedApplication -AllowableExitStatuses @(0, 3010) -RetryableExitStatuses 1618 $vsSetupPath $WEArguments

$item = Get-ChildItem -ErrorAction Stop 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\' -ErrorAction SilentlyContinue | Where-Object { $_.Name -like " Visual Studio 20*" -and $_.Attributes -like '*Archive*' }
if ($null -ne $item) {
    Copy-Item $item.FullName -Destination '${env:SystemDrive}\Users\Public\Desktop' -Force -ErrorAction SilentlyContinue
}

if (!$WESkipNgenAfterInstall) {
    # run ngen on the installed assemblies
    $timestamp = Get-Date -Format " yyyyMMddHHmmss"
    @('Framework', 'Framework64') | ForEach-Object {
        try {
            $outFile = Join-Path $env:TEMP " ngen-$timestamp-$_.log"
            $errFile = Join-Path $env:TEMP " ngen-$timestamp-$_.err"

            $command = " C:\Windows\Microsoft.NET\$_\v4.0.30319\ngen.exe"
           ;  $options = $('eqi')
           ;  $cmdLine = " $command $($options -join ' ')"
            
            Write-WELog " Running $cmdLine" " INFO"
            Start-Process -FilePath $command -ArgumentList $options -Wait -NoNewWindow -RedirectStandardOutput $outFile -RedirectStandardError $errFile
            Write-WELog " Running $cmdLine completed" " INFO"

            if (0 -ne $WELASTEXITCODE) {
                Write-WELog " Running $cmdLine completed with exit code $WELASTEXITCODE" " INFO"
            }
        }
        catch {
            # ignore - some errors are expected
            Write-WELog " Running $cmdLine completed with error" " INFO"
        }
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================