#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Install Winget

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Installs the latest WinGet and related PowerShell modules
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
[CmdletBinding()]
[OutputType([PSObject])]
 -ErrorAction Stop {
    $WinGetCmd = Get-Command -ErrorAction Stop 'winget.exe' -ErrorAction SilentlyContinue
    if ($WinGetCmd) {
        $WinGetExe = $WinGetCmd.Path
    }
    else {
        $WinGetExe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    }
    return $WinGetExe
}
try {
    $pwsh7Cmd = Get-Command -ErrorAction Stop 'pwsh.exe' -ErrorAction SilentlyContinue
    if ($pwsh7Cmd) {
        $pwsh7Exe = $pwsh7Cmd.Path
    }
    else {
        $pwsh7Exe = " $($env:ProgramFiles)\PowerShell\7\pwsh.exe"
    }
    if (!(Test-Path $pwsh7Exe)) {
        Write-Output " === Install PowerShell 7"
        RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -runBlock { Invoke-Expression " & { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet" }
    }
    Write-Output " === Registering PSGallery repository"
    Install-PackageProvider -Name NuGet -Force
    Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
    Write-Output " === Installing WinGet modules for PowerShell 7"
    RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -ignoreFailure $true -runBlock {
        & $pwsh7Exe -ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -Command 'Install-Module Microsoft.WinGet.Client -Scope AllUsers -Force' }
    RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -ignoreFailure $true -runBlock {
        & $pwsh7Exe -ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -Command 'Install-Module Microsoft.WinGet.Configuration -AllowPrerelease -Scope AllUsers -Force' }
    Write-Output " === Install Microsoft.Winget.Source"
    RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -ignoreFailure $true -runBlock {
        Add-AppxPackage 'https://cdn.winget.microsoft.com/cache/source2.msix'
    }
    Write-Output " === Running Repair-WinGetPackageManager"
    RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -ignoreFailure $true -onFailureBlock { & cmd.exe /c " echo Reset last exit code" } -runBlock {
        $pwsh7Output = & cmd.exe /c " ("" $pwsh7Exe"" -ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -Command Repair-WinGetPackageManager -Latest -Force -Verbose) 2>&1"
        if ($LASTEXITCODE -ne 0) {
            throw "Repair-WinGetPackageManager failed with exit code $LASTEXITCODE`:`n$pwsh7Output"
        }
        Write-Output " === Repair-WinGetPackageManager succeeded`:`n$pwsh7Output"
    }
    $WinGetExe = Get-WinGetExePath -ErrorAction Stop
    if (Test-Path $WinGetExe) {
        Write-Output " === Found $WinGetExe"
        & $WinGetExe '--info'
    }
    else {
        Write-Output " !!! [WARN] winget.exe is not found"
    }
$SettingsJson = @{
        installBehavior = @{
            archiveExtractionMethod = 'tar'
        }
    }
$SettingsJsonPath = " $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
    $SettingsJson | ConvertTo-Json | Out-File -FilePath $SettingsJsonPath -Encoding ascii -Force
    Write-Output "Content of $SettingsJsonPath :`n$(Get-Content -ErrorAction Stop $SettingsJsonPath -Raw | Out-String)"
}
catch {
    Write-Output " !!! [WARN] Unhandled exception:`n$_`n$($_.ScriptStackTrace)"`n}
