<#
.SYNOPSIS
    Azure Keyvault Secret Retriever

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
Write-Host "Retrieving secret from Key Vault: $VaultName"
$Secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
if ($AsPlainText) {
$SecretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret.SecretValue))
    Write-Host "Secret Value: $SecretValue"
} else {
    Write-Host "Secret retrieved (use -AsPlainText to display value):"
}
Write-Host "Name: $($Secret.Name)"
Write-Host "Version: $($Secret.Version)"
Write-Host "Created: $($Secret.Created)"
Write-Host "Updated: $($Secret.Updated)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n