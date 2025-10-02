#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Keyvault Secret Creator

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
    [Parameter(Mandatory)]
    [string]$SecretValue
)
Write-Output "Adding secret to Key Vault: $VaultName"
    [string]$SecureString = Read-Host -Prompt "Enter secure value" -AsSecureString
    [string]$Secret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $SecureString
Write-Output "Secret added successfully:"
Write-Output "Name: $($Secret.Name)"
Write-Output "Version: $($Secret.Version)"
Write-Output "Vault: $VaultName"
Write-Output "Created: $($Secret.Created)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
