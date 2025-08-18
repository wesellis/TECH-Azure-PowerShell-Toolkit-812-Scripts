<#
.SYNOPSIS
    We Enhanced Installazurerm

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

[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param(
	[switch] $linux=$false
)

if ( $linux ) {

Install-Module AzureRM.NetCore -SkipPublisherCheck -Force
Import-Module AzureRM.Netcore

}else{

Install-PackageProvider -name Nuget -MinimumVersion 2.8.5.201 -Force
Install-Module AzureRM -SkipPublisherCheck -Force

Import-Module AzureRM

}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
