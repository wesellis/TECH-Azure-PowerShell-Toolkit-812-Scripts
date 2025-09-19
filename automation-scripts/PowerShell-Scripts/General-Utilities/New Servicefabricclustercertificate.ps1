#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    New Servicefabricclustercertificate

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced New Servicefabricclustercertificate

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param(
    [string] [Parameter(Mandatory=$true)] $WEPassword,
    [string] [Parameter(Mandatory=$true)] $WECertDNSName,
    [string] [Parameter(Mandatory=$true)] $WEKeyVaultName,
    [string] [Parameter(Mandatory=$true)] $WEKeyVaultSecretName
)

#region Functions

$WESecurePassword = ConvertTo-SecureString -String $WEPassword -AsPlainText -Force
$WECertFileFullPath = $(Join-Path (Split-Path -Parent $WEMyInvocation.MyCommand.Definition) " \$WECertDNSName.pfx" )

$WENewCert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My -DnsName $WECertDNSName 
Export-PfxCertificate -FilePath $WECertFileFullPath -Password $WESecurePassword -Cert $WENewCert

$WEBytes = [System.IO.File]::ReadAllBytes($WECertFileFullPath)
$WEBase64 = [System.Convert]::ToBase64String($WEBytes)

$WEJSONBlob = @{
    data = $WEBase64
    dataType = 'pfx'
    password = $WEPassword
} | ConvertTo-Json

$WEContentBytes = [System.Text.Encoding]::UTF8.GetBytes($WEJSONBlob)
$WEContent = [System.Convert]::ToBase64String($WEContentBytes)
; 
$WESecretValue = ConvertTo-SecureString -String $WEContent -AsPlainText -Force; 
$WENewSecret = Set-AzureKeyVaultSecret -VaultName $WEKeyVaultName -Name $WEKeyVaultSecretName -SecretValue $WESecretValue -Verbose

Write-Information Write-WELog " Source Vault Resource Id: " " INFO" $(Get-AzureRmKeyVault -VaultName $WEKeyVaultName).ResourceId
Write-WELog " Certificate URL : " " INFO" $WENewSecret.Id
Write-WELog " Certificate Thumbprint : " " INFO" $WENewCert.Thumbprint



} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
