#Requires -Version 7.4

<#
.SYNOPSIS
    Install .NET Core SDK or Runtime on Windows.

.DESCRIPTION
    This script installs the .NET Core SDK or Runtime on Windows.
    It supports installing specific versions, channels, and architectures.

.PARAMETER Channel
    Default: LTS
    Download from the Channel specified. Possible values:
    - Current - most current release
    - LTS - most current supported release
    - 2-part version in a format A.B - represents a specific release
          examples: 2.0, 1.0
    - Branch name
          examples: release/2.0.0, Master
    Note: The version parameter overrides the channel parameter.

.PARAMETER Version
    Default: latest
    Represents a build version on specific channel. Possible values:
    - latest - most latest build on specific channel
    - 3-part version in a format A.B.C - represents specific version of build
          examples: 2.0.0-preview2-006120, 1.1.0

.PARAMETER InstallDir
    Default: %LocalAppData%\Microsoft\dotnet
    Path to where to install dotnet. Note that binaries will be placed directly in a given directory.

.PARAMETER Architecture
    Default: <auto> - this value represents currently running OS architecture
    Architecture of dotnet binaries to be installed.
    Possible values are: <auto>, amd64, x64, x86, arm64, arm

.PARAMETER Runtime
    Installs just a shared runtime, not the entire SDK.
    Possible values:
        - dotnet     - the Microsoft.NETCore.App shared runtime
        - aspnetcore - the Microsoft.AspNetCore.App shared runtime
        - windowsdesktop - the Microsoft.WindowsDesktop.App shared runtime

.PARAMETER JSonFile
    Determines the SDK version from a user specified global.json file
    Note: global.json must have a value for 'SDK:Version'

.PARAMETER DryRun
    If set it will not perform installation but instead display what command line to use.

.PARAMETER NoPath
    By default this script will set environment variable PATH for the current process.
    If set it will display binaries location but not set any environment variable.

.PARAMETER AzureFeed
    Default: https://dotnetcli.azureedge.net/dotnet
    This parameter typically is not changed by the user.
    It allows changing the URL for the Azure feed used by this installer.

.PARAMETER UncachedFeed
    This parameter typically is not changed by the user.
    It allows changing the URL for the Uncached feed used by this installer.

.PARAMETER FeedCredential
    Used as a query string to append to the Azure feed.

.PARAMETER ProxyAddress
    If set, the installer will use the proxy when making web requests

.PARAMETER ProxyUseDefaultCredentials
    Default: false
    Use default credentials, when using proxy address.

.PARAMETER ProxyBypassList
    If set with ProxyAddress, will provide the list of comma separated urls that will bypass the proxy

.PARAMETER SkipNonVersionedFiles
    Default: false
    Skips installing non-versioned files if they already exist, such as dotnet.exe.

.PARAMETER NoCdn
    Disable downloading from the Azure CDN, and use the uncached feed directly.

.PARAMETER OverrideVersion
    Install and Override dotnet version anyway

.EXAMPLE
    .\Dotnet-Install.ps1

.EXAMPLE
    .\Dotnet-Install.ps1 -Channel Current -Version latest

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [string]$Channel = "LTS",
    [string]$Version = "Latest",
    [ValidateNotNullOrEmpty()]
    [string]$JSonFile,
    [string]$InstallDir = "<auto>",
    [string]$Architecture = "<auto>",
    [ValidateSet("dotnet", "aspnetcore", "windowsdesktop", IgnoreCase = $false)]
    [string]$Runtime,
    [switch]$DryRun,
    [switch]$NoPath,
    [string]$AzureFeed = "https://dotnetcli.azureedge.net/dotnet",
    [string]$UncachedFeed = "https://dotnetcli.blob.core.windows.net/dotnet",
    [ValidateNotNullOrEmpty()]
    [string]$FeedCredential,
    [ValidateNotNullOrEmpty()]
    [string]$ProxyAddress,
    [switch]$ProxyUseDefaultCredentials,
    [string[]]$ProxyBypassList = @(),
    [switch]$SkipNonVersionedFiles,
    [switch]$NoCdn,
    [bool]$OverrideVersion = $false
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

if ($NoCdn) {
    $AzureFeed = $UncachedFeed
}

$BinFolderRelativePath = ""
$VersionRegEx = "/\d+\.\d+[^/]+/"
$OverrideNonVersionedFiles = !$SkipNonVersionedFiles

