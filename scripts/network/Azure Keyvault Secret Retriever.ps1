#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.KeyVault

<#`n.SYNOPSIS
    Azure Keyvault Secret Retriever

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VaultName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$SecretName,
    [Parameter()]
    [switch]$AsPlainText
)
Write-Output "Retrieving secret from Key Vault: $VaultName"
    [string]$Secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
if ($AsPlainText) {
    [string]$SecretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret.SecretValue))
    Write-Output "Secret Value: $SecretValue"
} else {
    Write-Output "Secret retrieved (use -AsPlainText to display value):"
}
Write-Output "Name: $($Secret.Name)"
Write-Output "Version: $($Secret.Version)"
Write-Output "Created: $($Secret.Created)"
Write-Output "Updated: $($Secret.Updated)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
