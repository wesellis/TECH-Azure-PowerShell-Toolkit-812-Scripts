#Requires -Version 7.4

<#
.SYNOPSIS
    Enable Azure DevCenter resource provider.

.DESCRIPTION
    This script registers the Microsoft.DevCenter resource provider in Azure,
    which is required to use Azure DevCenter services for development environments.

.EXAMPLE
    .\Enable-Devcenter.ps1

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Requires Az PowerShell module
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Registering Microsoft.DevCenter resource provider..."
    Register-AzResourceProvider -ProviderNamespace Microsoft.DevCenter
    Write-Output "Microsoft.DevCenter resource provider registered successfully."
}
catch {
    Write-Error "Failed to register Microsoft.DevCenter resource provider: $($_.Exception.Message)"
    throw
}