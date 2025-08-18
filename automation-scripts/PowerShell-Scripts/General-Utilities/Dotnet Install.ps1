<#
.SYNOPSIS
    We Enhanced Dotnet Install

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
    Installs dotnet cli
.DESCRIPTION
    Installs dotnet cli. If dotnet installation already exists in the given directory
    it will update it only if the requested version differs from the one already installed.
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
.PARAMETER SharedRuntime
    This parameter is obsolete and may be removed in a future version of this script.
    The recommended alternative is '-Runtime dotnet'.
    Installs just the shared runtime bits, not the entire SDK.
.PARAMETER Runtime
    Installs just a shared runtime, not the entire SDK.
    Possible values:
        - dotnet     - the Microsoft.NETCore.App shared runtime
        - aspnetcore - the Microsoft.AspNetCore.App shared runtime
        - windowsdesktop - the Microsoft.WindowsDesktop.App shared runtime
.PARAMETER DryRun
    If set it will not perform installation but instead display what command line to use to consistently install
    currently requested version of dotnet cli. In example if you specify version 'latest' it will display a link
    with specific version so that this command can be used deterministicly in a build script.
    It also displays binaries location if you prefer to install or download it yourself.
.PARAMETER NoPath
    By default this script will set environment variable PATH for the current process to the binaries folder inside installation folder.
    If set it will display binaries location but not set any environment variable.
.PARAMETER Verbose
    Displays diagnostics information.
.PARAMETER AzureFeed
    Default: https://dotnetcli.azureedge.net/dotnet
    This parameter typically is not changed by the user.
    It allows changing the URL for the Azure feed used by this installer.
.PARAMETER UncachedFeed
    This parameter typically is not changed by the user.
    It allows changing the URL for the Uncached feed used by this installer.
.PARAMETER FeedCredential
    Used as a query string to append to the Azure feed.
    It allows changing the URL to use non-public blob storage accounts.
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
.PARAMETER JSonFile
    Determines the SDK version from a user specified global.json file
    Note: global.json must have a value for 'SDK:Version'
.PARAMETER OverrideVersion
    Install and Override dotnet version anyway

