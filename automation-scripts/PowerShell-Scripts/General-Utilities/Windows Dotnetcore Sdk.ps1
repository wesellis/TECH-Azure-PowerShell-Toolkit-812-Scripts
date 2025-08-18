<#
.SYNOPSIS
    Windows Dotnetcore Sdk

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
    We Enhanced Windows Dotnetcore Sdk

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
[string]$WEDotNetCoreVersion = " latest" ,


[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERuntime,


[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEChannel,


[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEGlobalJsonFilePath,


[string]$WEOverrideDotnet

)


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (![string]::IsNullOrEmpty($WEGlobalJsonFilePath)) {
    Import-Module -Force (Join-Path $(Split-Path -Parent $WEPSScriptRoot) '_common/windows-json-utils.psm1')
    if([System.IO.File]::Exists($WEGlobalJsonFilePath)) {
        $WEDotNetCoreVersion = (Get-JsonFromFile $WEGlobalJsonFilePath).sdk.version
    }

    Write-WELog " Installing NetCore SDK version: $WEDotNetCoreVersion" " INFO"
    & .\dotnet-install.ps1 -Version $WEDotNetCoreVersion -InstallDir " C:\Program Files\dotnet" 
    exit 0
}
; 
$WEOverride = $false
if ((![string]::IsNullOrEmpty($WEOverrideDotnet)) -and ($WEOverrideDotnet -eq " OverrideDotnet" )) {
    ;  $WEOverride = $true
}

Write-WELog " Installing NetCore SDK version: $WEDotNetCoreVersion  channel: $WEChannel  runtime: $WERuntime  OverrideDotnet: $WEOverrideDotnet  Override:$WEOverride" " INFO"
Unblock-File -Path .\dotnet-install.ps1

if ([string]::IsNullOrEmpty($WEChannel)) {
    if ([string]::IsNullOrEmpty($WERuntime)) {
	    & .\dotnet-install.ps1 -Version $WEDotNetCoreVersion -InstallDir " C:\Program Files\dotnet" -OverrideVersion $WEOverride
    }
    else {
	    & .\dotnet-install.ps1 -Version $WEDotNetCoreVersion -InstallDir " C:\Program Files\dotnet" -RunTime $WERuntime -OverrideVersion $WEOverride
    }
}
elseif([string]::IsNullOrEmpty($WERuntime) -and [string]::IsNullOrEmpty($WEDotNetCoreVersion))
{
    & .\dotnet-install.ps1 -Channel $WEChannel -InstallDir " C:\Program Files\dotnet"
}
else
{
    if ([string]::IsNullOrEmpty($WERuntime)) {
	    & .\dotnet-install.ps1 -Version $WEDotNetCoreVersion -Channel $WEChannel -InstallDir " C:\Program Files\dotnet" -OverrideVersion $WEOverride
    }
    else {
	    & .\dotnet-install.ps1 -Version $WEDotNetCoreVersion -Channel $WEChannel -InstallDir " C:\Program Files\dotnet" -RunTime $WERuntime -OverrideVersion $WEOverride
    }
}




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
