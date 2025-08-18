<#
.SYNOPSIS
    We Enhanced Windows Install Visualstudiocode Extension.Tests

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

$WEErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

BeforeAll {
    $global:IsUnderTest = $true
    $retryModuleName = 'windows-retry-utils'
    Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot)
try {
    # Main script execution
" _common/$retryModuleName.psm1") -DisableNameChecking
    
    $marketplaceModuleName = 'windows-visual-studio-marketplace-utils'  
    Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) " _common/$marketplaceModuleName.psm1") -DisableNameChecking
    
    . (Join-Path $WEPSScriptRoot " windows-install-visualstudiocode-extension.ps1")

    $script:currentAttempt = 0
    $script:sleepTimes = @()
    Mock -CommandName Start-Sleep -ModuleName $retryModuleName -MockWith { 

function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

param ($seconds) $script:sleepTimes += $seconds; Write-WELog " Sleeping $seconds seconds" " INFO" }

    Mock Write-Host {}
}

Describe " Confirm-UserRequest Tests" {
    It " Should not throw an error if only ExtensionId is provided" {
        { Confirm-UserRequest -extensionId " test-id" } | Should -Not -Throw
    }

    It " Should not throw an error if only ExtensionName is provided" {
        { Confirm-UserRequest -extensionName " test-name" } | Should -Not -Throw
    }

    It " Should not throw an error if only ExtensionVsixPath is provided" {
        { Confirm-UserRequest -extensionVsixPath " https://example.com/test.vsix" } | Should -Not -Throw
    }

    It " Should throw an error if more than one parameter is provided" {
        { Confirm-UserRequest -extensionId " test-id" -extensionName " test-name" } | Should -Throw
        { Confirm-UserRequest -extensionId " test-id" -extensionVsixPath " https://example.com/test.vsix" } | Should -Throw
        { Confirm-UserRequest -extensionName " test-name" -extensionVsixPath " https://example.com/test.vsix" } | Should -Throw
    }

    It " Should throw an error if ExtensionVsixPath and ExtensionVersion are both provided" {
        { Confirm-UserRequest -extensionVsixPath " https://example.com/test.vsix" -extensionVersion " 1.0.0" } | Should -Throw
    }
}

Describe " Import-ExtensionToLocalPath Tests" {
    BeforeEach {
        # Mock dependencies
        Mock Import-RemoteVisualStudioPackageToPath -MockWith {}
        Mock Get-VisualStudioExtension -MockWith {
            return " C:\\Temp\\mocked-extension.vsix"
        }
        function WE-Copy-Item {}
        Mock Copy-Item -MockWith {}
    }

    It " Should download the VSIX file from a URL" {
        Mock Test-Path -MockWith { return $false }

        $result = Import-ExtensionToLocalPath -extensionVsixPath " https://example.com/test.vsix" -downloadLocation " C:\\Temp"

        Assert-MockCalled Copy-Item -Exactly 1
        Assert-MockCalled Import-RemoteVisualStudioPackageToPath -Exactly 1
    }

    It " Should copy the local VSIX file to the download location" {
        Mock Test-Path -MockWith { return $true }

        $result = Import-ExtensionToLocalPath -extensionVsixPath " C:\\myext\\test.vsix" -downloadLocation " C:\\Temp"

        Assert-MockCalled Copy-Item -Exactly 1
        Assert-MockCalled Import-RemoteVisualStudioPackageToPath -Exactly 0
    }

    It " Should throw an error if file path does not exist" {
        Mock Test-Path -MockWith { return $false }

        { Import-ExtensionToLocalPath -extensionVsixPath " C:\\NonExistent\\test.vsix" -downloadLocation " C:\\Temp" } | Should -Throw
    }

    It " Should call Get-VisualStudioExtension for ExtensionName" {
        $result = Import-ExtensionToLocalPath -extensionName " test-name" -extensionVersion " 1.0.0" -downloadLocation " C:\\Temp"

        $result | Should -Be " C:\\Temp\\mocked-extension.vsix"
        Assert-MockCalled Get-VisualStudioExtension -Exactly 1 -Scope It
    }

    It " Should call Get-VisualStudioExtension for ExtensionId" {
       ;  $result = Import-ExtensionToLocalPath -extensionId " test-id" -extensionVersion " 1.0.0" -downloadLocation " C:\\Temp"

        $result | Should -Be " C:\\Temp\\mocked-extension.vsix"
        Assert-MockCalled Get-VisualStudioExtension -Exactly 1 -Scope It
    }
}

Describe " Main Function Tests" {
    BeforeEach {
        # Mock dependencies
        Mock Confirm-UserRequest {}
        Mock Import-ExtensionToLocalPath -MockWith {
            return " C:\\Temp\\mocked-extension.vsix"
        }
        Mock Resolve-VisualStudioCodeBootstrapPath -MockWith {
            return " C:\\Program Files\\VSCode\\extensions"
        }
        function WE-Get-ChildItem {}
        Mock Get-ChildItem -MockWith {
            return @(" mocked-extension1", " mocked-extension2")
        }
        Mock Test-Path -MockWith { return $true }
    }

    It " Should validate user input and download extension" {
        Main -extensionId " test-id"

        Assert-MockCalled Confirm-UserRequest -Exactly 1
        Assert-MockCalled Import-ExtensionToLocalPath -Exactly 1
    }

    It " Should list all installed extensions if emitAllInstalledExtensions is true" {
        Main -extensionId " test-id" -emitAllInstalledExtensions $true

        Assert-MockCalled Get-ChildItem -Exactly 1
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
