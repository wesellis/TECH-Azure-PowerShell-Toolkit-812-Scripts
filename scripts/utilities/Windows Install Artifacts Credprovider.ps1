#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Install Artifacts Credprovider

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Installs the Azure Artifact Credential Provider
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)]
    [bool] $AddNetFx,
    [Parameter(Mandatory = $false)]
    [bool] $InstallNet6 = $true,
    [Parameter(Mandatory = $false)]
    [string] $version,
    [Parameter(Mandatory = $false)]
    [string] $OptionalCopyNugetPluginsRoot
)
Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-retry-utils.psm1')
    $DownloadUrl = "https://aka.ms/install-artifacts-credprovider.ps1"
    $OutputFile = [System.IO.Path]::Combine($env:TEMP, "installcredprovider.ps1" )
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (Test-Path -PathType Container $OutputFile) {
        [System.IO.Directory]::Delete($OutputFile, $true)
    }
    Write-Output "Downloading Artifact Credential provider install script from $DownloadUrl."
    Write-Output "Writing file to $OutputFile"
    $RunBlock = {
        Invoke-WebRequest -Uri " $DownloadUrl" -OutFile " $OutputFile"
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 5
    if (!(Test-Path -PathType Leaf $OutputFile)) {
        Write-Error "File download failed."
        throw
    }
    Write-Output "Running install script."
    if ($AddNetFx -eq $true) {
        Write-Output "Installing with NetFx."
    }
    else {
        Write-Output "Installing NetCore only."
    }
    if ($InstallNet6 -eq $true) {
        Write-Output "Installing .NET 6.0."
    }
    else {
        Write-Output "Installing .NET Core 3.1."
    }
    if (![string]::IsNullOrEmpty($version)) {
        Write-Output "Installing version $version"
    }
    $RunBlock = {
        &$OutputFile -AddNetFx:$AddNetFx -InstallNet6:$InstallNet6 -Version:$version
    }
    RunWithRetries -runBlock $RunBlock -retryAttempts 5 -waitBeforeRetrySeconds 5
    $NugetPluginDirectory = [System.IO.Path]::Combine($env:USERPROFILE, ".nuget" , "plugins" )
    $ExpectedNetCoreLocation = [System.IO.Path]::Combine($NugetPluginDirectory, "netcore\CredentialProvider.Microsoft\CredentialProvider.Microsoft.dll" )
    if (!(Test-Path -PathType Leaf $ExpectedNetCoreLocation)) {
        Write-Output "Credential Provider (NetCore) not found at $ExpectedNetCoreLocation."
        throw
    }
    $ExpectedNetFXLoacation = [System.IO.Path]::Combine($NugetPluginDirectory, "netfx\CredentialProvider.Microsoft\CredentialProvider.Microsoft.exe" )
    if ($AddNetFx -eq $true -and !(Test-Path -PathType Leaf $ExpectedNetFXLoacation)) {
        Write-Output "Credential Provider (NetFx) not found at $ExpectedNetFXLoacation."
        throw
    }
    if (!([System.String]::IsNullOrWhiteSpace($OptionalCopyNugetPluginsRoot))) {
    $TargetDirectory = [System.IO.Path]::Combine($OptionalCopyNugetPluginsRoot, ".nuget" , "plugins" )
        if (!(Test-Path -PathType Container $TargetDirectory)) {
            Write-Output "Creating directory '$TargetDirectory'."
            [System.IO.Directory]::CreateDirectory($TargetDirectory)
        }
        if (!(Test-Path -PathType Container $TargetDirectory)) {
            Write-Error "Could not create folder '$TargetDirectory'."
            throw
        }
        Write-Information Write-Output "Copying NuGet plugins from '$NugetPluginDirectory' to '$TargetDirectory'."
        Copy-Item -Path " $NugetPluginDirectory\*" -Destination " $TargetDirectory\" -Recurse -Force
    }
    exit 0
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop`n}
