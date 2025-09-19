#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Copy Filefromazure

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Copy Filefromazure

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$artifactsLocation,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$artifactsLocationSasToken,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$folderName,
    [string]$fileToInstall
)

#region Functions
; 
$source = $artifactsLocation + " \$folderName\$fileToInstall" + $artifactsLocationSasToken; 
$dest = " C:\WindowsAzure\$folderName"
New-Item -Path $dest -ItemType directory
Invoke-WebRequest $source -OutFile " $dest\$fileToInstall"



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
