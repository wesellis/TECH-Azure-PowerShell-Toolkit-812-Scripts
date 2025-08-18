<#
.SYNOPSIS
    We Enhanced Windows Visual Studio Marketplace Utils.Tests

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
    Import-Module -Force -Name (Join-Path $(Split-Path -Parent $WEPSScriptRoot)
try {
    # Main script execution
" _common/$retryModuleName.psm1")
    
    $marketplaceModuleName = 'windows-visual-studio-marketplace-utils'  
    Import-Module -Force -Name (Join-Path $(Split-Path -Parent $WEPSScriptRoot) " _common/$marketplaceModuleName.psm1")
    
    # Mock a x64 processor by default
    function WE-Get-CimInstance { }
    Mock Get-CimInstance {
        [pscustomobject]@{ Architecture = 9 }
    } -Verifiable -ModuleName $marketplaceModuleName

    $script:currentAttempt = 0
    $script:sleepTimes = @()
    Mock -CommandName Start-Sleep -ModuleName $retryModuleName `
        -MockWith { 

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

param ($seconds) $script:sleepTimes += $seconds; }

    Mock Write-Host {} -ModuleName $marketplaceModuleName
    Mock Write-Host {} -ModuleName $retryModuleName
}

Describe " Get-ApiHeaders Tests" {
    It " Should return the correct headers" {
        $headers = Get-ApiHeaders

        $headers | Should -Not -BeNullOrEmpty
        $headers[" Accept"] | Should -Be " application/json;api-version=3.0-preview.1"
        $headers[" Content-Type"] | Should -Be " application/json"
    }
}

Describe " Get-ApiFlags Tests" {
    It " Should be 402" {
        $flags = Get-ApiFlags -VersionNumber $null

        ($flags -band 402) | Should -Be 402
    }
}

Describe " Get-RequestBody Tests" {
    It " Should create a valid request body" {
        $body = Get-RequestBody -ExtensionReference " test.extension" -Flags 402
        $jsonBody = $body | ConvertFrom-Json

        $jsonBody.filters[0].criteria[0].filterType | Should -Be 7
        $jsonBody.filters[0].criteria[0].value | Should -Be " test.extension"
        $jsonBody.flags | Should -Be 402
    }
}

Describe " Import-ExtensionByMetadata Tests" {
    Context " When the destination file does not exist" {
        BeforeEach {
            Mock Test-Path {
                [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($WEPath)
                return $false
            } -Verifiable -ModuleName $marketplaceModuleName

            Mock Copy-Item {
                [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($WEPath, $WEDestination)
                Write-WELog " Mocked: Copying $WEPath to $WEDestination" " INFO"
            } -Verifiable -ModuleName $marketplaceModuleName

            Mock Import-RemoteVisualStudioPackageToPath {
                [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($WEVsixUrl, $WELocalFilePath)
                Write-WELog " Mocked: Downloading $WEVsixUrl to $WELocalFilePath" " INFO"
            } -Verifiable -ModuleName $marketplaceModuleName
        }

        It " Should download and copy the file to the destination" {
            $WEExtensionMetadata = [PSCustomObject]@{
                name    = " SampleExtension"
                vsixUrl = " http://localhost/sampleextension.VSIXPackage"
            }
            $WEDownloadLocation = " c:\temp\"
            $WEExpectedFilePath = Join-Path -Path $WEDownloadLocation -ChildPath " SampleExtension.vsix"
            $WEResult = Import-ExtensionByMetadata -ExtensionMetadata $WEExtensionMetadata -DownloadLocation $WEDownloadLocation

            # Assertions
            Assert-MockCalled Import-RemoteVisualStudioPackageToPath -Exactly 1 -Scope It -ModuleName $marketplaceModuleName
            Assert-MockCalled Copy-Item -Exactly 1 -Scope It -ModuleName $marketplaceModuleName
            $WEResult | Should -Be $WEExpectedFilePath
        }
    }

    Context " When the destination file already exists" {
        BeforeEach {
            Mock Test-Path {
                [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($WEPath)
                $true
            } -Verifiable -ModuleName $marketplaceModuleName

            Mock Copy-Item {
                [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($WEPath, $WEDestination)
                Write-WELog " Mocked: Copying $WEPath to $WEDestination" " INFO"
            } -Verifiable -ModuleName $marketplaceModuleName

            Mock Import-RemoteVisualStudioPackageToPath {
                [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($WEVsixUrl, $WELocalFilePath)
                Write-WELog " Mocked: Downloading $WEVsixUrl to $WELocalFilePath" " INFO"
            } -Verifiable -ModuleName $marketplaceModuleName
        }

        It " Should not attempt to download or copy the file" {
            $WEExtensionMetadata = [PSCustomObject]@{
                name    = " SampleExtension"
                vsixUrl = " http://localhost/sampleextension.VSIXPackage"
            }
            $WEDownloadLocation = " c:\temp\"
            $WEExpectedFilePath = Join-Path -Path $WEDownloadLocation -ChildPath " SampleExtension.vsix"
            $WEResult = Import-ExtensionByMetadata -ExtensionMetadata $WEExtensionMetadata -DownloadLocation $WEDownloadLocation

            # Assertions
            Assert-MockCalled Import-RemoteVisualStudioPackageToPath -Exactly 0 -Scope It -ModuleName $marketplaceModuleName
            Assert-MockCalled Copy-Item -Exactly 0 -Scope It -ModuleName $marketplaceModuleName
            $WEResult | Should -Be $WEExpectedFilePath
        }
    }

    Context " Retries and error handling" {
        BeforeEach {
            Mock Test-Path {
                [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($WEPath)
                return $false
            } -Verifiable -ModuleName $marketplaceModuleName

            Mock Import-RemoteVisualStudioPackageToPath {
                [CmdletBinding()]
$ErrorActionPreference = "Stop"
param($WEVsixUrl, $WELocalFilePath)
                throw " Simulated error"
            } -Verifiable -ModuleName $marketplaceModuleName
        }

        It " Should throw an error if all retries fail" {
            $WEExtensionMetadata = [PSCustomObject]@{
                name    = " SampleExtension"
                vsixUrl = " http://localhost/sampleextension.VSIXPackage"
            }
            $WEDownloadLocation = " c:\temp\"
            { Import-ExtensionByMetadata -ExtensionMetadata $WEExtensionMetadata -DownloadLocation $WEDownloadLocation } |
            Should -Throw " Simulated error"
        }
    }
}

Describe " Get-ExtensionMetadata" {
    BeforeEach {
        Mock Get-ApiHeaders { return @{} } -ModuleName $marketplaceModuleName
        Mock Get-ApiFlags { return 100 } -ModuleName $marketplaceModuleName
        Mock Get-RequestBody {
            

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

param ($WEExtensionReference, $WEFlags)
            return @{ mockBody = " data" }
        } -ModuleName $marketplaceModuleName
        Mock Invoke-MarketplaceApi {
            

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

param ($WEApiUrl, $WEHeaders, $WEBody)
            return @{
                results = @(@{
                        extensions = @(
                            @{
                                versions = @(
                                    [PSCustomObject]@{
                                        version        = " 1.0.0";
                                        targetPlatform = " x64";
                                        files          = @(
                                            @{
                                                assetType = " Microsoft.VisualStudio.Services.VSIXPackage";
                                                source    = " http://localhost/vsix"
                                            }
                                        );
                                        properties     = @(
                                            @{
                                                key   = " Microsoft.VisualStudio.Code.PreRelease";
                                                value = " false"
                                            }
                                        )
                                    }
                                )
                            }
                        )
                    })
            }
        } -ModuleName $marketplaceModuleName
    }

    Context " Valid scenarios" {
        It " Should return metadata for a valid extension reference" {
            $result = Get-ExtensionMetadata -ExtensionReference " example.extension" -TargetPlatform " x64"

            $result | Should -Not -BeNullOrEmpty
            $result.name | Should -Be " example.extension"
            $result.vsixUrl | Should -Be " http://localhost/vsix"
            $result.dependencies | Should -BeNullOrEmpty
        }

        It " Should return metadata for a specific version" {
            Mock Invoke-MarketplaceApi {
                

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

param ($WEApiUrl, $WEHeaders, $WEBody)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    versions = @(
                                        [PSCustomObject]@{
                                            version        = " 2.0.0";
                                            targetPlatform = " x64";
                                            files          = @(
                                                @{
                                                    assetType = " Microsoft.VisualStudio.Services.VSIXPackage";
                                                    source    = " http://localhost/vsix-2.0.0"
                                                }
                                            );
                                            properties     = @(
                                                @{
                                                    key   = " Microsoft.VisualStudio.Code.PreRelease";
                                                    value = " false"
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        })
                }
            } -ModuleName $marketplaceModuleName

            $result = Get-ExtensionMetadata -ExtensionReference " example.extension" -VersionNumber " 2.0.0" -TargetPlatform " x64"

            $result | Should -Not -BeNullOrEmpty
            $result.vsixUrl | Should -Be " http://localhost/vsix-2.0.0"
        }

        It " Should filter by target platform" {
            Mock Invoke-MarketplaceApi {
                

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

param ($WEApiUrl, $WEHeaders, $WEBody)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    versions = @(
                                        [PSCustomObject]@{
                                            version        = " 1.0.0";
                                            targetPlatform = " x64";
                                            files          = @(
                                                @{
                                                    assetType = " Microsoft.VisualStudio.Services.VSIXPackage";
                                                    source    = " http://localhost/vsix-x64"
                                                }
                                            );
                                            properties     = @()
                                        },
                                        [PSCustomObject]@{
                                            version        = " 1.0.0";
                                            targetPlatform = " arm64";
                                            files          = @(
                                                @{
                                                    assetType = " Microsoft.VisualStudio.Services.VSIXPackage";
                                                    source    = " http://localhost/vsix-arm64"
                                                }
                                            );
                                            properties     = @()
                                        }
                                    )
                                }
                            )
                        })
                }
            } -ModuleName $marketplaceModuleName

            $result = Get-ExtensionMetadata -ExtensionReference " example.extension" -TargetPlatform " arm64"

            $result | Should -Not -BeNullOrEmpty
            $result.vsixUrl | Should -Be " http://localhost/vsix-arm64"
        }
    }

    Context " Error scenarios" {
        It " Should throw an error for missing 'versions' property" {
            Mock Invoke-MarketplaceApi {
                

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

param ($WEApiUrl, $WEHeaders, $WEBody)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    # Missing versions
                                }
                            )
                        })
                }
            } -ModuleName $marketplaceModuleName

            { Get-ExtensionMetadata -ExtensionReference " invalid.extension" -TargetPlatform " x64" } |
            Should -Throw " Property 'versions' is missing or inaccessible in the Marketplace API response. Ensure you have provided a valid extension id. The property 'versions' cannot be found on this object. Verify that the property exists."
        }

        It " Should throw an error if no VSIXPackage is found" {
            Mock Invoke-MarketplaceApi {
                

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

param ($WEApiUrl, $WEHeaders, $WEBody)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    versions = @(
                                        @{
                                            version    = " 1.0.0";
                                            files      = @(
                                                # Missing VSIXPackage
                                            );
                                            properties = @()
                                        }
                                    )
                                }
                            )
                        })
                }
            } -ModuleName $marketplaceModuleName

            { Get-ExtensionMetadata -ExtensionReference " example.extension" -TargetPlatform " x64" } |
            Should -Throw " No VSIXPackage was found in the file list for the extension metadata. Verify the extension and version specified are correct. The property 'source' cannot be found on this object. Verify that the property exists."
        }

        It " Should throw an error if pre-release version is found but not allowed" {
            Mock Invoke-MarketplaceApi {
                

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

param ($WEApiUrl, $WEHeaders, $WEBody)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    versions = @(
                                        [PSCustomObject]@{
                                            version        = " 2.0.0";
                                            targetPlatform = " x64";
                                            files          = @(
                                                @{
                                                    assetType = " Microsoft.VisualStudio.Services.VSIXPackage";
                                                    source    = " http://localhost/vsix-2.0.0"
                                                }
                                            );
                                            properties     = @(
                                                @{
                                                    key   = " Microsoft.VisualStudio.Code.PreRelease";
                                                    value = " true"
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        })
                }
            } -ModuleName $marketplaceModuleName

            { Get-ExtensionMetadata -ExtensionReference " example.extension" -TargetPlatform " x64" -DownloadPreRelease $false } |
            Should -Throw " Extension 'example.extension' version 'Not specified' not found for 'x64'. Latest 10 versions found: (2.0.0)"
        }
    }
}

Describe 'Get-CurrentPlatform' {
    It 'Should return win32-arm64 when processor is ARM64' {
        # Simulate an ARM64 processor
        Mock Get-CimInstance {
            [pscustomobject]@{ Architecture = 12 }
        } -Verifiable -ModuleName $marketplaceModuleName

        $result = Get-CurrentPlatform
        $result | Should -Be 'win32-arm64'

        Assert-MockCalled Get-CimInstance -Exactly 1 -ModuleName $marketplaceModuleName
    }

    It 'Should return win32-x64 when processor is x64' {
        # Simulate an x64 processor
        Mock Get-CimInstance {
            [pscustomobject]@{ Architecture = 9 }
        } -Verifiable -ModuleName $marketplaceModuleName

        $result = Get-CurrentPlatform
        $result | Should -Be 'win32-x64'

        Assert-MockCalled Get-CimInstance -Exactly 1 -ModuleName $marketplaceModuleName
    }

    It 'Should default to win32-x64 when processor architecture is unknown' {
        # Simulate an unknown processor architecture
        Mock Get-CimInstance {
            [pscustomobject]@{ Architecture = 99 }
        } -Verifiable -ModuleName $marketplaceModuleName

       ;  $result = Get-CurrentPlatform
        $result | Should -Be 'win32-x64'

        Assert-MockCalled Get-CimInstance -Exactly 1 -ModuleName $marketplaceModuleName
    }
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
