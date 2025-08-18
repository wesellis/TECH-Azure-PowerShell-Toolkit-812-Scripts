<#
.SYNOPSIS
    Windows Install Winget

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
    We Enhanced Windows Install Winget

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
    Installs the latest WinGet and related PowerShell modules


$WEErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$WEProgressPreference = 'SilentlyContinue'

[CmdletBinding()]
function WE-Get-WinGetExePath -ErrorAction Stop {
    $winGetCmd = Get-Command -ErrorAction Stop 'winget.exe' -ErrorAction SilentlyContinue
    if ($winGetCmd) {
        $winGetExe = $winGetCmd.Path
    }
    else {
        $winGetExe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    }

    return $winGetExe
}

try {
    Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-retry-utils.psm1')

    # PowerShell 7 is required for Microsoft.WinGet.* modules
    $pwsh7Cmd = Get-Command -ErrorAction Stop 'pwsh.exe' -ErrorAction SilentlyContinue
    if ($pwsh7Cmd) {
        $pwsh7Exe = $pwsh7Cmd.Path
    }
    else {
        $pwsh7Exe = " $($env:ProgramFiles)\PowerShell\7\pwsh.exe"
    }

    if (!(Test-Path $pwsh7Exe)) {
        Write-WELog " === Install PowerShell 7" " INFO"
        RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -runBlock { Invoke-Expression " & { $(Invoke-RestMethod https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet" }
    }

    # Install NuGet provider to avoid a confirmation prompt if the provider is not installed yet
    Write-WELog " === Registering PSGallery repository" " INFO"
    Install-PackageProvider -Name NuGet -Force
    Set-PSRepository -Name " PSGallery" -InstallationPolicy Trusted

    Write-WELog " === Installing WinGet modules for PowerShell 7" " INFO"
    RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -ignoreFailure $true -runBlock {
        & $pwsh7Exe -ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -Command 'Install-Module Microsoft.WinGet.Client -Scope AllUsers -Force' }
    RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -ignoreFailure $true -runBlock { 
        & $pwsh7Exe -ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -Command 'Install-Module Microsoft.WinGet.Configuration -AllowPrerelease -Scope AllUsers -Force' }

    # Work around https://github.com/microsoft/winget-cli/issues/3862
    #   An unexpected error occurred while executing the command: 
    #   0x8a15000f : Data required by the source is missing
    # When this workaround is no longer needed, clean up or remove windows-prepare-for-sysprep.ps1 as well
    Write-WELog " === Install Microsoft.Winget.Source" " INFO"
    RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -ignoreFailure $true -runBlock {
        Add-AppxPackage 'https://cdn.winget.microsoft.com/cache/source2.msix'
    }

    # Ensure winget.exe is available for the current user to be used during the image creation process
    Write-WELog " === Running Repair-WinGetPackageManager" " INFO"
    RunWithRetries -waitBeforeRetrySeconds 5 -retryAttempts 1 -ignoreFailure $true -onFailureBlock { & cmd.exe /c " echo Reset last exit code" } -runBlock {
        $pwsh7Output = & cmd.exe /c " ("" $pwsh7Exe"" -ExecutionPolicy Bypass -NoProfile -NoLogo -NonInteractive -Command Repair-WinGetPackageManager -Latest -Force -Verbose) 2>&1"
        if ($WELASTEXITCODE -ne 0) {
            throw " Repair-WinGetPackageManager failed with exit code $WELASTEXITCODE`:`n$pwsh7Output"
        }

        Write-WELog " === Repair-WinGetPackageManager succeeded`:`n$pwsh7Output" " INFO"
    }

    $winGetExe = Get-WinGetExePath -ErrorAction Stop
    if (Test-Path $winGetExe) {
        Write-WELog " === Found $winGetExe" " INFO"
        & $winGetExe '--info'
    }
    else {
        Write-WELog " !!! [WARN] winget.exe is not found" " INFO"
    }

    # Set https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md#archive-extraction-method to work around https://github.com/microsoft/winget-cli/issues/4153
    # This setting is only needed during image creation since there is no an active user session during that process.
    # The file will be lost when the final image is captured because the file is located under LOCALAPPDATA of the local user used for image building.
   ;  $settingsJson = @{
        installBehavior = @{
            archiveExtractionMethod = 'tar'
        }
    }

   ;  $settingsJsonPath = " $env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
    $settingsJson | ConvertTo-Json | Out-File -FilePath $settingsJsonPath -Encoding ascii -Force
    Write-WELog " Content of $settingsJsonPath :`n$(Get-Content -ErrorAction Stop $settingsJsonPath -Raw | Out-String)" " INFO"
}
catch {
    # Do not block image creation if WinGet pre-installation fails. 'configure-winget' logon task will attempt to repait WinGet it needed.
    Write-WELog " !!! [WARN] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" " INFO"
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================