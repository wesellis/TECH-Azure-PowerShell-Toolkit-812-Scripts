<#
.SYNOPSIS
    We Enhanced Azure Keyvault Secret Creator

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVaultName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESecretName,
    
    [Parameter(Mandatory=$true)]
    [string]$WESecretValue
)

Write-WELog " Adding secret to Key Vault: $WEVaultName" " INFO"

$WESecureString = ConvertTo-SecureString $WESecretValue -AsPlainText -Force
; 
$WESecret = Set-AzKeyVaultSecret -VaultName $WEVaultName -Name $WESecretName -SecretValue $WESecureString

Write-WELog " Secret added successfully:" " INFO"
Write-WELog "  Name: $($WESecret.Name)" " INFO"
Write-WELog "  Version: $($WESecret.Version)" " INFO"
Write-WELog "  Vault: $WEVaultName" " INFO"
Write-WELog "  Created: $($WESecret.Created)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
