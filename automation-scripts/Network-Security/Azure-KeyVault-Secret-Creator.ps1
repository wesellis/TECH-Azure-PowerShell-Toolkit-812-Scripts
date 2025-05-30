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

Write-Host "Adding secret to Key Vault: $VaultName"

$SecureString = ConvertTo-SecureString $SecretValue -AsPlainText -Force

$Secret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $SecureString

Write-Host "Secret added successfully:"
Write-Host "  Name: $($Secret.Name)"
Write-Host "  Version: $($Secret.Version)"
Write-Host "  Vault: $VaultName"
Write-Host "  Created: $($Secret.Created)"
