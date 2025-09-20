<#
.SYNOPSIS
    Windows Install Visualstudiocode Extension

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Installs a Visual Studio Code extension
    Installs the provided Visual Studio Code extension by id or name to the given installation of VS Code
.PARAMETER ExtensionId
    Visual Studio Code Marketplace identifier for the extension. Cannot be defined if ExtensionName or ExtensionVsixPath is defined
.PARAMETER ExtensionName
    Visual Studio Code Marketplace name identifier for the extension. Cannot be defined if ExtensionId or ExtensionVsixPath is defined
.PARAMETER ExtensionVsixPath
    File path or URL to the extension VSIX file. Cannot be defined if ExtensionName or ExtensionId is defined
.PARAMETER ExtensionVersion
    Version of extension to install, or latest if unspecified. Only applicable when ExtensionName or ExtensionId is set.
.PARAMETER VisualStudioCodeInstallPath
    The location of the Visual Studio Code install (optional, defaults to the global install location)
.PARAMETER EmitAllInstalledExtensions
    After the install operation, emit all extensions installed globally and their versions (default: false)
    Sample Bicep snippet for using the artifact:
    {
      name: 'windows-install-visualstudiocode-extension'
      parameters: {
        ExtensionName: 'GitHub.copilot'
      }
    }
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)] [String] $ExtensionId,
    [Parameter(Mandatory = $false)] [String] $ExtensionName,
    [Parameter(Mandatory = $false)] [String] $ExtensionVsixPath,
    [Parameter(Mandatory = $false)] [String] $ExtensionVersion,
    [Parameter(Mandatory = $false)] [String] $VisualStudioCodeInstallPath,
    [Parameter(Mandatory = $false)] [bool] $InstallInsiders = $false,
    [Parameter(Mandatory = $false)] [bool] $EmitAllInstalledExtensions = $false
)
Set-StrictMode -Version Latest
[OutputType([bool])]
 (
    [Parameter(Mandatory = $false)] [String] $extensionId = $null,
    [Parameter(Mandatory = $false)] [String] $extensionName = $null,
    [Parameter(Mandatory = $false)] [String] $extensionVsixPath = $null,
    [Parameter(Mandatory = $false)] [String] $extensionVersion = $null) {
    $paramCount = 0
    if (-not [string]::IsNullOrWhiteSpace($extensionId)) { $paramCount++ }
    if (-not [string]::IsNullOrWhiteSpace($extensionName)) { $paramCount++ }
    if (-not [string]::IsNullOrWhiteSpace($extensionVsixPath)) { $paramCount++ }
    if ($paramCount -ne 1) {
        Write-Error "You must provide either an ExtensionId, ExtensionName, or ExtensionVsixPath (but not more than one). You can find the ExtensionName in the URL of the Marketplace extension. Example: If the extension URL is https://marketplace.visualstudio.com/items?itemName=GitHub.copilot then you would use `GitHub.copilot`."
    }
    if ((-not [string]::IsNullOrWhiteSpace($extensionVsixPath)) -and (-not [string]::IsNullOrWhiteSpace($extensionVersion))) {
        Write-Error "You cannot specify an ExtensionVersion when installing from a direct VSIX URL or path."
    }
}
function Import-ExtensionToLocalPath (
    [Parameter(Mandatory = $false)] [String] $extensionId = $null,
    [Parameter(Mandatory = $false)] [String] $extensionName = $null,
    [Parameter(Mandatory = $false)] [String] $extensionVsixPath = $null,
    [Parameter(Mandatory = $false)] [String] $extensionVersion = $null,
    [Parameter(Mandatory = $true)] [String] $downloadLocation,
    [Parameter(Mandatory = $false)] [Bool] $downloadPreRelease) {
    # Process direct URLs and local path references to extensions
    if (-not [string]::IsNullOrWhiteSpace($extensionVsixPath)) {
        Write-Host "ExtensionVsixPath: $extensionVsixPath"
        if ($extensionVsixPath -match '^https://') {
            try {
                $fileName = [System.IO.Path]::GetFileName($extensionVsixPath)
                if (-not $fileName.EndsWith(" .vsix" )) {
                    $fileName = $fileName + " .vsix"
                }
                $savedPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $fileName)
                Import-RemoteVisualStudioPackageToPath -VsixUrl $extensionVsixPath -LocalFilePath $savedPath
                Copy-Item -Path $savedPath -Destination $downloadLocation
            }
            catch {
                Write-Error "Failed to download the VSIX file from: $extensionVsixPath. $_"
            }
        }
        elseif (-Not (Test-Path $extensionVsixPath)) {
            Write-Error "The specified file path does not exist: $extensionVsixPath."
        }
        else {
            Write-Host "Copying VSIX from local path: $extensionVsixPath"
            Copy-Item -Path $extensionVsixPath -Destination $downloadLocation
            Write-Host "Copied VSIX to: $downloadLocation"
        }
    }
    # Process extension name
    elseif (-not [string]::IsNullOrWhiteSpace($extensionName)) {
        Write-Host "ExtensionName: $extensionName"
        $params = @{
            DownloadPreRelease = $downloadPreRelease }
            DownloadLocation = $downloadLocation
            ExtensionReference = $extensionId
            VersionNumber = $extensionVersion
            DownloadDependencies = $true
        }
        Get-VisualStudioExtension @params
}
function Resolve-VisualStudioCodeBootstrapPath (
    [Parameter(Mandatory = $false)] [String] $visualStudioCodeInstallPath = $null,
    [Parameter(Mandatory = $false)] [bool] $installInsiders = $false) {
    if ([string]::IsNullOrWhiteSpace($visualStudioCodeInstallPath)) {
        if ($installInsiders) {
            $visualStudioCodeInstallPath = " %ProgramFiles%\Microsoft VS Code Insiders"
        }
        else {
            $visualStudioCodeInstallPath = " %ProgramFiles%\Microsoft VS Code"
        }
    }
    $visualStudioCodeInstallPath = [System.Environment]::ExpandEnvironmentVariables($visualStudioCodeInstallPath)
    if (-not (Test-Path $visualStudioCodeInstallPath)) {
        Write-Error "Visual Studio Code install path was not found at $VisualStudioCodeInstallPath. Ensure the windows-vscodeinstall artifact is executed before this or manually define the install path via the property VisualStudioCodeInstallPath"
    }
    return Join-Path -Path $visualStudioCodeInstallPath -ChildPath " bootstrap\extensions"
}
function Main (
    [Parameter(Mandatory = $false)] [String] $extensionId = $null,
    [Parameter(Mandatory = $false)] [String] $extensionName = $null,
    [Parameter(Mandatory = $false)] [String] $extensionVsixPath = $null,
    [Parameter(Mandatory = $false)] [String] $extensionVersion = $null,
    [Parameter(Mandatory = $false)] [String] $visualStudioCodeInstallPath = $null,
    [Parameter(Mandatory = $false)] [bool] $installInsiders = $false,
    [Parameter(Mandatory = $false)] [bool];  $emitAllInstalledExtensions = $false) {
    $params = @{
        extensionName = $extensionName
        extensionVersion = $extensionVersion
        extensionId = $extensionId
        extensionVsixPath = $extensionVsixPath
    }
    Confirm-UserRequest @params
$vsCodeGlobalExtensionsPath = Resolve-VisualStudioCodeBootstrapPath
    if (-not (Test-Path $vsCodeGlobalExtensionsPath)) {
        New-Item -ErrorAction Stop $vsCodeGlobalExtensionsPath -ItemType Directory -ErrorAction 'SilentlyContinue' | Out-Null
        if (-not (Test-Path $vsCodeGlobalExtensionsPath)) {
            Write-Error "The folder $vsCodeGlobalExtensionsPath could not be created. Please ensure you are running as admin."
        }
    }
    $params = @{
        downloadPreRelease = $installInsiders
        extensionVsixPath = $extensionVsixPath
        extensionId = $extensionId
        downloadLocation = $vsCodeGlobalExtensionsPath
        extensionVersion = $extensionVersion
        extensionName = $extensionName
    }
    Import-ExtensionToLocalPath @params
    if ($emitAllInstalledExtensions) {
        Write-Host "All extensions in the bootstrap directory:"
        Get-ChildItem -Path $vsCodeGlobalExtensionsPath -File
    }
}
try {
    if (-not ((Test-Path variable:global:IsUnderTest) -and $global:IsUnderTest)) {
        $params = @{
            extensionVsixPath = $ExtensionVsixPath
            extensionId = $ExtensionId
            emitAllInstalledExtensions = $EmitAllInstalledExtensions }
            visualStudioCodeInstallPath = $VisualStudioCodeInstallPath
            installInsiders = $InstallInsiders
            extensionVersion = $ExtensionVersion
            extensionName = $ExtensionName
        }
        Main @params
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}\n

