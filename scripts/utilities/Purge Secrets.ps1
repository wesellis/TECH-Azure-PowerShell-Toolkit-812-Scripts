#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.KeyVault

<#
.SYNOPSIS
    Purge BEK Secrets from Azure Key Vault

.DESCRIPTION
    Azure automation script to list or purge BitLocker Encryption Key (BEK)
    secrets from an Azure Key Vault. Used for cleaning up wrapped BEK secrets
    that are no longer needed.

.PARAMETER VaultName
    Name of the Azure Key Vault (default: "azbotvault")

.PARAMETER Purge
    Switch to enable purging of secrets. Without this switch, secrets are only listed.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate Azure Key Vault permissions
    Use with caution - purging secrets is irreversible
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [string]$VaultName = "azbotvault",

    [Parameter(Mandatory = $false)]
    [switch]$Purge
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Connecting to Key Vault: $VaultName"

    # Get all BEK secrets from the vault
    $secrets = Get-AzKeyVaultSecret -VaultName $VaultName | Where-Object { $_.ContentType -eq "Wrapped BEK" }

    if (-not $secrets) {
        Write-Output "No wrapped BEK secrets found in vault: $VaultName"
        return
    }

    Write-Output "Found $($secrets.Count) wrapped BEK secrets"

    if ($Purge) {
        if ($PSCmdlet.ShouldProcess("$($secrets.Count) BEK secrets in vault $VaultName", "Purge")) {
            Write-Warning "Purging $($secrets.Count) BEK secrets from vault: $VaultName"

            $purgedCount = 0
            foreach ($secret in $secrets) {
                try {
                    Remove-AzKeyVaultSecret -VaultName $VaultName -Name $secret.Name -Force
                    Write-Output "Purged secret: $($secret.Name)"
                    $purgedCount++
                }
                catch {
                    Write-Error "Failed to purge secret $($secret.Name): $_"
                }
            }

            Write-Output "Successfully purged $purgedCount out of $($secrets.Count) secrets"
        }
    }
    else {
        Write-Output "`nListing wrapped BEK secrets:"
        Write-Output "=" * 50

        foreach ($secret in $secrets) {
            Write-Output "Name: $($secret.Name)"
            Write-Output "Id: $($secret.Id)"
            Write-Output "Created: $($secret.Created)"
            Write-Output "Updated: $($secret.Updated)"
            Write-Output "Enabled: $($secret.Enabled)"
            Write-Output "-" * 50
        }

        Write-Output "`nTotal secrets: $($secrets.Count)"
        Write-Output "To purge these secrets, run with -Purge switch"
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

# Example usage:
# .\Purge Secrets.ps1 -VaultName "mykeyvault"                # List secrets
# .\Purge Secrets.ps1 -VaultName "mykeyvault" -Purge -WhatIf  # Preview purge
# .\Purge Secrets.ps1 -VaultName "mykeyvault" -Purge          # Actually purge secrets