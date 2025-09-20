<#
.SYNOPSIS
    Installazurerm

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
	[switch];  $linux=$false
)
if ( $linux ) {
Install-Module AzureRM.NetCore -SkipPublisherCheck -Force
}else{
Install-PackageProvider -name Nuget -MinimumVersion 2.8.5.201 -Force
Install-Module AzureRM -SkipPublisherCheck -Force
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

