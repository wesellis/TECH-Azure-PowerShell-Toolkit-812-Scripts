# ============================================================================
# Script Name: Azure Key Vault Secret Retriever
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Retrieves a secret value from Azure Key Vault
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$VaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$SecretName,
    
    [Parameter(Mandatory=$false)]
    [switch]$AsPlainText
)

Write-Information "Retrieving secret from Key Vault: $VaultName"

$Secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName

if ($AsPlainText) {
    $SecretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret.SecretValue))
    Write-Information "Secret Value: $SecretValue"
} else {
    Write-Information "Secret retrieved (use -AsPlainText to display value):"
}

Write-Information "  Name: $($Secret.Name)"
Write-Information "  Version: $($Secret.Version)"
Write-Information "  Created: $($Secret.Created)"
Write-Information "  Updated: $($Secret.Updated)"
