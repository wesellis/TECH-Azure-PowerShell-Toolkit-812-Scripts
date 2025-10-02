#Requires -Version 7.4
#Requires -Modules PartnerCenter, Az.Accounts

<#
.SYNOPSIS
    Connect to Azure using Secure App Model

.DESCRIPTION
    Azure automation script for connecting to Azure using Secure App Model with Partner Center

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

    SECURITY WARNING: Never hardcode credentials, tokens, or tenant IDs in scripts.
    Use secure methods like Azure Key Vault, environment variables, or parameter files.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$ApplicationId,

    [Parameter(Mandatory = $true)]
    [string]$AccountId,

    [Parameter(Mandatory = $false)]
    [string]$RefreshToken,

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName,

    [Parameter(Mandatory = $false)]
    [string]$SecretName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Get-RefreshTokenSecure {
    param(
        [string]$KeyVaultName,
        [string]$SecretName,
        [string]$RefreshToken
    )

    if ($KeyVaultName -and $SecretName) {
        Write-Verbose "Retrieving refresh token from Key Vault: $KeyVaultName"
        try {
            $secret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText
            return $secret
        }
        catch {
            Write-Error "Failed to retrieve refresh token from Key Vault: $_"
            throw
        }
    }
    elseif ($RefreshToken) {
        Write-Warning "Using refresh token from parameter. Consider using Key Vault for production scenarios."
        return $RefreshToken
    }
    else {
        # Prompt for refresh token if not provided
        $secureToken = Read-Host -Prompt "Enter refresh token" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
}

function Get-ApplicationCredential {
    param(
        [string]$ApplicationId
    )

    Write-Verbose "Getting credential for Application ID: $ApplicationId"

    # Check for environment variable first
    $appSecret = $env:AZURE_APP_SECRET

    if ($appSecret) {
        $securePassword = ConvertTo-SecureString $appSecret -AsPlainText -Force
        return New-Object System.Management.Automation.PSCredential ($ApplicationId, $securePassword)
    }
    else {
        # Prompt for credentials
        return Get-Credential -UserName $ApplicationId -Message "Enter application secret"
    }
}

try {
    Write-Verbose "Starting Azure Secure App Model connection..."

    # Import required module
    Import-Module 'PartnerCenter' -ErrorAction Stop

    # Get refresh token securely
    $secureRefreshToken = Get-RefreshTokenSecure -KeyVaultName $KeyVaultName `
                                                 -SecretName $SecretName `
                                                 -RefreshToken $RefreshToken

    # Get application credential
    $appCredential = Get-ApplicationCredential -ApplicationId $ApplicationId

    # Create Azure management token
    Write-Verbose "Creating Azure management token..."
    $azureTokenParams = @{
        ApplicationId    = $appCredential.UserName
        Credential       = $appCredential
        RefreshToken     = $secureRefreshToken
        Scopes           = 'https://management.azure.com/user_impersonation'
        ServicePrincipal = $true
        Tenant           = $TenantId
    }

    $azureToken = New-PartnerAccessToken @azureTokenParams

    # Create Graph token
    Write-Verbose "Creating Graph token..."
    $graphTokenParams = @{
        ApplicationId    = $appCredential.UserName
        Credential       = $appCredential
        RefreshToken     = $secureRefreshToken
        Scopes           = 'https://graph.windows.net/.default'
        ServicePrincipal = $true
        Tenant           = $TenantId
    }

    $graphToken = New-PartnerAccessToken @graphTokenParams

    # Connect to Azure Account
    Write-Verbose "Connecting to Azure Account..."
    $connectParams = @{
        AccessToken      = $azureToken.AccessToken
        AccountId        = $AccountId
        GraphAccessToken = $graphToken.AccessToken
        Tenant           = $TenantId
    }

    Connect-AzAccount @connectParams

    Write-Verbose "Successfully connected to Azure using Secure App Model"

    # Return connection details (without sensitive information)
    return @{
        TenantId      = $TenantId
        ApplicationId = $ApplicationId
        AccountId     = $AccountId
        Connected     = $true
        ConnectedAt   = Get-Date
    }
}
catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    throw
}
finally {
    # Clear sensitive variables
    if ($secureRefreshToken) { Clear-Variable -Name secureRefreshToken -Force -ErrorAction SilentlyContinue }
    if ($appCredential) { Clear-Variable -Name appCredential -Force -ErrorAction SilentlyContinue }
    if ($azureToken) { Clear-Variable -Name azureToken -Force -ErrorAction SilentlyContinue }
    if ($graphToken) { Clear-Variable -Name graphToken -Force -ErrorAction SilentlyContinue }
}