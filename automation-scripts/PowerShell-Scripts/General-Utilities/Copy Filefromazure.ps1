<#
.SYNOPSIS
    Copy Filefromazure

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$artifactsLocation,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$artifactsLocationSasToken,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$folderName,
    [string]$fileToInstall
)
#region Functions
$source = $artifactsLocation + " \$folderName\$fileToInstall" + $artifactsLocationSasToken;
$dest = "C:\WindowsAzure\$folderName"
New-Item -Path $dest -ItemType directory
Invoke-WebRequest $source -OutFile " $dest\$fileToInstall"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n