function Say($str) {
    try {
        Write-Output "dotnet-install: $str"
    }
    catch {
        Write-Output "dotnet-install: $str"
    }
}

function Say-Warning($str) {
    try {
        Write-Warning "dotnet-install: $str"
    }
    catch {
        Write-Output "dotnet-install: Warning: $str"
    }
}

function Say-Error($str) {
    try {
        $Host.UI.WriteErrorLine("dotnet-install: $str")
    }
    catch {
        Write-Output "dotnet-install: Error: $str"
    }
}

function Say-Verbose($str) {
    try {
        Write-Verbose "dotnet-install: $str"
    }
    catch {
        Write-Output "dotnet-install: $str"
    }
}

function Say-Invocation($Invocation) {
    $command = $Invocation.MyCommand
    $args = (($Invocation.BoundParameters.Keys | ForEach-Object { "-$_ `"$($Invocation.BoundParameters[$_])`"" }) -join " ")
    Say-Verbose "$command $args"
}

function Invoke-With-Retry([ScriptBlock]$ScriptBlock, [int]$MaxAttempts = 3, [int]$SecondsBetweenAttempts = 1) {
    $Attempts = 0
    while ($true) {
        try {
            return & $ScriptBlock
        }
        catch {
            $Attempts++
            if ($Attempts -lt $MaxAttempts) {
                Start-Sleep $SecondsBetweenAttempts
            }
            else {
                throw
            }
        }
    }
}

function Get-Machine-Architecture() {
    Say-Invocation $MyInvocation
    if ($ENV:PROCESSOR_ARCHITEW6432 -ne $null) {
        return $ENV:PROCESSOR_ARCHITEW6432
    }
    return $ENV:PROCESSOR_ARCHITECTURE
}

function Get-CLIArchitecture-From-Architecture([ValidateNotNullOrEmpty()][string]$Architecture) {
    Say-Invocation $MyInvocation
    switch ($Architecture.ToLower()) {
        { $_ -eq "<auto>" } { return Get-CLIArchitecture-From-Architecture $(Get-Machine-Architecture) }
        { ($_ -eq "amd64") -or ($_ -eq "x64") } { return "x64" }
        { $_ -eq "x86" } { return "x86" }
        { $_ -eq "arm" } { return "arm" }
        { $_ -eq "arm64" } { return "arm64" }
        default { throw "Architecture '$Architecture' not supported. If you think this is a bug, report it at https://github.com/dotnet/install-scripts/issues" }
    }
}

function Get-Version-Info-From-Version-Text([ValidateNotNullOrEmpty()][string]$VersionText) {
    Say-Invocation $MyInvocation
    $Data = -split $VersionText
    $VersionInfo = @{
        CommitHash = $(if ($Data.Count -gt 1) { $Data[0] })
        Version = $Data[-1]
    }
    return $VersionInfo
}

function Load-Assembly([string]$Assembly) {
    try {
        Add-Type -Assembly $Assembly | Out-Null
    }
    catch {
        # Ignore load errors
    }
}

function GetHTTPResponse([Uri]$Uri) {
    Invoke-With-Retry {
        $HttpClient = $null
        try {
            Load-Assembly -Assembly System.Net.Http
            if (-not $ProxyAddress) {
                try {
                    $DefaultProxy = [System.Net.WebRequest]::DefaultWebProxy
                    if ($DefaultProxy -and (-not $DefaultProxy.IsBypassed($Uri))) {
                        $ProxyAddress = $DefaultProxy.GetProxy($Uri).OriginalString
                        $ProxyUseDefaultCredentials = $true
                    }
                } catch {
                    $ProxyAddress = $null
                    Say-Verbose "Exception ignored: $_.Exception.Message - moving forward..."
                }
            }
            if ($ProxyAddress) {
                $HttpClientHandler = New-Object -ErrorAction Stop System.Net.Http.HttpClientHandler
                $HttpClientHandler.Proxy = New-Object -ErrorAction Stop System.Net.WebProxy -Property @{
                    Address = $ProxyAddress
                    UseDefaultCredentials = $ProxyUseDefaultCredentials
                    BypassList = $ProxyBypassList
                }
                $HttpClient = New-Object -ErrorAction Stop System.Net.Http.HttpClient -ArgumentList $HttpClientHandler
            }
            else {
                $HttpClient = New-Object -ErrorAction Stop System.Net.Http.HttpClient
            }
            $HttpClient.Timeout = New-TimeSpan -Minutes 20
            $Task = $HttpClient.GetAsync("${Uri}${FeedCredential}").ConfigureAwait("false")
            $Response = $Task.GetAwaiter().GetResult()
            if (($null -eq $Response) -or (-not ($Response.IsSuccessStatusCode))) {
                $DownloadException = [System.Exception]"Unable to download $Uri."
                if ($null -ne $Response) {
                    $DownloadException.Data["StatusCode"] = [int]$Response.StatusCode
                    $DownloadException.Data["ErrorMessage"] = "Unable to download $Uri. Returned HTTP status code: " + $DownloadException.Data["StatusCode"]
                }
                throw $DownloadException
            }
            return $Response
        }
        catch [System.Net.Http.HttpRequestException] {
            $DownloadException = [System.Exception]"Unable to download $Uri."
            $CurrentException = $PSItem.Exception
            $ErrorMsg = $CurrentException.Message + "`r`n"
            while ($CurrentException.InnerException) {
                $CurrentException = $CurrentException.InnerException
                $ErrorMsg = $ErrorMsg + $CurrentException.Message + "`r`n"
            }
            if ($ErrorMsg -like "*SSL/TLS*") {
                $ErrorMsg = $ErrorMsg + "Ensure that TLS 1.2 or higher is enabled to use this script.`r`n"
            }
            $DownloadException.Data["ErrorMessage"] = $ErrorMsg
            throw $DownloadException
        }
        finally {
            if ($null -ne $HttpClient) {
                $HttpClient.Dispose()
            }
        }
    }
}

function Get-Latest-Version-Info([ValidateNotNullOrEmpty()][string]$AzureFeed, [ValidateNotNullOrEmpty()][string]$Channel) {
    Say-Invocation $MyInvocation
    $VersionFileUrl = $null
    if ($Runtime -eq "dotnet") {
        $VersionFileUrl = "$UncachedFeed/Runtime/$Channel/latest.version"
    }
    elseif ($Runtime -eq "aspnetcore") {
        $VersionFileUrl = "$UncachedFeed/aspnetcore/Runtime/$Channel/latest.version"
    }
    elseif ($Runtime -eq "windowsdesktop") {
        $VersionFileUrl = "$UncachedFeed/WindowsDesktop/$Channel/latest.version"
    }
    elseif (-not $Runtime) {
        $VersionFileUrl = "$UncachedFeed/Sdk/$Channel/latest.version"
    }
    else {
        throw "Invalid value for `$Runtime"
    }
    try {
        $Response = GetHTTPResponse -Uri $VersionFileUrl
    }
    catch {
        Say-Error "Could not resolve version information."
        throw
    }
    $StringContent = $Response.Content.ReadAsStringAsync().Result
    switch ($Response.Content.Headers.ContentType) {
        { ($_ -eq "application/octet-stream") } { $VersionText = $StringContent }
        { ($_ -eq "text/plain") } { $VersionText = $StringContent }
        { ($_ -eq "text/plain; charset=UTF-8") } { $VersionText = $StringContent }
        default { throw "`$Response.Content.Headers.ContentType` is an unknown .version file content type." }
    }
    $VersionInfo = Get-Version-Info-From-Version-Text $VersionText
    return $VersionInfo
}

function Parse-Jsonfile-For-Version([ValidateNotNullOrEmpty()][string]$JSonFile) {
    Say-Invocation $MyInvocation
    If (-Not (Test-Path $JSonFile)) {
        throw "Unable to find '$JSonFile'"
    }
    try {
        $JSonContent = Get-Content($JSonFile) -Raw | ConvertFrom-Json | Select-Object -expand "sdk" -ErrorAction SilentlyContinue
    }
    catch {
        Say-Error "Json file unreadable: '$JSonFile'"
        throw
    }
    if ($JSonContent) {
        try {
            $JSonContent.PSObject.Properties | ForEach-Object {
                $PropertyName = $_.Name
                if ($PropertyName -eq "version") {
                    $Version = $_.Value
                    Say-Verbose "Version = $Version"
                }
            }
        } catch {
            Say-Error "Unable to parse the SDK node in '$JSonFile'"
            throw
        }
    }
    else {
        throw "Unable to find the SDK node in '$JSonFile'"
    }
    If ($null -eq $Version) {
        throw "Unable to find the SDK:version node in '$JSonFile'"
    }
    return $Version
}

function Get-Specific-Version-From-Version([ValidateNotNullOrEmpty()][string]$AzureFeed, [ValidateNotNullOrEmpty()][string]$Channel, [ValidateNotNullOrEmpty()][string]$Version, [string]$JSonFile) {
    Say-Invocation $MyInvocation
    if (-not $JSonFile) {
        if ($Version.ToLower() -eq "latest") {
            $LatestVersionInfo = Get-Latest-Version-Info -AzureFeed $AzureFeed -Channel $Channel
            return $LatestVersionInfo.Version
        }
        else {
            return $Version
        }
    }
    else {
        return Parse-Jsonfile-For-Version $JSonFile
    }
}

function Get-Download-Link([ValidateNotNullOrEmpty()][string]$AzureFeed, [ValidateNotNullOrEmpty()][string]$SpecificVersion, [ValidateNotNullOrEmpty()][string]$CLIArchitecture) {
    Say-Invocation $MyInvocation
    $SpecificProductVersion = Get-Product-Version -AzureFeed $AzureFeed -SpecificVersion $SpecificVersion
    if ($Runtime -eq "dotnet") {
        $PayloadURL = "$AzureFeed/Runtime/$SpecificVersion/dotnet-runtime-$SpecificProductVersion-win-$CLIArchitecture.zip"
    }
    elseif ($Runtime -eq "aspnetcore") {
        $PayloadURL = "$AzureFeed/aspnetcore/Runtime/$SpecificVersion/aspnetcore-runtime-$SpecificProductVersion-win-$CLIArchitecture.zip"
    }
    elseif ($Runtime -eq "windowsdesktop") {
        $PayloadURL = "$AzureFeed/Runtime/$SpecificVersion/windowsdesktop-runtime-$SpecificProductVersion-win-$CLIArchitecture.zip"
        if ($SpecificVersion -match '^(\d+)\.(.*)$') {
            $MajorVersion = [int]$Matches[1]
            if ($MajorVersion -ge 5) {
                $PayloadURL = "$AzureFeed/WindowsDesktop/$SpecificVersion/windowsdesktop-runtime-$SpecificProductVersion-win-$CLIArchitecture.zip"
            }
        }
    }
    elseif (-not $Runtime) {
        $PayloadURL = "$AzureFeed/Sdk/$SpecificVersion/dotnet-sdk-$SpecificProductVersion-win-$CLIArchitecture.zip"
    }
    else {
        throw "Invalid value for `$Runtime"
    }
    Say-Verbose "Constructed primary named payload URL: $PayloadURL"
    return $PayloadURL, $SpecificProductVersion
}

function Get-LegacyDownload-Link([ValidateNotNullOrEmpty()][string]$AzureFeed, [ValidateNotNullOrEmpty()][string]$SpecificVersion, [ValidateNotNullOrEmpty()][string]$CLIArchitecture) {
    Say-Invocation $MyInvocation
    if (-not $Runtime) {
        $PayloadURL = "$AzureFeed/Sdk/$SpecificVersion/dotnet-dev-win-$CLIArchitecture.$SpecificVersion.zip"
    }
    elseif ($Runtime -eq "dotnet") {
        $PayloadURL = "$AzureFeed/Runtime/$SpecificVersion/dotnet-win-$CLIArchitecture.$SpecificVersion.zip"
    }
    else {
        return $null
    }
    Say-Verbose "Constructed legacy named payload URL: $PayloadURL"
    return $PayloadURL
}

function Get-Product-Version([ValidateNotNullOrEmpty()][string]$AzureFeed, [ValidateNotNullOrEmpty()][string]$SpecificVersion) {
    Say-Invocation $MyInvocation
    if ($Runtime -eq "dotnet") {
        $ProductVersionTxtURL = "$AzureFeed/Runtime/$SpecificVersion/productVersion.txt"
    }
    elseif ($Runtime -eq "aspnetcore") {
        $ProductVersionTxtURL = "$AzureFeed/aspnetcore/Runtime/$SpecificVersion/productVersion.txt"
    }
    elseif ($Runtime -eq "windowsdesktop") {
        $ProductVersionTxtURL = "$AzureFeed/Runtime/$SpecificVersion/productVersion.txt"
        if ($SpecificVersion -match '^(\d+)\.(.*)') {
            $MajorVersion = [int]$Matches[1]
            if ($MajorVersion -ge 5) {
                $ProductVersionTxtURL = "$AzureFeed/WindowsDesktop/$SpecificVersion/productVersion.txt"
            }
        }
    }
    elseif (-not $Runtime) {
        $ProductVersionTxtURL = "$AzureFeed/Sdk/$SpecificVersion/productVersion.txt"
    }
    else {
        throw "Invalid value '$Runtime' specified for `$Runtime"
    }
    Say-Verbose "Checking for existence of $ProductVersionTxtURL"
    try {
        $ProductVersionResponse = GetHTTPResponse($ProductVersionTxtUrl)
        if ($ProductVersionResponse.StatusCode -eq 200) {
            $ProductVersion = $ProductVersionResponse.Content.ReadAsStringAsync().Result.Trim()
            if ($ProductVersion -ne $SpecificVersion) {
                Say "Using alternate version $ProductVersion found in $ProductVersionTxtURL"
            }
            return $ProductVersion
        }
        else {
            Say-Verbose "Got StatusCode $($ProductVersionResponse.StatusCode) trying to get productVersion.txt at $ProductVersionTxtUrl, so using default value of $SpecificVersion"
            $ProductVersion = $SpecificVersion
        }
    } catch {
        Say-Verbose "Could not read productVersion.txt at $ProductVersionTxtUrl, so using default value of $SpecificVersion (Exception: '$($_.Exception.Message)')"
        $ProductVersion = $SpecificVersion
    }
    return $ProductVersion
}

function Get-User-Share-Path() {
    Say-Invocation $MyInvocation
    $InstallRoot = $env:DOTNET_INSTALL_DIR
    if (!$InstallRoot) {
        $InstallRoot = "$env:LocalAppData\Microsoft\dotnet"
    }
    return $InstallRoot
}

function Resolve-Installation-Path([ValidateNotNullOrEmpty()][string]$InstallDir) {
    Say-Invocation $MyInvocation
    if ($InstallDir -eq "<auto>") {
        return Get-User-Share-Path
    }
    return $InstallDir
}

function Is-Dotnet-Package-Installed([ValidateNotNullOrEmpty()][string]$InstallRoot, [ValidateNotNullOrEmpty()][string]$RelativePathToPackage, [ValidateNotNullOrEmpty()][string]$SpecificVersion) {
    Say-Invocation $MyInvocation
    $DotnetPackagePath = Join-Path -Path $InstallRoot -ChildPath $RelativePathToPackage | Join-Path -ChildPath $SpecificVersion
    Say-Verbose "Is-Dotnet-Package-Installed: DotnetPackagePath=$DotnetPackagePath"
    return Test-Path $DotnetPackagePath -PathType Container
}

function Get-Absolute-Path([ValidateNotNullOrEmpty()][string]$RelativeOrAbsolutePath) {
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($RelativeOrAbsolutePath)
}

function Get-Path-Prefix-With-Version($path) {
    $match = [regex]::match($path, $VersionRegEx)
    if ($match.Success) {
        return $entry.FullName.Substring(0, $match.Index + $match.Length)
    }
    return $null
}

function Get-List-Of-Directories-And-Versions-To-Unpack-From-Dotnet-Package([System.IO.Compression.ZipArchive]$Zip, [ValidateNotNullOrEmpty()][string]$OutPath) {
    Say-Invocation $MyInvocation
    $ret = @()
    foreach ($entry in $Zip.Entries) {
        $dir = Get-Path-Prefix-With-Version $entry.FullName
        if ($null -ne $dir) {
            $path = Get-Absolute-Path $(Join-Path -Path $OutPath -ChildPath $dir)
            if (-Not (Test-Path $path -PathType Container)) {
                $ret = $ret + $dir
            }
        }
    }
    $ret = $ret | Sort-Object | Get-Unique -ErrorAction Stop
    $values = ($ret | ForEach-Object { "$_" }) -join ";"
    Say-Verbose "Directories to unpack: $values"
    return $ret
}

function Extract-Dotnet-Package([ValidateNotNullOrEmpty()][string]$ZipPath, [ValidateNotNullOrEmpty()][string]$OutPath) {
    Say-Invocation $MyInvocation
    Load-Assembly -Assembly System.IO.Compression.FileSystem
    Set-Variable -Name Zip
    try {
        $Zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $DirectoriesToUnpack = Get-List-Of-Directories-And-Versions-To-Unpack-From-Dotnet-Package -Zip $Zip -OutPath $OutPath
        foreach ($entry in $Zip.Entries) {
            $PathWithVersion = Get-Path-Prefix-With-Version $entry.FullName
            if (($null -eq $PathWithVersion) -Or ($DirectoriesToUnpack -contains $PathWithVersion)) {
                $DestinationPath = Get-Absolute-Path $(Join-Path -Path $OutPath -ChildPath $entry.FullName)
                $DestinationDir = Split-Path -Parent $DestinationPath
                $OverrideFiles = $OverrideNonVersionedFiles -Or (-Not (Test-Path $DestinationPath))
                if ((-Not $DestinationPath.EndsWith("\")) -And $OverrideFiles) {
                    New-Item -ItemType Directory -Force -Path $DestinationDir | Out-Null
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $DestinationPath, $OverrideNonVersionedFiles)
                }
            }
        }
    }
    finally {
        if ($null -ne $Zip) {
            $Zip.Dispose()
        }
    }
}

function DownloadFile($Source, [ValidateNotNullOrEmpty()][string]$OutPath) {
    if ($Source -notlike "http*") {
        if (![System.IO.Path]::IsPathRooted($Source)) {
            $Source = $(Join-Path -Path $pwd -ChildPath $Source)
        }
        $Source = Get-Absolute-Path $Source
        Say "Copying file from $Source to $OutPath"
        Copy-Item $Source $OutPath
        return
    }
    $Stream = $null
    try {
        $Response = GetHTTPResponse -Uri $Source
        $Stream = $Response.Content.ReadAsStreamAsync().Result
        $File = [System.IO.File]::Create($OutPath)
        $Stream.CopyTo($File)
        $File.Close()
    }
    finally {
        if ($null -ne $Stream) {
            $Stream.Dispose()
        }
    }
}

function SafeRemoveFile($Path) {
    try {
        if (Test-Path $Path) {
            Remove-Item -ErrorAction Stop $Path -Force
            Say-Verbose "The temporary file `"$Path`" was removed."
        }
        else {
            Say-Verbose "The temporary file `"$Path`" does not exist, therefore is not removed."
        }
    } catch {
        Say-Warning "Failed to remove the temporary file: `"$Path`", remove it manually."
    }
}

function Prepend-Sdk-InstallRoot-To-Path([ValidateNotNullOrEmpty()][string]$InstallRoot, [ValidateNotNullOrEmpty()][string]$BinFolderRelativePath) {
    $BinPath = Get-Absolute-Path $(Join-Path -Path $InstallRoot -ChildPath $BinFolderRelativePath)
    if (-Not $NoPath) {
        $SuffixedBinPath = "$BinPath;"
        if (-Not $env:path.Contains($SuffixedBinPath)) {
            Say "Adding to current process PATH: `"$BinPath`". Note: This change will not be visible if PowerShell was run as a child process."
            $env:path = $SuffixedBinPath + $env:path
        } else {
            Say-Verbose "Current process PATH already contains `"$BinPath`""
        }
    }
    else {
        Say "Binaries of dotnet can be found in $BinPath"
    }
}

Say "Note that the intended use of this script is for Continuous Integration (CI) scenarios, where:"
Say " - The SDK needs to be installed without user interaction and without admin rights."
Say " - The SDK installation doesn't need to persist across multiple CI runs."
Say "To set up a development environment or to run apps, use installers rather than this script. Visit https://dotnet.microsoft.com/download to get the installer.`r`n"

$CLIArchitecture = Get-CLIArchitecture-From-Architecture $Architecture
$SpecificVersion = Get-Specific-Version-From-Version -AzureFeed $AzureFeed -Channel $Channel -Version $Version -JSonFile $JSonFile
$DownloadLink, $EffectiveVersion = Get-Download-Link -AzureFeed $AzureFeed -SpecificVersion $SpecificVersion -CLIArchitecture $CLIArchitecture
$LegacyDownloadLink = Get-LegacyDownload-Link -AzureFeed $AzureFeed -SpecificVersion $SpecificVersion -CLIArchitecture $CLIArchitecture
$InstallRoot = Resolve-Installation-Path $InstallDir
Say-Verbose "InstallRoot: $InstallRoot"
$ScriptName = $MyInvocation.MyCommand.Name

if ($DryRun) {
    Say "Payload URLs:"
    Say "Primary named payload URL: $DownloadLink"
    if ($LegacyDownloadLink) {
        Say "Legacy named payload URL: $LegacyDownloadLink"
    }
    $RepeatableCommand = ".\$ScriptName -Version `"$SpecificVersion`" -InstallDir `"$InstallRoot`" -Architecture `"$CLIArchitecture`""
    if ($Runtime -eq "dotnet") {
        $RepeatableCommand = $RepeatableCommand + " -Runtime `"dotnet`""
    }
    elseif ($Runtime -eq "aspnetcore") {
        $RepeatableCommand = $RepeatableCommand + " -Runtime `"aspnetcore`""
    }
    foreach ($key in $MyInvocation.BoundParameters.Keys) {
        if (-not (@("Architecture", "Channel", "DryRun", "InstallDir", "Runtime", "SharedRuntime", "Version") -contains $key)) {
            $RepeatableCommand = $RepeatableCommand + " -$key `"$($MyInvocation.BoundParameters[$key])`""
        }
    }
    Say "Repeatable invocation: $RepeatableCommand"
    if ($SpecificVersion -ne $EffectiveVersion) {
        Say "NOTE: Due to finding a version manifest with this runtime, it would actually install with version '$EffectiveVersion'"
    }
    return
}

if ($Runtime -eq "dotnet") {
    $AssetName = ".NET Core Runtime"
    $DotnetPackageRelativePath = "shared\Microsoft.NETCore.App"
}
elseif ($Runtime -eq "aspnetcore") {
    $AssetName = "ASP.NET Core Runtime"
    $DotnetPackageRelativePath = "shared\Microsoft.AspNetCore.App"
}
elseif ($Runtime -eq "windowsdesktop") {
    $AssetName = ".NET Core Windows Desktop Runtime"
    $DotnetPackageRelativePath = "shared\Microsoft.WindowsDesktop.App"
}
elseif (-not $Runtime) {
    $AssetName = ".NET Core SDK"
    $DotnetPackageRelativePath = "sdk"
}
else {
    throw "Invalid value for `$Runtime"
}

if ($SpecificVersion -ne $EffectiveVersion) {
    Say "Performing installation checks for effective version: $EffectiveVersion"
    $SpecificVersion = $EffectiveVersion
}

$IsAssetInstalled = Is-Dotnet-Package-Installed -InstallRoot $InstallRoot -RelativePathToPackage $DotnetPackageRelativePath -SpecificVersion $SpecificVersion
if ((!$OverrideVersion) -and ($IsAssetInstalled)) {
    Say "$AssetName version $SpecificVersion is already installed."
    Prepend-Sdk-InstallRoot-To-Path -InstallRoot $InstallRoot -BinFolderRelativePath $BinFolderRelativePath
    return
}

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
$InstallDrive = $((Get-Item -ErrorAction Stop $InstallRoot).PSDrive.Name)
$DiskInfo = Get-PSDrive -Name $InstallDrive
if ($DiskInfo.Free / 1MB -le 100) {
    throw "There is not enough disk space on drive ${installDrive}:"
}

$ZipPath = [System.IO.Path]::combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
Say-Verbose "Zip path: $ZipPath"
$DownloadFailed = $false
$PrimaryDownloadStatusCode = 0
$LegacyDownloadStatusCode = 0
$PrimaryDownloadFailedMsg = ""
$LegacyDownloadFailedMsg = ""

Say "Downloading primary link $DownloadLink"
try {
    DownloadFile -Source $DownloadLink -OutPath $ZipPath
}
catch {
    if ($PSItem.Exception.Data.Contains("StatusCode")) {
        $PrimaryDownloadStatusCode = $PSItem.Exception.Data["StatusCode"]
    }
    if ($PSItem.Exception.Data.Contains("ErrorMessage")) {
        $PrimaryDownloadFailedMsg = $PSItem.Exception.Data["ErrorMessage"]
    } else {
        $PrimaryDownloadFailedMsg = $PSItem.Exception.Message
    }
    if ($PrimaryDownloadStatusCode -eq 404) {
        Say "The resource at $DownloadLink is not available."
    } else {
        Say $PSItem.Exception.Message
    }
    SafeRemoveFile -Path $ZipPath
    if ($LegacyDownloadLink) {
        $DownloadLink = $LegacyDownloadLink
        $ZipPath = [System.IO.Path]::combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
        Say-Verbose "Legacy zip path: $ZipPath"
        Say "Downloading legacy link $DownloadLink"
        try {
            DownloadFile -Source $DownloadLink -OutPath $ZipPath
        }
        catch {
            if ($PSItem.Exception.Data.Contains("StatusCode")) {
                $LegacyDownloadStatusCode = $PSItem.Exception.Data["StatusCode"]
            }
            if ($PSItem.Exception.Data.Contains("ErrorMessage")) {
                $LegacyDownloadFailedMsg = $PSItem.Exception.Data["ErrorMessage"]
            } else {
                $LegacyDownloadFailedMsg = $PSItem.Exception.Message
            }
            if ($LegacyDownloadStatusCode -eq 404) {
                Say "The resource at $DownloadLink is not available."
            } else {
                Say $PSItem.Exception.Message
            }
            SafeRemoveFile -Path $ZipPath
            $DownloadFailed = $true
        }
    }
    else {
        $DownloadFailed = $true
    }
}

if ($DownloadFailed) {
    if (($PrimaryDownloadStatusCode -eq 404) -and ((-not $LegacyDownloadLink) -or ($LegacyDownloadStatusCode -eq 404))) {
        throw "Could not find `"$AssetName`" with version = $SpecificVersion`nRefer to: https://aka.ms/dotnet-os-lifecycle for information on .NET Core support"
    } else {
        if ($PrimaryDownloadStatusCode -ne 404) {
            throw "Could not download `"$AssetName`" with version = $SpecificVersion`r`n$PrimaryDownloadFailedMsg"
        }
        if (($LegacyDownloadLink) -and ($LegacyDownloadStatusCode -ne 404)) {
            throw "Could not download `"$AssetName`" with version = $SpecificVersion`r`n$LegacyDownloadFailedMsg"
        }
        throw "Could not download `"$AssetName`" with version = $SpecificVersion"
    }
}

Say "Extracting zip from $DownloadLink"
Extract-Dotnet-Package -ZipPath $ZipPath -OutPath $InstallRoot
$IsAssetInstalled = $false
if ($SpecificVersion -Match "rtm" -or $SpecificVersion -Match "servicing") {
    $ReleaseVersion = $SpecificVersion.Split("-")[0]
    Say-Verbose "Checking installation: version = $ReleaseVersion"
    $IsAssetInstalled = Is-Dotnet-Package-Installed -InstallRoot $InstallRoot -RelativePathToPackage $DotnetPackageRelativePath -SpecificVersion $ReleaseVersion
}
if (!$IsAssetInstalled) {
    Say-Verbose "Checking installation: version = $SpecificVersion"
    $IsAssetInstalled = Is-Dotnet-Package-Installed -InstallRoot $InstallRoot -RelativePathToPackage $DotnetPackageRelativePath -SpecificVersion $SpecificVersion
}
if (!$IsAssetInstalled) {
    Say-Error "Failed to verify the version of installed `"$AssetName`".`nInstallation source: $DownloadLink.`nInstallation location: $InstallRoot.`nReport the bug at https://github.com/dotnet/install-scripts/issues."
    throw "`"$AssetName`" with version = $SpecificVersion failed to install with an unknown error."
}

SafeRemoveFile -Path $ZipPath
Prepend-Sdk-InstallRoot-To-Path -InstallRoot $InstallRoot -BinFolderRelativePath $BinFolderRelativePath

if ($OverrideVersion) {
    Say "Override dotnet Version $Version"
    $path = [Environment]::GetLogicalDrives()
    foreach ($item in $path) {
        if (Test-Path -Path $item) {
            Say $item
            dotnet new globaljson --sdk-version $Version --output $item --force
        }
    }
}

Say "Note that the script does not resolve dependencies during installation."
Say "To check the list of dependencies, go to https://docs.microsoft.com/dotnet/core/install/windows#dependencies"
Say "Installation finished"