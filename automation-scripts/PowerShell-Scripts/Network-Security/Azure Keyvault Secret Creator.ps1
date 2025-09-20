<#
.SYNOPSIS
    Azure Keyvault Secret Creator

.DESCRIPTION
    Azure automation
#>
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
    [Parameter(Mandatory)]
    [string]$SecretValue
)
Write-Host "Adding secret to Key Vault: $VaultName"
$SecureString = ConvertTo-SecureString $SecretValue -AsPlainText -Force
$Secret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $SecureString
Write-Host "Secret added successfully:"
Write-Host "Name: $($Secret.Name)"
Write-Host "Version: $($Secret.Version)"
Write-Host "Vault: $VaultName"
Write-Host "Created: $($Secret.Created)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

