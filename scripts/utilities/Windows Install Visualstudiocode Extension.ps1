#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Install Visualstudiocode Extension

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
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
    [Parameter(Mandatory = $false)] [String] $ExtensionId = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionName = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionVsixPath = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionVersion = $null) {
    $ParamCount = 0
    if (-not [string]::IsNullOrWhiteSpace($ExtensionId)) { $ParamCount++ }
    if (-not [string]::IsNullOrWhiteSpace($ExtensionName)) { $ParamCount++ }
    if (-not [string]::IsNullOrWhiteSpace($ExtensionVsixPath)) { $ParamCount++ }
    if ($ParamCount -ne 1) {
        Write-Error "You must provide either an ExtensionId, ExtensionName, or ExtensionVsixPath (but not more than one). You can find the ExtensionName in the URL of the Marketplace extension. Example: If the extension URL is https://marketplace.visualstudio.com/items?itemName=GitHub.copilot then you would use `GitHub.copilot`."
    }
    if ((-not [string]::IsNullOrWhiteSpace($ExtensionVsixPath)) -and (-not [string]::IsNullOrWhiteSpace($ExtensionVersion))) {
        Write-Error "You cannot specify an ExtensionVersion when installing from a direct VSIX URL or path."
    }
}
function Import-ExtensionToLocalPath (
    [Parameter(Mandatory = $false)] [String] $ExtensionId = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionName = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionVsixPath = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionVersion = $null,
    [Parameter(Mandatory = $true)] [String] $DownloadLocation,
    [Parameter(Mandatory = $false)] [Bool] $DownloadPreRelease) {
    if (-not [string]::IsNullOrWhiteSpace($ExtensionVsixPath)) {
        Write-Output "ExtensionVsixPath: $ExtensionVsixPath"
        if ($ExtensionVsixPath -match '^https://') {
            try {
    $FileName = [System.IO.Path]::GetFileName($ExtensionVsixPath)
                if (-not $FileName.EndsWith(" .vsix" )) {
    $FileName = $FileName + " .vsix"
                }
    $SavedPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $FileName)
                Import-RemoteVisualStudioPackageToPath -VsixUrl $ExtensionVsixPath -LocalFilePath $SavedPath
                Copy-Item -Path $SavedPath -Destination $DownloadLocation
            }
            catch {
                Write-Error "Failed to download the VSIX file from: $ExtensionVsixPath. $_"
            }
        }
        elseif (-Not (Test-Path $ExtensionVsixPath)) {
            Write-Error "The specified file path does not exist: $ExtensionVsixPath."
        }
        else {
            Write-Output "Copying VSIX from local path: $ExtensionVsixPath"
            Copy-Item -Path $ExtensionVsixPath -Destination $DownloadLocation
            Write-Output "Copied VSIX to: $DownloadLocation"
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($ExtensionName)) {
        Write-Output "ExtensionName: $ExtensionName"
    $params = @{
            DownloadPreRelease = $DownloadPreRelease }
            DownloadLocation = $DownloadLocation
            ExtensionReference = $ExtensionId
            VersionNumber = $ExtensionVersion
            DownloadDependencies = $true
        }
        Get-VisualStudioExtension @params
}
function Resolve-VisualStudioCodeBootstrapPath (
    [Parameter(Mandatory = $false)] [String] $VisualStudioCodeInstallPath = $null,
    [Parameter(Mandatory = $false)] [bool] $InstallInsiders = $false) {
    if ([string]::IsNullOrWhiteSpace($VisualStudioCodeInstallPath)) {
        if ($InstallInsiders) {
    $VisualStudioCodeInstallPath = " %ProgramFiles%\Microsoft VS Code Insiders"
        }
        else {
    $VisualStudioCodeInstallPath = " %ProgramFiles%\Microsoft VS Code"
        }
    }
    $VisualStudioCodeInstallPath = [System.Environment]::ExpandEnvironmentVariables($VisualStudioCodeInstallPath)
    if (-not (Test-Path $VisualStudioCodeInstallPath)) {
        Write-Error "Visual Studio Code install path was not found at $VisualStudioCodeInstallPath. Ensure the windows-vscodeinstall artifact is executed before this or manually define the install path via the property VisualStudioCodeInstallPath"
    }
    return Join-Path -Path $VisualStudioCodeInstallPath -ChildPath " bootstrap\extensions"
}
function Main (
    [Parameter(Mandatory = $false)] [String] $ExtensionId = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionName = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionVsixPath = $null,
    [Parameter(Mandatory = $false)] [String] $ExtensionVersion = $null,
    [Parameter(Mandatory = $false)] [String] $VisualStudioCodeInstallPath = $null,
    [Parameter(Mandatory = $false)] [bool] $InstallInsiders = $false,
    [Parameter(Mandatory = $false)] [bool];  $EmitAllInstalledExtensions = $false) {
    $params = @{
        extensionName = $ExtensionName
        extensionVersion = $ExtensionVersion
        extensionId = $ExtensionId
        extensionVsixPath = $ExtensionVsixPath
    }
    Confirm-UserRequest @params
    $VsCodeGlobalExtensionsPath = Resolve-VisualStudioCodeBootstrapPath
    if (-not (Test-Path $VsCodeGlobalExtensionsPath)) {
        New-Item -ErrorAction Stop $VsCodeGlobalExtensionsPath -ItemType Directory -ErrorAction 'SilentlyContinue' | Out-Null
        if (-not (Test-Path $VsCodeGlobalExtensionsPath)) {
            Write-Error "The folder $VsCodeGlobalExtensionsPath could not be created. Please ensure you are running as admin."
        }
    }
    $params = @{
        downloadPreRelease = $InstallInsiders
        extensionVsixPath = $ExtensionVsixPath
        extensionId = $ExtensionId
        downloadLocation = $VsCodeGlobalExtensionsPath
        extensionVersion = $ExtensionVersion
        extensionName = $ExtensionName
    }
    Import-ExtensionToLocalPath @params
    if ($EmitAllInstalledExtensions) {
        Write-Output "All extensions in the bootstrap directory:"
        Get-ChildItem -Path $VsCodeGlobalExtensionsPath -File
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
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
