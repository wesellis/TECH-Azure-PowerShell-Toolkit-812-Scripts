#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$VaultName,
    
    [Parameter(Mandatory=$true)]
    [string]$SecretName,
    
    [Parameter(Mandatory=$true)]
    [string]$SecretValue
)

#region Functions

Write-Information "Adding secret to Key Vault: $VaultName"

$SecureString = ConvertTo-SecureString $SecretValue -AsPlainText -Force

$Secret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $SecureString

Write-Information "Secret added successfully:"
Write-Information "  Name: $($Secret.Name)"
Write-Information "  Version: $($Secret.Version)"
Write-Information "  Vault: $VaultName"
Write-Information "  Created: $($Secret.Created)"


#endregion
