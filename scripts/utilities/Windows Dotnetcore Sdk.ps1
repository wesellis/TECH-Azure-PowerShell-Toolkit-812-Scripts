#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Dotnetcore Sdk

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
$DotNetCoreVersion = " latest" ,
[Parameter()]
    [ValidateNotNullOrEmpty()]
    $Runtime,
[Parameter()]
    [ValidateNotNullOrEmpty()]
    $Channel,
[Parameter()]
    [ValidateNotNullOrEmpty()]
    $GlobalJsonFilePath,
$OverrideDotnet
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (![string]::IsNullOrEmpty($GlobalJsonFilePath)) {
    Import-Module -Force (Join-Path $(Split-Path -Parent $PSScriptRoot) '_common/windows-json-utils.psm1')
    if([System.IO.File]::Exists($GlobalJsonFilePath)) {
    $DotNetCoreVersion = (Get-JsonFromFile -ErrorAction Stop $GlobalJsonFilePath).sdk.version
    }
    Write-Output "Installing NetCore SDK version: $DotNetCoreVersion"
    & .\dotnet-install.ps1 -Version $DotNetCoreVersion -InstallDir "C:\Program Files\dotnet"
    exit 0
}
    $Override = $false
if ((![string]::IsNullOrEmpty($OverrideDotnet)) -and ($OverrideDotnet -eq "OverrideDotnet" )) {
    $Override = $true
}
Write-Output "Installing NetCore SDK version: $DotNetCoreVersion  channel: $Channel  runtime: $Runtime  OverrideDotnet: $OverrideDotnet  Override:$Override"
Unblock-File -Path .\dotnet-install.ps1
if ([string]::IsNullOrEmpty($Channel)) {
    if ([string]::IsNullOrEmpty($Runtime)) {
	    & .\dotnet-install.ps1 -Version $DotNetCoreVersion -InstallDir "C:\Program Files\dotnet" -OverrideVersion $Override
    }
    else {
	    & .\dotnet-install.ps1 -Version $DotNetCoreVersion -InstallDir "C:\Program Files\dotnet" -RunTime $Runtime -OverrideVersion $Override
    }
}
elseif([string]::IsNullOrEmpty($Runtime) -and [string]::IsNullOrEmpty($DotNetCoreVersion))
{
    & .\dotnet-install.ps1 -Channel $Channel -InstallDir "C:\Program Files\dotnet"
}
else
{
    if ([string]::IsNullOrEmpty($Runtime)) {
	    & .\dotnet-install.ps1 -Version $DotNetCoreVersion -Channel $Channel -InstallDir "C:\Program Files\dotnet" -OverrideVersion $Override
    }
    else {
	    & .\dotnet-install.ps1 -Version $DotNetCoreVersion -Channel $Channel -InstallDir "C:\Program Files\dotnet" -RunTime $Runtime -OverrideVersion $Override
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
