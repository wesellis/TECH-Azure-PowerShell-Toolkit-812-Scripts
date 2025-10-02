#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Visual Studio Marketplace Utils.Tests
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
    $RetryModuleName = 'windows-retry-utils'
    try {
" _common/$RetryModuleName.psm1" )
    $MarketplaceModuleName = 'windows-visual-studio-marketplace-utils'
    [OutputType([PSCustomObject])]
 -ErrorAction Stop { }
    Mock Get-CimInstance -ErrorAction Stop {
        [pscustomobject]@{ Architecture = 9 }
    } -Verifiable -ModuleName $MarketplaceModuleName
    $script:currentAttempt = 0
    $script:sleepTimes = @()
    $params = @{
        MockWith = "{"
        CommandName = "Start-Sleep"
        ModuleName = $RetryModuleName
    }
    Mock @params
function Write-Host {
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
param($seconds) $script:sleepTimes += $seconds; }
    Mock Write-Information {} -ModuleName $MarketplaceModuleName
    Mock Write-Information {} -ModuleName $RetryModuleName
}
Describe "Get-ApiHeaders -ErrorAction Stop Tests" {
    It "Should return the correct headers" {
    $headers = Get-ApiHeaders -ErrorAction Stop
    $headers | Should -Not -BeNullOrEmpty
    $headers["Accept" ] | Should -Be " application/json;api-version=3.0-preview.1"
    $headers["Content-Type" ] | Should -Be " application/json"
    }
}
Describe "Get-ApiFlags -ErrorAction Stop Tests" {
    It "Should be 402" {
    $flags = Get-ApiFlags -VersionNumber $null
        ($flags -band 402) | Should -Be 402
    }
}
Describe "Get-RequestBody -ErrorAction Stop Tests" {
    It "Should create a valid request body" {
    $body = Get-RequestBody -ExtensionReference " test.extension" -Flags 402
    $JsonBody = $body | ConvertFrom-Json
    $JsonBody.filters[0].criteria[0].filterType | Should -Be 7
    $JsonBody.filters[0].criteria[0].value | Should -Be " test.extension"
    $JsonBody.flags | Should -Be 402
    }
}
Describe "Import-ExtensionByMetadata Tests" {
    Context "When the destination file does not exist" {
        BeforeEach {
            Mock Test-Path {
                param($Path)
                return $false
            } -Verifiable -ModuleName $MarketplaceModuleName
            Mock Copy-Item {
                param($Path, $Destination)
                Write-Output "Mocked: Copying $Path to $Destination"
            } -Verifiable -ModuleName $MarketplaceModuleName
            Mock Import-RemoteVisualStudioPackageToPath {
                param($VsixUrl, $LocalFilePath)
                Write-Output "Mocked: Downloading $VsixUrl to $LocalFilePath"
            } -Verifiable -ModuleName $MarketplaceModuleName
        }
        It "Should download and copy the file to the destination" {
    $ExtensionMetadata = [PSCustomObject]@{
                name    = "SampleExtension"
                vsixUrl = " http://localhost/sampleextension.VSIXPackage"
            }
    $DownloadLocation = " c:\temp\"
    $ExpectedFilePath = Join-Path -Path $DownloadLocation -ChildPath "SampleExtension.vsix"
    $Result = Import-ExtensionByMetadata -ExtensionMetadata $ExtensionMetadata -DownloadLocation $DownloadLocation
            Assert-MockCalled Import-RemoteVisualStudioPackageToPath -Exactly 1 -Scope It -ModuleName $MarketplaceModuleName
            Assert-MockCalled Copy-Item -Exactly 1 -Scope It -ModuleName $MarketplaceModuleName
    $Result | Should -Be $ExpectedFilePath
        }
    }
    Context "When the destination file already exists" {
        BeforeEach {
            Mock Test-Path {
                param($Path)
    $true
            } -Verifiable -ModuleName $MarketplaceModuleName
            Mock Copy-Item {
                param($Path, $Destination)
                Write-Output "Mocked: Copying $Path to $Destination"
            } -Verifiable -ModuleName $MarketplaceModuleName
            Mock Import-RemoteVisualStudioPackageToPath {
                param($VsixUrl, $LocalFilePath)
                Write-Output "Mocked: Downloading $VsixUrl to $LocalFilePath"
            } -Verifiable -ModuleName $MarketplaceModuleName
        }
        It "Should not attempt to download or copy the file" {
    $ExtensionMetadata = [PSCustomObject]@{
                name    = "SampleExtension"
                vsixUrl = " http://localhost/sampleextension.VSIXPackage"
            }
    $DownloadLocation = " c:\temp\"
    $ExpectedFilePath = Join-Path -Path $DownloadLocation -ChildPath "SampleExtension.vsix"
    $Result = Import-ExtensionByMetadata -ExtensionMetadata $ExtensionMetadata -DownloadLocation $DownloadLocation
            Assert-MockCalled Import-RemoteVisualStudioPackageToPath -Exactly 0 -Scope It -ModuleName $MarketplaceModuleName
            Assert-MockCalled Copy-Item -Exactly 0 -Scope It -ModuleName $MarketplaceModuleName
    $Result | Should -Be $ExpectedFilePath
        }
    }
    Context "Retries and error handling" {
        BeforeEach {
            Mock Test-Path {
                param($Path)
                return $false
            } -Verifiable -ModuleName $MarketplaceModuleName
            Mock Import-RemoteVisualStudioPackageToPath {
                param($VsixUrl, $LocalFilePath)
                throw "Simulated error"
            } -Verifiable -ModuleName $MarketplaceModuleName
        }
        It "Should throw an error if all retries fail" {
    $ExtensionMetadata = [PSCustomObject]@{
                name    = "SampleExtension"
                vsixUrl = " http://localhost/sampleextension.VSIXPackage"
            }
    $DownloadLocation = " c:\temp\"
            { Import-ExtensionByMetadata -ExtensionMetadata $ExtensionMetadata -DownloadLocation $DownloadLocation } |
            Should -Throw "Simulated error"
        }
    }
}
Describe "Get-ExtensionMetadata" {
    BeforeEach {
        Mock Get-ApiHeaders -ErrorAction Stop { return @{} } -ModuleName $MarketplaceModuleName
        Mock Get-ApiFlags -ErrorAction Stop { return 100 } -ModuleName $MarketplaceModuleName
        Mock Get-RequestBody -ErrorAction Stop {
function Write-Host {
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
param($ExtensionReference, $Flags)
            return @{ mockBody = " data" }
        } -ModuleName $MarketplaceModuleName
        Mock Invoke-MarketplaceApi {
function Write-Host {
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
param($ApiUrl, $Headers, $Body)
            return @{
                results = @(@{
                        extensions = @(
                            @{
                                versions = @(
                                    [PSCustomObject]@{
                                        version        = " 1.0.0" ;
                                        targetPlatform = " x64" ;
                                        files          = @(
                                            @{
                                                assetType = "Microsoft.VisualStudio.Services.VSIXPackage" ;
                                                source    = " http://localhost/vsix"
                                            }
                                        );
                                        properties     = @(
                                            @{
                                                key   = "Microsoft.VisualStudio.Code.PreRelease" ;
                                                value = " false"
                                            }
                                        )
                                    }
                                )
                            }
                        )
                    })
            }
        } -ModuleName $MarketplaceModuleName
    }
    Context "Valid scenarios" {
        It "Should return metadata for a valid extension reference" {
    $result = Get-ExtensionMetadata -ExtensionReference " example.extension" -TargetPlatform " x64"
    $result | Should -Not -BeNullOrEmpty
    $result.name | Should -Be " example.extension"
    $result.vsixUrl | Should -Be " http://localhost/vsix"
    $result.dependencies | Should -BeNullOrEmpty
        }
        It "Should return metadata for a specific version" {
            Mock Invoke-MarketplaceApi {
function Write-Host {
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
param($ApiUrl, $Headers, $Body)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    versions = @(
                                        [PSCustomObject]@{
                                            version        = " 2.0.0" ;
                                            targetPlatform = " x64" ;
                                            files          = @(
                                                @{
                                                    assetType = "Microsoft.VisualStudio.Services.VSIXPackage" ;
                                                    source    = " http://localhost/vsix-2.0.0"
                                                }
                                            );
                                            properties     = @(
                                                @{
                                                    key   = "Microsoft.VisualStudio.Code.PreRelease" ;
                                                    value = " false"
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        })
                }
            } -ModuleName $MarketplaceModuleName
    $result = Get-ExtensionMetadata -ExtensionReference " example.extension" -VersionNumber " 2.0.0" -TargetPlatform " x64"
    $result | Should -Not -BeNullOrEmpty
    $result.vsixUrl | Should -Be " http://localhost/vsix-2.0.0"
        }
        It "Should filter by target platform" {
            Mock Invoke-MarketplaceApi {
function Write-Host {
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
param($ApiUrl, $Headers, $Body)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    versions = @(
                                        [PSCustomObject]@{
                                            version        = " 1.0.0" ;
                                            targetPlatform = " x64" ;
                                            files          = @(
                                                @{
                                                    assetType = "Microsoft.VisualStudio.Services.VSIXPackage" ;
                                                    source    = " http://localhost/vsix-x64"
                                                }
                                            );
                                            properties     = @()
                                        },
                                        [PSCustomObject]@{
                                            version        = " 1.0.0" ;
                                            targetPlatform = " arm64" ;
                                            files          = @(
                                                @{
                                                    assetType = "Microsoft.VisualStudio.Services.VSIXPackage" ;
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
            } -ModuleName $MarketplaceModuleName
    $result = Get-ExtensionMetadata -ExtensionReference " example.extension" -TargetPlatform " arm64"
    $result | Should -Not -BeNullOrEmpty
    $result.vsixUrl | Should -Be " http://localhost/vsix-arm64"
        }
    }
    Context "Error scenarios" {
        It "Should throw an error for missing 'versions' property" {
            Mock Invoke-MarketplaceApi {
function Write-Host {
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
param($ApiUrl, $Headers, $Body)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                }
                            )
                        })
                }
            } -ModuleName $MarketplaceModuleName
            { Get-ExtensionMetadata -ExtensionReference " invalid.extension" -TargetPlatform " x64" } |
            Should -Throw "Property 'versions' is missing or inaccessible in the Marketplace API response. Ensure you have provided a valid extension id. The property 'versions' cannot be found on this object. Verify that the property exists."
        }
        It "Should throw an error if no VSIXPackage is found" {
            Mock Invoke-MarketplaceApi {
function Write-Host {
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
param($ApiUrl, $Headers, $Body)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    versions = @(
                                        @{
                                            version    = " 1.0.0" ;
                                            files      = @(
                                            );
                                            properties = @()
                                        }
                                    )
                                }
                            )
                        })
                }
            } -ModuleName $MarketplaceModuleName
            { Get-ExtensionMetadata -ExtensionReference " example.extension" -TargetPlatform " x64" } |
            Should -Throw "No VSIXPackage was found in the file list for the extension metadata. Verify the extension and version specified are correct. The property 'source' cannot be found on this object. Verify that the property exists."
        }
        It "Should throw an error if pre-release version is found but not allowed" {
            Mock Invoke-MarketplaceApi {
function Write-Host {
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
param($ApiUrl, $Headers, $Body)
                return @{
                    results = @(@{
                            extensions = @(
                                @{
                                    versions = @(
                                        [PSCustomObject]@{
                                            version        = " 2.0.0" ;
                                            targetPlatform = " x64" ;
                                            files          = @(
                                                @{
                                                    assetType = "Microsoft.VisualStudio.Services.VSIXPackage" ;
                                                    source    = " http://localhost/vsix-2.0.0"
                                                }
                                            );
                                            properties     = @(
                                                @{
                                                    key   = "Microsoft.VisualStudio.Code.PreRelease" ;
                                                    value = " true"
                                                }
                                            )
                                        }
                                    )
                                }
                            )
                        })
                }
            } -ModuleName $MarketplaceModuleName
            { Get-ExtensionMetadata -ExtensionReference " example.extension" -TargetPlatform " x64" -DownloadPreRelease $false } |
            Should -Throw "Extension 'example.extension' version 'Not specified' not found for 'x64'. Latest 10 versions found: (2.0.0)"
        }
    }
}
Describe 'Get-CurrentPlatform' {
    It 'Should return win32-arm64 when processor is ARM64' {
        Mock Get-CimInstance -ErrorAction Stop {
            [pscustomobject]@{ Architecture = 12 }
        } -Verifiable -ModuleName $MarketplaceModuleName
    $result = Get-CurrentPlatform -ErrorAction Stop
    $result | Should -Be 'win32-arm64'
        Assert-MockCalled Get-CimInstance -Exactly 1 -ModuleName $MarketplaceModuleName
    }
    It 'Should return win32-x64 when processor is x64' {
        Mock Get-CimInstance -ErrorAction Stop {
            [pscustomobject]@{ Architecture = 9 }
        } -Verifiable -ModuleName $MarketplaceModuleName
    $result = Get-CurrentPlatform -ErrorAction Stop
    $result | Should -Be 'win32-x64'
        Assert-MockCalled Get-CimInstance -Exactly 1 -ModuleName $MarketplaceModuleName
    }
    It 'Should default to win32-x64 when processor architecture is unknown' {
        Mock Get-CimInstance -ErrorAction Stop {
            [pscustomobject]@{ Architecture = 99 }
        } -Verifiable -ModuleName $MarketplaceModuleName
    $result = Get-CurrentPlatform -ErrorAction Stop
    $result | Should -Be 'win32-x64'
        Assert-MockCalled Get-CimInstance -Exactly 1 -ModuleName $MarketplaceModuleName
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
