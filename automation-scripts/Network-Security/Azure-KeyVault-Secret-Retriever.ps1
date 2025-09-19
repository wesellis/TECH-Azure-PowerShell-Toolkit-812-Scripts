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
    
    [Parameter(Mandatory=$false)]
    [switch]$AsPlainText
)

#region Functions

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


#endregion
