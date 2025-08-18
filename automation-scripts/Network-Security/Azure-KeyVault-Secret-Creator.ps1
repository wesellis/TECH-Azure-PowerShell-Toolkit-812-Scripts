# ============================================================================
# Script Name: Azure Key Vault Secret Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Adds a new secret to Azure Key Vault
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$VaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$SecretName,
    
    [Parameter(Mandatory=$true)]
    [string]$SecretValue
)

Write-Information "Adding secret to Key Vault: $VaultName"

$SecureString = ConvertTo-SecureString $SecretValue -AsPlainText -Force

$Secret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $SecureString

Write-Information "Secret added successfully:"
Write-Information "  Name: $($Secret.Name)"
Write-Information "  Version: $($Secret.Version)"
Write-Information "  Vault: $VaultName"
Write-Information "  Created: $($Secret.Created)"
