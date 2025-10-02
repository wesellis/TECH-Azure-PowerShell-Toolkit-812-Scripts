#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    New Servicefabricclustercertificate

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
[CmdletBinding()
try {
]
param(
    [string] [Parameter(Mandatory)] $Password,
    [string] [Parameter(Mandatory)] $CertDNSName,
    [string] [Parameter(Mandatory)] $KeyVaultName,
    [string] [Parameter(Mandatory)] $KeyVaultSecretName
)
    $SecurePassword = Read-Host -Prompt "Enter secure value" -AsSecureString
    $CertFileFullPath = $(Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) " \$CertDNSName.pfx" )
    $NewCert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -DnsName $CertDNSName
Export-PfxCertificate -FilePath $CertFileFullPath -Password $SecurePassword -Cert $NewCert
    $Bytes = [System.IO.File]::ReadAllBytes($CertFileFullPath)
    $Base64 = [System.Convert]::ToBase64String($Bytes)
    $JSONBlob = @{
    data = $Base64
    dataType = 'pfx'
    password = $Password
} | ConvertTo-Json
    $ContentBytes = [System.Text.Encoding]::UTF8.GetBytes($JSONBlob)
    $Content = [System.Convert]::ToBase64String($ContentBytes)
    $SecretValue = Read-Host -Prompt "Enter secure value" -AsSecureString;
    $NewSecret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $KeyVaultSecretName -SecretValue $SecretValue -Verbose
Write-Information Write-Output "Source Vault Resource Id: " $(Get-AzureRmKeyVault -VaultName $KeyVaultName).ResourceId
Write-Output "Certificate URL : " $NewSecret.Id
Write-Output "Certificate Thumbprint : " $NewCert.Thumbprint
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