[cmdletbinding()]
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
   [string]$WEChannel="LTS" ,
   [string]$WEVersion="Latest" ,
   [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEJSonFile,
   [string]$WEInstallDir="<auto>" ,
   [string]$WEArchitecture="<auto>" ,
   [ValidateSet("dotnet" , "aspnetcore" , "windowsdesktop" , IgnoreCase = $false)]
   [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERuntime,
   [Obsolete("This parameter may be removed in a future version of this script. The recommended alternative is '-Runtime dotnet'." )]
   [switch]$WESharedRuntime,
   [switch]$WEDryRun,
   [switch]$WENoPath,
   [string]$WEAzureFeed="https://dotnetcli.azureedge.net/dotnet" ,
   [string]$WEUncachedFeed="https://dotnetcli.blob.core.windows.net/dotnet" ,
   [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEFeedCredential,
   [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEProxyAddress,
   [switch]$WEProxyUseDefaultCredentials,
   [string[]]$WEProxyBypassList=@(),
   [switch]$WESkipNonVersionedFiles,
   [switch]$WENoCdn,
   [bool]$WEOverrideVersion = $false
)

Set-StrictMode -Version Latest
$WEErrorActionPreference="Stop"
$WEProgressPreference=" SilentlyContinue"

if ($WENoCdn) {
    $WEAzureFeed = $WEUncachedFeed
}

$WEBinFolderRelativePath=""

if ($WESharedRuntime -and (-not $WERuntime)) {
    $WERuntime = " dotnet"
}


$WEVersionRegEx=" /\d+\.\d+[^/]+/"
$WEOverrideNonVersionedFiles = !$WESkipNonVersionedFiles

function WE-Say($str) {
    try {
        Write-WELog " dotnet-install: $str" " INFO"
    }
    catch {
        # Some platforms cannot utilize Write-Host (Azure Functions, for instance). Fall back to Write-Output
        Write-Output " dotnet-install: $str"
    }
}

function WE-Say-Warning($str) {
    try {
        Write-Warning " dotnet-install: $str"
    }
    catch {
        # Some platforms cannot utilize Write-Warning (Azure Functions, for instance). Fall back to Write-Output
        Write-Output " dotnet-install: Warning: $str"
    }
}


function WE-Say-Error($str) {
    try {
        # Write-Error is quite oververbose for the purpose of the function, let's write one line with error style settings.
        $WEHost.UI.WriteErrorLine(" dotnet-install: $str")
    }
    catch {
        Write-Output " dotnet-install: Error: $str"
    }
}

function WE-Say-Verbose($str) {
    try {
        Write-Verbose " dotnet-install: $str"
    }
    catch {
        # Some platforms cannot utilize Write-Verbose (Azure Functions, for instance). Fall back to Write-Output
        Write-Output " dotnet-install: $str"
    }
}

function WE-Say-Invocation($WEInvocation) {
   ;  $command = $WEInvocation.MyCommand;
    $args = (($WEInvocation.BoundParameters.Keys | foreach { " -$_ `"$($WEInvocation.BoundParameters[$_])`"" }) -join " " )
    Say-Verbose "$command $args"
}

function WE-Invoke-With-Retry([ScriptBlock]$WEScriptBlock, [int]$WEMaxAttempts = 3, [int]$WESecondsBetweenAttempts = 1) {
    $WEAttempts = 0

    while ($true) {
        try {
            return & $WEScriptBlock
        }
        catch {
            $WEAttempts++
            if ($WEAttempts -lt $WEMaxAttempts) {
                Start-Sleep $WESecondsBetweenAttempts
            }
            else {
                throw
            }
        }
    }
}

function WE-Get-Machine-Architecture() {
    Say-Invocation $WEMyInvocation

    # On PS x86, PROCESSOR_ARCHITECTURE reports x86 even on x64 systems.
    # To get the correct architecture, we need to use PROCESSOR_ARCHITEW6432.
    # PS x64 doesn't define this, so we fall back to PROCESSOR_ARCHITECTURE.
    # Possible values: amd64, x64, x86, arm64, arm

    if( $WEENV:PROCESSOR_ARCHITEW6432 -ne $null )
    {    
        return $WEENV:PROCESSOR_ARCHITEW6432
    }

    return $WEENV:PROCESSOR_ARCHITECTURE
}

function WE-Get-CLIArchitecture-From-Architecture([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEArchitecture) {
    Say-Invocation $WEMyInvocation

    switch ($WEArchitecture.ToLower()) {
        { $_ -eq " <auto>" } { return Get-CLIArchitecture-From-Architecture $(Get-Machine-Architecture) }
        { ($_ -eq " amd64") -or ($_ -eq " x64") } { return " x64" }
        { $_ -eq " x86" } { return " x86" }
        { $_ -eq " arm" } { return " arm" }
        { $_ -eq " arm64" } { return " arm64" }
        default { throw " Architecture '$WEArchitecture' not supported. If you think this is a bug, report it at https://github.com/dotnet/install-scripts/issues" }
    }
}


function WE-Get-Version-Info-From-Version-Text([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVersionText) {
    Say-Invocation $WEMyInvocation

    $WEData = -split $WEVersionText

    $WEVersionInfo = @{
        CommitHash = $(if ($WEData.Count -gt 1) { $WEData[0] })
        Version = $WEData[-1] # last line is always the version number.
    }
    return $WEVersionInfo
}

function WE-Load-Assembly([string] $WEAssembly) {
    try {
        Add-Type -Assembly $WEAssembly | Out-Null
    }
    catch {
        # On Nano Server, PowerShell Core Edition is used.  Add-Type is unable to resolve base class assemblies because they are not GAC'd.
        # Loading the base class assemblies is not unnecessary as the types will automatically get resolved.
    }
}

function WE-GetHTTPResponse([Uri] $WEUri)
{
    Invoke-With-Retry(
    {

        $WEHttpClient = $null

        try {
            # HttpClient is used vs Invoke-WebRequest in order to support Nano Server which doesn't support the Invoke-WebRequest cmdlet.
            Load-Assembly -Assembly System.Net.Http

            if(-not $WEProxyAddress) {
                try {
                    # Despite no proxy being explicitly specified, we may still be behind a default proxy
                   ;  $WEDefaultProxy = [System.Net.WebRequest]::DefaultWebProxy;
                    if($WEDefaultProxy -and (-not $WEDefaultProxy.IsBypassed($WEUri))) {
                        $WEProxyAddress = $WEDefaultProxy.GetProxy($WEUri).OriginalString
                        $WEProxyUseDefaultCredentials = $true
                    }
                } catch {
                    # Eat the exception and move forward as the above code is an attempt
                    #    at resolving the DefaultProxy that may not have been a problem.
                    $WEProxyAddress = $null
                    Say-Verbose(" Exception ignored: $_.Exception.Message - moving forward...")
                }
            }

            if($WEProxyAddress) {
               ;  $WEHttpClientHandler = New-Object System.Net.Http.HttpClientHandler
                $WEHttpClientHandler.Proxy =  New-Object System.Net.WebProxy -Property @{
                    Address=$WEProxyAddress;
                    UseDefaultCredentials=$WEProxyUseDefaultCredentials;
                    BypassList = $WEProxyBypassList;
                }
                $WEHttpClient = New-Object System.Net.Http.HttpClient -ArgumentList $WEHttpClientHandler
            }
            else {

                $WEHttpClient = New-Object System.Net.Http.HttpClient
            }
            # Default timeout for HttpClient is 100s.  For a 50 MB download this assumes 500 KB/s average, any less will time out
            # 20 minutes allows it to work over much slower connections.
            $WEHttpClient.Timeout = New-TimeSpan -Minutes 20
           ;  $WETask = $WEHttpClient.GetAsync(" ${Uri}${FeedCredential}").ConfigureAwait(" false");
            $WEResponse = $WETask.GetAwaiter().GetResult();

            if (($null -eq $WEResponse) -or (-not ($WEResponse.IsSuccessStatusCode))) {
                # The feed credential is potentially sensitive info. Do not log FeedCredential to console output.
                $WEDownloadException = [System.Exception] " Unable to download $WEUri."

                if ($null -ne $WEResponse) {
                    $WEDownloadException.Data[" StatusCode"] = [int] $WEResponse.StatusCode
                    $WEDownloadException.Data[" ErrorMessage"] = " Unable to download $WEUri. Returned HTTP status code: " + $WEDownloadException.Data[" StatusCode"]
                }

                throw $WEDownloadException
            }

            return $WEResponse
        }
        catch [System.Net.Http.HttpRequestException] {
            $WEDownloadException = [System.Exception] " Unable to download $WEUri."

            # Pick up the exception message and inner exceptions' messages if they exist
            $WECurrentException = $WEPSItem.Exception
            $WEErrorMsg = $WECurrentException.Message + " `r`n"
            while ($WECurrentException.InnerException) {
              $WECurrentException = $WECurrentException.InnerException
              $WEErrorMsg = $WEErrorMsg + $WECurrentException.Message + " `r`n"
            }

            # Check if there is an issue concerning TLS.
            if ($WEErrorMsg -like " *SSL/TLS*") {
                $WEErrorMsg = $WEErrorMsg + " Ensure that TLS 1.2 or higher is enabled to use this script.`r`n"
            }

            $WEDownloadException.Data[" ErrorMessage"] = $WEErrorMsg
            throw $WEDownloadException
        }
        finally {
             if ($WEHttpClient -ne $null) {
                $WEHttpClient.Dispose()
            }
        }
    })
}

function WE-Get-Latest-Version-Info([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAzureFeed, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEChannel) {
    Say-Invocation $WEMyInvocation

    $WEVersionFileUrl = $null
    if ($WERuntime -eq " dotnet") {
        $WEVersionFileUrl = " $WEUncachedFeed/Runtime/$WEChannel/latest.version"
    }
    elseif ($WERuntime -eq " aspnetcore") {
        $WEVersionFileUrl = " $WEUncachedFeed/aspnetcore/Runtime/$WEChannel/latest.version"
    }
    elseif ($WERuntime -eq " windowsdesktop") {
        $WEVersionFileUrl = " $WEUncachedFeed/WindowsDesktop/$WEChannel/latest.version"
    }
    elseif (-not $WERuntime) {
        $WEVersionFileUrl = " $WEUncachedFeed/Sdk/$WEChannel/latest.version"
    }
    else {
        throw " Invalid value for `$WERuntime"
    }
    try {
        $WEResponse = GetHTTPResponse -Uri $WEVersionFileUrl
    }
    catch {
        Say-Error " Could not resolve version information."
        throw
    }
    $WEStringContent = $WEResponse.Content.ReadAsStringAsync().Result

    switch ($WEResponse.Content.Headers.ContentType) {
        { ($_ -eq " application/octet-stream") } { $WEVersionText = $WEStringContent }
        { ($_ -eq " text/plain") } {;  $WEVersionText = $WEStringContent }
        { ($_ -eq " text/plain; charset=UTF-8") } { $WEVersionText = $WEStringContent }
        default { throw " ``$WEResponse.Content.Headers.ContentType`` is an unknown .version file content type." }
    }

    $WEVersionInfo = Get-Version-Info-From-Version-Text $WEVersionText

    return $WEVersionInfo
}

function WE-Parse-Jsonfile-For-Version([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEJSonFile) {
    Say-Invocation $WEMyInvocation

    If (-Not (Test-Path $WEJSonFile)) {
        throw " Unable to find '$WEJSonFile'"
    }
    try {
        $WEJSonContent = Get-Content($WEJSonFile) -Raw | ConvertFrom-Json | Select-Object -expand " sdk" -ErrorAction SilentlyContinue
    }
    catch {
        Say-Error " Json file unreadable: '$WEJSonFile'"
        throw
    }
    if ($WEJSonContent) {
        try {
            $WEJSonContent.PSObject.Properties | ForEach-Object {
                $WEPropertyName = $_.Name
                if ($WEPropertyName -eq " version") {
                    $WEVersion = $_.Value
                    Say-Verbose " Version = $WEVersion"
                }
            }
        }
        catch {
            Say-Error " Unable to parse the SDK node in '$WEJSonFile'"
            throw
        }
    }
    else {
        throw " Unable to find the SDK node in '$WEJSonFile'"
    }
    If ($WEVersion -eq $null) {
        throw " Unable to find the SDK:version node in '$WEJSonFile'"
    }
    return $WEVersion
}

function WE-Get-Specific-Version-From-Version([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAzureFeed, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEChannel, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVersion, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEJSonFile) {
    Say-Invocation $WEMyInvocation

    if (-not $WEJSonFile) {
        if ($WEVersion.ToLower() -eq " latest") {
            $WELatestVersionInfo = Get-Latest-Version-Info -AzureFeed $WEAzureFeed -Channel $WEChannel
            return $WELatestVersionInfo.Version
        }
        else {
            return $WEVersion 
        }
    }
    else {
        return Parse-Jsonfile-For-Version $WEJSonFile
    }
}

function WE-Get-Download-Link([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAzureFeed, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESpecificVersion, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WECLIArchitecture) {
    Say-Invocation $WEMyInvocation

    # If anything fails in this lookup it will default to $WESpecificVersion
    $WESpecificProductVersion = Get-Product-Version -AzureFeed $WEAzureFeed -SpecificVersion $WESpecificVersion

    if ($WERuntime -eq " dotnet") {
        $WEPayloadURL = " $WEAzureFeed/Runtime/$WESpecificVersion/dotnet-runtime-$WESpecificProductVersion-win-$WECLIArchitecture.zip"
    }
    elseif ($WERuntime -eq " aspnetcore") {
        $WEPayloadURL = " $WEAzureFeed/aspnetcore/Runtime/$WESpecificVersion/aspnetcore-runtime-$WESpecificProductVersion-win-$WECLIArchitecture.zip"
    }
    elseif ($WERuntime -eq " windowsdesktop") {
        # The windows desktop runtime is part of the core runtime layout prior to 5.0
        $WEPayloadURL = " $WEAzureFeed/Runtime/$WESpecificVersion/windowsdesktop-runtime-$WESpecificProductVersion-win-$WECLIArchitecture.zip"
        if ($WESpecificVersion -match '^(\d+)\.(.*)$')
        {
            $majorVersion = [int]$WEMatches[1]
            if ($majorVersion -ge 5)
            {
                $WEPayloadURL = " $WEAzureFeed/WindowsDesktop/$WESpecificVersion/windowsdesktop-runtime-$WESpecificProductVersion-win-$WECLIArchitecture.zip"
            }
        }
    }
    elseif (-not $WERuntime) {
        $WEPayloadURL = " $WEAzureFeed/Sdk/$WESpecificVersion/dotnet-sdk-$WESpecificProductVersion-win-$WECLIArchitecture.zip"
    }
    else {
        throw " Invalid value for `$WERuntime"
    }

    Say-Verbose " Constructed primary named payload URL: $WEPayloadURL"

    return $WEPayloadURL, $WESpecificProductVersion
}

function WE-Get-LegacyDownload-Link([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAzureFeed, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESpecificVersion, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WECLIArchitecture) {
    Say-Invocation $WEMyInvocation

    if (-not $WERuntime) {
        $WEPayloadURL = " $WEAzureFeed/Sdk/$WESpecificVersion/dotnet-dev-win-$WECLIArchitecture.$WESpecificVersion.zip"
    }
    elseif ($WERuntime -eq " dotnet") {
        $WEPayloadURL = " $WEAzureFeed/Runtime/$WESpecificVersion/dotnet-win-$WECLIArchitecture.$WESpecificVersion.zip"
    }
    else {
        return $null
    }

    Say-Verbose " Constructed legacy named payload URL: $WEPayloadURL"

    return $WEPayloadURL
}

function WE-Get-Product-Version([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAzureFeed, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESpecificVersion) {
    Say-Invocation $WEMyInvocation

    if ($WERuntime -eq " dotnet") {
        $WEProductVersionTxtURL = " $WEAzureFeed/Runtime/$WESpecificVersion/productVersion.txt"
    }
    elseif ($WERuntime -eq " aspnetcore") {
        $WEProductVersionTxtURL = " $WEAzureFeed/aspnetcore/Runtime/$WESpecificVersion/productVersion.txt"
    }
    elseif ($WERuntime -eq " windowsdesktop") {
        # The windows desktop runtime is part of the core runtime layout prior to 5.0
        $WEProductVersionTxtURL = " $WEAzureFeed/Runtime/$WESpecificVersion/productVersion.txt"
        if ($WESpecificVersion -match '^(\d+)\.(.*)')
        {
            $majorVersion = [int]$WEMatches[1]
            if ($majorVersion -ge 5)
            {
                $WEProductVersionTxtURL = " $WEAzureFeed/WindowsDesktop/$WESpecificVersion/productVersion.txt"
            }
        }
    }
    elseif (-not $WERuntime) {
        $WEProductVersionTxtURL = " $WEAzureFeed/Sdk/$WESpecificVersion/productVersion.txt"
    }
    else {
        throw " Invalid value '$WERuntime' specified for `$WERuntime"
    }

    Say-Verbose " Checking for existence of $WEProductVersionTxtURL"

    try {
        $productVersionResponse = GetHTTPResponse($productVersionTxtUrl)

        if ($productVersionResponse.StatusCode -eq 200) {
            $productVersion = $productVersionResponse.Content.ReadAsStringAsync().Result.Trim()
            if ($productVersion -ne $WESpecificVersion)
            {
                Say " Using alternate version $productVersion found in $WEProductVersionTxtURL"
            }

            return $productVersion
        }
        else {
            Say-Verbose " Got StatusCode $($productVersionResponse.StatusCode) trying to get productVersion.txt at $productVersionTxtUrl, so using default value of $WESpecificVersion"
            $productVersion = $WESpecificVersion
        }
    } catch {
        Say-Verbose " Could not read productVersion.txt at $productVersionTxtUrl, so using default value of $WESpecificVersion (Exception: '$($_.Exception.Message)' )"
        $productVersion = $WESpecificVersion
    }

    return $productVersion
}

function WE-Get-User-Share-Path() {
    Say-Invocation $WEMyInvocation

    $WEInstallRoot = $env:DOTNET_INSTALL_DIR
    if (!$WEInstallRoot) {
        $WEInstallRoot = " $env:LocalAppData\Microsoft\dotnet"
    }
    return $WEInstallRoot
}

function WE-Resolve-Installation-Path([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEInstallDir) {
    Say-Invocation $WEMyInvocation

    if ($WEInstallDir -eq " <auto>") {
        return Get-User-Share-Path
    }
    return $WEInstallDir
}

function WE-Is-Dotnet-Package-Installed([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEInstallRoot, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERelativePathToPackage, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESpecificVersion) {
    Say-Invocation $WEMyInvocation

    $WEDotnetPackagePath = Join-Path -Path $WEInstallRoot -ChildPath $WERelativePathToPackage | Join-Path -ChildPath $WESpecificVersion
    Say-Verbose " Is-Dotnet-Package-Installed: DotnetPackagePath=$WEDotnetPackagePath"
    return Test-Path $WEDotnetPackagePath -PathType Container
}

function WE-Get-Absolute-Path([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERelativeOrAbsolutePath) {
    # Too much spam
    # Say-Invocation $WEMyInvocation

    return $WEExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($WERelativeOrAbsolutePath)
}

function WE-Get-Path-Prefix-With-Version($path) {
    $match = [regex]::match($path, $WEVersionRegEx)
    if ($match.Success) {
        return $entry.FullName.Substring(0, $match.Index + $match.Length)
    }

    return $null
}

function WE-Get-List-Of-Directories-And-Versions-To-Unpack-From-Dotnet-Package([System.IO.Compression.ZipArchive]$WEZip, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOutPath) {
    Say-Invocation $WEMyInvocation

    $ret = @()
    foreach ($entry in $WEZip.Entries) {
        $dir = Get-Path-Prefix-With-Version $entry.FullName
        if ($dir -ne $null) {
            $path = Get-Absolute-Path $(Join-Path -Path $WEOutPath -ChildPath $dir)
            if (-Not (Test-Path $path -PathType Container)) {
                $ret = $ret + $dir
            }
        }
    }

    $ret = $ret | Sort-Object | Get-Unique

   ;  $values = ($ret | foreach { " $_" }) -join " ;"
    Say-Verbose " Directories to unpack: $values"

    return $ret
}


function WE-Extract-Dotnet-Package([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEZipPath, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOutPath) {
    Say-Invocation $WEMyInvocation

    Load-Assembly -Assembly System.IO.Compression.FileSystem
    Set-Variable -Name Zip
    try {
        $WEZip = [System.IO.Compression.ZipFile]::OpenRead($WEZipPath)

        $WEDirectoriesToUnpack = Get-List-Of-Directories-And-Versions-To-Unpack-From-Dotnet-Package -Zip $WEZip -OutPath $WEOutPath

        foreach ($entry in $WEZip.Entries) {
            $WEPathWithVersion = Get-Path-Prefix-With-Version $entry.FullName
            if (($WEPathWithVersion -eq $null) -Or ($WEDirectoriesToUnpack -contains $WEPathWithVersion)) {
                $WEDestinationPath = Get-Absolute-Path $(Join-Path -Path $WEOutPath -ChildPath $entry.FullName)
                $WEDestinationDir = Split-Path -Parent $WEDestinationPath
                $WEOverrideFiles=$WEOverrideNonVersionedFiles -Or (-Not (Test-Path $WEDestinationPath))
                if ((-Not $WEDestinationPath.EndsWith(" \")) -And $WEOverrideFiles) {
                    New-Item -ItemType Directory -Force -Path $WEDestinationDir | Out-Null
                    [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $WEDestinationPath, $WEOverrideNonVersionedFiles)
                }
            }
        }
    }
    finally {
        if ($WEZip -ne $null) {
            $WEZip.Dispose()
        }
    }
}

function WE-DownloadFile($WESource, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEOutPath) {
    if ($WESource -notlike " http*") {
        #  Using System.IO.Path.GetFullPath to get the current directory
        #    does not work in this context - $pwd gives the current directory
        if (![System.IO.Path]::IsPathRooted($WESource)) {
            $WESource = $(Join-Path -Path $pwd -ChildPath $WESource)
        }
        $WESource = Get-Absolute-Path $WESource
        Say " Copying file from $WESource to $WEOutPath"
        Copy-Item $WESource $WEOutPath
        return
    }

    $WEStream = $null

    try {
        $WEResponse = GetHTTPResponse -Uri $WESource
        $WEStream = $WEResponse.Content.ReadAsStreamAsync().Result
        $WEFile = [System.IO.File]::Create($WEOutPath)
        $WEStream.CopyTo($WEFile)
        $WEFile.Close()
    }
    finally {
        if ($WEStream -ne $null) {
            $WEStream.Dispose()
        }
    }
}

function WE-SafeRemoveFile($WEPath) {
    try {
        if (Test-Path $WEPath) {
            Remove-Item $WEPath -Force
            Say-Verbose " The temporary file `"$WEPath`" was removed."
        }
        else
        {
            Say-Verbose " The temporary file `"$WEPath`" does not exist, therefore is not removed."
        }
    }
    catch
    {
        Say-Warning " Failed to remove the temporary file: `"$WEPath`" , remove it manually."
    }
}

function WE-Prepend-Sdk-InstallRoot-To-Path([Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEInstallRoot, [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEBinFolderRelativePath) {
    $WEBinPath = Get-Absolute-Path $(Join-Path -Path $WEInstallRoot -ChildPath $WEBinFolderRelativePath)
    if (-Not $WENoPath) {
       ;  $WESuffixedBinPath = " $WEBinPath;"
        if (-Not $env:path.Contains($WESuffixedBinPath)) {
            Say " Adding to current process PATH: `"$WEBinPath`" . Note: This change will not be visible if PowerShell was run as a child process."
            $env:path = $WESuffixedBinPath + $env:path
        } else {
            Say-Verbose " Current process PATH already contains `"$WEBinPath`""
        }
    }
    else {
        Say " Binaries of dotnet can be found in $WEBinPath"
    }
}

Say " Note that the intended use of this script is for Continuous Integration (CI) scenarios, where:"
Say " - The SDK needs to be installed without user interaction and without admin rights."
Say " - The SDK installation doesn't need to persist across multiple CI runs."
Say " To set up a development environment or to run apps, use installers rather than this script. Visit https://dotnet.microsoft.com/download to get the installer.`r`n"

$WECLIArchitecture = Get-CLIArchitecture-From-Architecture $WEArchitecture
$WESpecificVersion = Get-Specific-Version-From-Version -AzureFeed $WEAzureFeed -Channel $WEChannel -Version $WEVersion -JSonFile $WEJSonFile
$WEDownloadLink, $WEEffectiveVersion = Get-Download-Link -AzureFeed $WEAzureFeed -SpecificVersion $WESpecificVersion -CLIArchitecture $WECLIArchitecture
$WELegacyDownloadLink = Get-LegacyDownload-Link -AzureFeed $WEAzureFeed -SpecificVersion $WESpecificVersion -CLIArchitecture $WECLIArchitecture

$WEInstallRoot = Resolve-Installation-Path $WEInstallDir
Say-Verbose " InstallRoot: $WEInstallRoot"
$WEScriptName = $WEMyInvocation.MyCommand.Name

if ($WEDryRun) {
    Say " Payload URLs:"
    Say " Primary named payload URL: $WEDownloadLink"
    if ($WELegacyDownloadLink) {
        Say " Legacy named payload URL: $WELegacyDownloadLink"
    }
    $WERepeatableCommand = " .\$WEScriptName -Version `"$WESpecificVersion`" -InstallDir `" $WEInstallRoot`" -Architecture `" $WECLIArchitecture`""
    if ($WERuntime -eq " dotnet") {
       $WERepeatableCommand = $WERepeatableCommand + " -Runtime `" dotnet`""
    }
    elseif ($WERuntime -eq " aspnetcore") {
       $WERepeatableCommand = $WERepeatableCommand + " -Runtime `" aspnetcore`""
    }
    foreach ($key in $WEMyInvocation.BoundParameters.Keys) {
        if (-not (@(" Architecture"," Channel"," DryRun"," InstallDir"," Runtime"," SharedRuntime"," Version") -contains $key)) {
            $WERepeatableCommand = $WERepeatableCommand + " -$key `" $($WEMyInvocation.BoundParameters[$key])`""
        }
    }
    Say " Repeatable invocation: $WERepeatableCommand"
    if ($WESpecificVersion -ne $WEEffectiveVersion)
    {
        Say " NOTE: Due to finding a version manifest with this runtime, it would actually install with version '$WEEffectiveVersion'"
    }

    return
}

if ($WERuntime -eq " dotnet") {
    $assetName = " .NET Core Runtime"
    $dotnetPackageRelativePath = " shared\Microsoft.NETCore.App"
}
elseif ($WERuntime -eq " aspnetcore") {
    $assetName = " ASP.NET Core Runtime"
    $dotnetPackageRelativePath = " shared\Microsoft.AspNetCore.App"
}
elseif ($WERuntime -eq " windowsdesktop") {
    $assetName = " .NET Core Windows Desktop Runtime"
    $dotnetPackageRelativePath = " shared\Microsoft.WindowsDesktop.App"
}
elseif (-not $WERuntime) {
    $assetName = " .NET Core SDK"
    $dotnetPackageRelativePath = " sdk"
}
else {
    throw " Invalid value for `$WERuntime"
}

if ($WESpecificVersion -ne $WEEffectiveVersion)
{
   Say " Performing installation checks for effective version: $WEEffectiveVersion"
   $WESpecificVersion = $WEEffectiveVersion
}


$isAssetInstalled = Is-Dotnet-Package-Installed -InstallRoot $WEInstallRoot -RelativePathToPackage $dotnetPackageRelativePath -SpecificVersion $WESpecificVersion
if ((!$WEOverrideVersion) -and ($isAssetInstalled)) {
    Say " $assetName version $WESpecificVersion is already installed."
    Prepend-Sdk-InstallRoot-To-Path -InstallRoot $WEInstallRoot -BinFolderRelativePath $WEBinFolderRelativePath
    return
}

New-Item -ItemType Directory -Force -Path $WEInstallRoot | Out-Null
; 
$installDrive = $((Get-Item $WEInstallRoot).PSDrive.Name);
$diskInfo = Get-PSDrive -Name $installDrive
if ($diskInfo.Free / 1MB -le 100) {
    throw " There is not enough disk space on drive ${installDrive}:"
}

$WEZipPath = [System.IO.Path]::combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
Say-Verbose " Zip path: $WEZipPath"

$WEDownloadFailed = $false

$WEPrimaryDownloadStatusCode = 0
$WELegacyDownloadStatusCode = 0

$WEPrimaryDownloadFailedMsg = ""
$WELegacyDownloadFailedMsg = ""

Say " Downloading primary link $WEDownloadLink"
try {
    DownloadFile -Source $WEDownloadLink -OutPath $WEZipPath
}
catch {
    if ($WEPSItem.Exception.Data.Contains(" StatusCode")) {
        $WEPrimaryDownloadStatusCode = $WEPSItem.Exception.Data[" StatusCode"]
    }

    if ($WEPSItem.Exception.Data.Contains(" ErrorMessage")) {
        $WEPrimaryDownloadFailedMsg = $WEPSItem.Exception.Data[" ErrorMessage"]
    } else {
        $WEPrimaryDownloadFailedMsg = $WEPSItem.Exception.Message
    }

    if ($WEPrimaryDownloadStatusCode -eq 404) {
        Say " The resource at $WEDownloadLink is not available."
    } else {
        Say $WEPSItem.Exception.Message
    }

    SafeRemoveFile -Path $WEZipPath

    if ($WELegacyDownloadLink) {
        $WEDownloadLink = $WELegacyDownloadLink
        $WEZipPath = [System.IO.Path]::combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
        Say-Verbose " Legacy zip path: $WEZipPath"
        Say " Downloading legacy link $WEDownloadLink"
        try {
            DownloadFile -Source $WEDownloadLink -OutPath $WEZipPath
        }
        catch {
            if ($WEPSItem.Exception.Data.Contains(" StatusCode")) {
                $WELegacyDownloadStatusCode = $WEPSItem.Exception.Data[" StatusCode"]
            }

            if ($WEPSItem.Exception.Data.Contains(" ErrorMessage")) {
                $WELegacyDownloadFailedMsg = $WEPSItem.Exception.Data[" ErrorMessage"]
            } else {
                $WELegacyDownloadFailedMsg = $WEPSItem.Exception.Message
            }

            if ($WELegacyDownloadStatusCode -eq 404) {
                Say " The resource at $WEDownloadLink is not available."
            } else {
                Say $WEPSItem.Exception.Message
            }

            SafeRemoveFile -Path $WEZipPath
            $WEDownloadFailed = $true
        }
    }
    else {
        $WEDownloadFailed = $true
    }
}

if ($WEDownloadFailed) {
    if (($WEPrimaryDownloadStatusCode -eq 404) -and ((-not $WELegacyDownloadLink) -or ($WELegacyDownloadStatusCode -eq 404))) {
        throw " Could not find `"$assetName`" with version = $WESpecificVersion`nRefer to: https://aka.ms/dotnet-os-lifecycle for information on .NET Core support"
    } else {
        # 404-NotFound is an expected response if it goes from only one of the links, do not show that error.
        # If primary path is available (not 404-NotFound) then show the primary error else show the legacy error.
        if ($WEPrimaryDownloadStatusCode -ne 404) {
            throw " Could not download `"$assetName`" with version = $WESpecificVersion`r`n$WEPrimaryDownloadFailedMsg"
        }
        if (($WELegacyDownloadLink) -and ($WELegacyDownloadStatusCode -ne 404)) {
            throw " Could not download `"$assetName`" with version = $WESpecificVersion`r`n$WELegacyDownloadFailedMsg"
        }
        throw " Could not download `"$assetName`" with version = $WESpecificVersion"
    }
}

Say " Extracting zip from $WEDownloadLink"
Extract-Dotnet-Package -ZipPath $WEZipPath -OutPath $WEInstallRoot


$isAssetInstalled = $false


if ($WESpecificVersion -Match " rtm" -or $WESpecificVersion -Match " servicing") {
    $WEReleaseVersion = $WESpecificVersion.Split(" -")[0]
    Say-Verbose " Checking installation: version = $WEReleaseVersion"
    $isAssetInstalled = Is-Dotnet-Package-Installed -InstallRoot $WEInstallRoot -RelativePathToPackage $dotnetPackageRelativePath -SpecificVersion $WEReleaseVersion
}


if (!$isAssetInstalled) {
    Say-Verbose " Checking installation: version = $WESpecificVersion"
    $isAssetInstalled = Is-Dotnet-Package-Installed -InstallRoot $WEInstallRoot -RelativePathToPackage $dotnetPackageRelativePath -SpecificVersion $WESpecificVersion
}


if (!$isAssetInstalled) {
    Say-Error " Failed to verify the version of installed `"$assetName`" .`nInstallation source: $WEDownloadLink.`nInstallation location: $WEInstallRoot.`nReport the bug at https://github.com/dotnet/install-scripts/issues."
    throw " `"$assetName`" with version = $WESpecificVersion failed to install with an unknown error."
}

SafeRemoveFile -Path $WEZipPath

Prepend-Sdk-InstallRoot-To-Path -InstallRoot $WEInstallRoot -BinFolderRelativePath $WEBinFolderRelativePath

if($WEOverrideVersion){
  Say " Override dotnet Version $WEVersion"
 ;  $path = [Environment]::GetLogicalDrives()

  foreach ($item in $path)
  {
    if (Test-Path -Path $item ){
      Say $item 
      dotnet new globaljson --sdk-version $WEVersion --output $item --force 
    }
  }
}


Say " Note that the script does not resolve dependencies during installation."
Say " To check the list of dependencies, go to https://docs.microsoft.com/dotnet/core/install/windows#dependencies"
Say " Installation finished"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================