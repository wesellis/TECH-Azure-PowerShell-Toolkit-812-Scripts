#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Install Winget Packages.Tests
.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
BeforeAll {
    $script:IsUnderTest = $true
    try {
'_common/windows-retry-utils.psm1')
    . (Join-Path $PSScriptRoot 'windows-install-winget-packages.ps1') -Packages 'UNUSED'
}
Describe "CreateDevVhdTests" {
    BeforeEach {
    $script:LASTEXITCODE = 0
    $script:sleepTimes = @()
        Mock -CommandName Start-Sleep -ModuleName windows-retry-utils -MockWith {
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
param($seconds) $script:sleepTimes += $seconds; Write-Output "Sleeping $seconds seconds" }
        Mock Invoke-Executable {
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
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CommandLine
            )
            throw "Must be mocked by the test! Invoking $CommandLine."
        }
        Mock Invoke-Executable {
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
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CommandLine
            )
            Write-Output " === [Mock] Invoking $CommandLine"
        } -ParameterFilter { $CommandLine -like '*winget.exe --info' }
        Mock Invoke-Executable {
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
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CommandLine
            )
            Write-Output " === [Mock] Invoking $CommandLine"
    $script:LASTEXITCODE = 123
        } -ParameterFilter { $CommandLine -like '*robocopy.exe /R:5 /W:5 /S *AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\DiagOutputDir C:\.tools\Setup\Logs\WinGet' }
        Mock Invoke-Executable {
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
;
[CmdletBinding()]
param(
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CommandLine
            )
            Write-Output " === [Mock] Invoking $CommandLine"
    $script:LASTEXITCODE = 123
        } -ParameterFilter { $CommandLine -like 'C:\Windows\System32\icacls.exe "C:\Program Files\WinGet\Packages"/t /q /grant "BUILTIN\Users:(rx)" ' }
    }
    It "InstallSuccess_<TestName>" -ForEach @(
        @{
            TestName     = 'SinglePackageNoVersion';
            TestPackages = 'TestPkg_975'
            ExpectedArgs = @('TestPkg_975 ')
        }
        @{
            TestName     = 'SinglePackageWithVersion';
            TestPackages = 'TestPkg_975@2.0.1'
            ExpectedArgs = @('TestPkg_975 --version 2.0.1')
        }
        @{
            TestName     = 'MultiplePackageNoVersion';
            TestPackages = 'TestPkg_975 , Test1Pkg2, ,   ,_Test_Pkg-_'
            ExpectedArgs = @('TestPkg_975 ', 'Test1Pkg2 ', '_Test_Pkg-_ ')
        }
        @{
            TestName     = 'MultiplePackageWithVersion';
            TestPackages = 'TestPkg_975@4.5.6 , Test1Pkg2, ,   ,_Test_Pkg-_@1.2.3   '
            ExpectedArgs = @('TestPkg_975 --version 4.5.6', 'Test1Pkg2 ', '_Test_Pkg-_ --version 1.2.3')
        }
    ) {
        Mock Invoke-Executable {
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
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CommandLine
            )
            foreach ($ExpectedArg in $ExpectedArgs) {
                if ($CommandLine -like " *winget.exe install --id $ExpectedArg --exact --disable-interactivity --silent --no-upgrade --accept-package-agreements --accept-source-agreements --verbose-logs --scope machine --force" ) {
                    Write-Output " === [Mock] Invoking $CommandLine"
                    return
                }
            }
            throw "Unexpected command: $CommandLine"
        }
        Install-WinGet-Packages -Packages $TestPackages
        Should -Invoke Invoke-Executable -Times (3 + $ExpectedArgs.Count) -Exactly
    $script:sleepTimes | Should -Be @()
    $global:LASTEXITCODE | Should -Be 0
    }
    It "InvalidPackageFormat" {
        {
            Install-WinGet-Packages -Packages 'TestPkg_975@2.0.1@3.0.1'
        } | Should -Throw 'Unexpected format for package TestPkg_975@2.0.1@3.0.1. Expected format is *'
    $script:sleepTimes | Should -Be @()
    }
    It "MissingWinGet" {
        function Get-Command -ErrorAction Stop { return $null }
        { Install-WinGet-Packages -Packages 'TestPkg_975' } | Should -Throw 'Could not locate winget.exe'
    $script:sleepTimes | Should -Be @()
    }
    It "ThrowOnInstallFailure" {
        Mock Invoke-Executable {
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
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CommandLine
            )
            if ($CommandLine -like " *winget.exe install --id TestPkg_1  --exact --disable-interactivity --silent --no-upgrade --accept-package-agreements --accept-source-agreements --verbose-logs --scope machine --force" ) {
                Write-Output " === [Mock] Invoking $CommandLine"
                return
            }
            if ($CommandLine -like '*winget.exe install --id TestPkg_2  --exact --disable-interactivity --silent --no-upgrade --accept-package-agreements --accept-source-agreements --verbose-logs --scope machine --force') {
    $script:LASTEXITCODE = 1
                Write-Output " === [Mock] Failed command: $CommandLine"
                return
            }
            throw "Unexpected command: $CommandLine"
        }
        { Install-WinGet-Packages -Packages 'TestPkg_1, TestPkg_2 , TestPkg_3' }  | Should -Throw "Failed to install TestPkg_2 with exit code 1. WinGet return codes are listed at https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md"
    $script:sleepTimes | Should -Be @(1, 1, 1, 1, 1)
        Should -Invoke Invoke-Executable -Times 8 -Exactly
    }
    It "IgnoreInstallFailure" {
        Mock Invoke-Executable {
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
;
[CmdletBinding()]
param(
                [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string] $CommandLine
            )
            foreach ($ExpectedArg in @('TestPkg_2 ', 'TestPkg_3 ')) {
                if ($CommandLine -like " *winget.exe install --id $ExpectedArg --exact --disable-interactivity --silent --no-upgrade --accept-package-agreements --accept-source-agreements --verbose-logs --scope machine --force" ) {
                    Write-Output " === [Mock] Invoking $CommandLine"
                    return
                }
            }
            if ($CommandLine -like '*winget.exe install --id TestPkg_2  --exact --disable-interactivity --silent --no-upgrade --accept-package-agreements --accept-source-agreements --verbose-logs --scope machine --force') {
    $script:LASTEXITCODE = 1
                Write-Output " === [Mock] Failed command: $CommandLine"
                return
            }
            throw "Unexpected command: $CommandLine"
        }
        Install-WinGet-Packages -Packages 'TestPkg_1, TestPkg_2 , TestPkg_3' -IgnorePackageInstallFailures $true
    $script:sleepTimes | Should -Be @(1, 1, 1, 1, 1)
    $global:LASTEXITCODE | Should -Be 0
        Should -Invoke Invoke-Executable -Times 11 -Exactly
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
