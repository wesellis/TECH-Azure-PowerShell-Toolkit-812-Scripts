<#
.SYNOPSIS
    Windows Install Artifacts Credprovider

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
    We Enhanced Windows Install Artifacts Credprovider

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
.SYNOPSIS
    Installs the Azure Artifact Credential Provider

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $false)]
    [bool] $addNetFx,
    [Parameter(Mandatory = $false)]
    [bool] $installNet6 = $true,
    [Parameter(Mandatory = $false)]
    [string] $version,
    [Parameter(Mandatory = $false)]
    [string] $optionalCopyNugetPluginsRoot
)

Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-retry-utils.psm1')

$downloadUrl = " https://aka.ms/install-artifacts-credprovider.ps1"
$outputFile = [System.IO.Path]::Combine($env:TEMP, " installcredprovider.ps1" )

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (Test-Path -PathType Container $outputFile) {
        [System.IO.Directory]::Delete($outputFile, $true)
    }

    Write-WELog " Downloading Artifact Credential provider install script from $downloadUrl." " INFO"
    Write-WELog " Writing file to $outputFile" " INFO"
    $runBlock = {
        Invoke-WebRequest -Uri " $downloadUrl" -OutFile " $outputFile"
    }
    RunWithRetries -runBlock $runBlock -retryAttempts 5 -waitBeforeRetrySeconds 5

    if (!(Test-Path -PathType Leaf $outputFile)) {
        Write-Error " File download failed."
        exit 1
    }

    Write-WELog " Running install script." " INFO"

    if ($addNetFx -eq $true) {
        Write-WELog " Installing with NetFx." " INFO"
    }
    else {
        Write-WELog " Installing NetCore only." " INFO"
    }

    if ($installNet6 -eq $true) {
        Write-WELog " Installing .NET 6.0." " INFO"
    }
    else {
        Write-WELog " Installing .NET Core 3.1." " INFO"
    }

    if (![string]::IsNullOrEmpty($version)) {
        Write-WELog " Installing version $version" " INFO"
    }

    $runBlock = {
        &$outputFile -AddNetFx:$addNetFx -InstallNet6:$installNet6 -Version:$version
    }
    RunWithRetries -runBlock $runBlock -retryAttempts 5 -waitBeforeRetrySeconds 5

    $nugetPluginDirectory = [System.IO.Path]::Combine($env:USERPROFILE, " .nuget" , " plugins" )
    $expectedNetCoreLocation = [System.IO.Path]::Combine($nugetPluginDirectory, " netcore\CredentialProvider.Microsoft\CredentialProvider.Microsoft.dll" )
    if (!(Test-Path -PathType Leaf $expectedNetCoreLocation)) {
        Write-WELog " Credential Provider (NetCore) not found at $expectedNetCoreLocation." " INFO"
        exit 1
    }

   ;  $expectedNetFXLoacation = [System.IO.Path]::Combine($nugetPluginDirectory, " netfx\CredentialProvider.Microsoft\CredentialProvider.Microsoft.exe" )
    if ($addNetFx -eq $true -and !(Test-Path -PathType Leaf $expectedNetFXLoacation)) {
        Write-WELog " Credential Provider (NetFx) not found at $expectedNetFXLoacation." " INFO"
        exit 1
    }

    if (!([System.String]::IsNullOrWhiteSpace($optionalCopyNugetPluginsRoot))) {
       ;  $targetDirectory = [System.IO.Path]::Combine($optionalCopyNugetPluginsRoot, " .nuget" , " plugins" )
        # Create the target if it doesn't exist
        if (!(Test-Path -PathType Container $targetDirectory)) {
            Write-WELog " Creating directory '$targetDirectory'." " INFO"
            [System.IO.Directory]::CreateDirectory($targetDirectory)
        }

        # If it still doesn't exist, throw an error
        if (!(Test-Path -PathType Container $targetDirectory)) {
            Write-Error " Could not create folder '$targetDirectory'."
            exit 1
        }

        Write-Information Write-WELog " Copying NuGet plugins from '$nugetPluginDirectory' to '$targetDirectory'." " INFO"
        Copy-Item -Path " $nugetPluginDirectory\*" -Destination " $targetDirectory\" -Recurse -Force
    }

    exit 0
}
catch {
    Write-Error " !!! [ERROR] Unhandled exception:`n$_`n$($_.ScriptStackTrace)" -ErrorAction Stop
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================