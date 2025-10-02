#Requires -Version 7.4

<#
.SYNOPSIS
    Create Root And Clients Certificates

.DESCRIPTION
    Azure automation script for creating root and client certificates for Point-to-Site VPN connections.
    This script creates a root certificate and three client certificates for different organizational units.

.PARAMETER PwdCertificates
    Password for certificates (default: '12345')

.NOTES
    Version: 1.0
    Author: Wes Ellis (wes@wesellis.com)
    Requires appropriate permissions and modules
    Creates certificates for marketing, sales, and engineering departments
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'Password for certificates', ValueFromPipeline = $true)]
    [string]$PwdCertificates = '12345'
)

$ErrorActionPreference = "Stop"

try {
    Write-Output "Starting Root and Client Certificate creation..."

    for ($selection = 1; $selection -le 3; $selection++) {
        switch ($selection) {
            1 { $CertSubject = 'CN=cert@marketing.contoso.com'; $ClientNumb = '1' }
            2 { $CertSubject = 'CN=cert@sale.contoso.com'; $ClientNumb = '2' }
            3 { $CertSubject = 'CN=cert@engineering.contoso.com'; $ClientNumb = '3' }
        }

        $CertPath = "C:\cert$ClientNumb\"
        $PathFolder = [string](Split-Path -Path $CertPath -Parent)
        $FolderName = [string](Split-Path -Path $CertPath -Leaf)

        Write-Information "Folder to store digital certificates: $PathFolder$FolderName" -InformationAction Continue
        New-Item -Path $PathFolder -Name $FolderName -ItemType Directory -Force | Out-Null
        Write-Output ""

        # Parameters for root certificate creation
        $params = @{
            Type              = 'Custom'
            Subject           = 'CN=P2SRootCert'
            KeySpec           = 'Signature'
            KeyExportPolicy   = 'Exportable'
            KeyUsage          = 'CertSign'
            KeyUsageProperty  = 'Sign'
            KeyLength         = 2048
            HashAlgorithm     = 'sha256'
            NotAfter          = (Get-Date).AddMonths(24)
            CertStoreLocation = 'Cert:\CurrentUser\My'
        }

        Write-Output "$(Get-Date) - Checking P2S Root certificate in Cert:\CurrentUser\My"
        $CertRoot = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq 'CN=P2SRootCert' }

        if ($null -eq $CertRoot) {
            $CertRoot = New-SelfSignedCertificate @params
            Write-Output "$(Get-Date) - P2S Root certificate created"
        }
        else {
            Write-Output "$(Get-Date) - P2S Root certificate already exists, skipping"
        }

        # Export root certificate with private key
        $mypwd = Read-Host -AsSecureString -Prompt "Enter secure password for root certificate"
        $CertRootThumbprint = (Get-ChildItem -Path "Cert:\CurrentUser\My" | Where-Object -Property Subject -eq "CN=P2SRootCert" | Select-Object Thumbprint).Thumbprint
        $CertRoot = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertRootThumbprint"
        Export-PfxCertificate -Cert $CertRoot -FilePath "$CertPath\P2SRoot-with-privKey.pfx" -Password $mypwd

        Write-Output "$(Get-Date) - Start creation P2S Client cert: $CertSubject"

        # Parameters for client certificate creation
        $params = @{
            Type              = 'Custom'
            Subject           = $CertSubject
            KeySpec           = 'Signature'
            KeyExportPolicy   = 'Exportable'
            KeyLength         = 2048
            HashAlgorithm     = 'sha256'
            NotAfter          = (Get-Date).AddMonths(18)
            CertStoreLocation = 'Cert:\CurrentUser\My'
            Signer            = $CertRoot
            TextExtension     = @('2.5.29.37={text}1.3.6.1.5.5.7.3.2')
        }

        $CertClient = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $CertSubject }
        if ($null -eq $CertClient) {
            New-SelfSignedCertificate @params | Out-Null
            Write-Output "$(Get-Date) - P2S Client cert: $CertSubject created"
        }
        else {
            Write-Output "$(Get-Date) - P2S Client cert: $CertSubject already exists, skipping"
        }

        # Export root certificate as .cert file
        $FileCert = $CertPath + 'P2SRoot' + $ClientNumb + '.cert'
        $CertRoot = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq "CN=P2SRootCert" }

        if ($null -eq $CertRoot) {
            Write-Output "$(Get-Date) - Root Certificate CN=P2SRootCert not found"
            Write-Output "Stop processing!"
            Exit
        }
        else {
            Export-Certificate -Cert $CertRoot -FilePath $FileCert -Force | Out-Null
            Write-Output "$(Get-Date) - Created the file: $FileCert"
        }

        # Convert to .cer format
        $FileCer = $CertPath + 'P2SRoot' + $ClientNumb + '.cer'
        Write-Output "$(Get-Date) - Creating root certificate in $FileCer"

        if (-not (Test-Path -Path $FileCer)) {
            certutil -encode $FileCert $FileCer | Out-Null
            Write-Output "$(Get-Date) - Created root cer file"
        }
        else {
            Write-Output "$(Get-Date) - Root .cer file exists, skipping"
        }

        # Export client certificate
        $CertFilePath = $CertPath + 'certClient' + $ClientNumb + '.pfx'
        $mypwd = Read-Host -AsSecureString -Prompt "Enter secure password for client certificate"
        $CertClient = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -eq $CertSubject }
        Export-PfxCertificate -cert $CertClient -FilePath $CertFilePath -Password $mypwd

        # Write password file
        $PwdFile = $CertPath + 'certpwd.txt'
        Write-Output ""
        Write-Information "Writing password file: $PwdFile" -InformationAction Continue
        Out-File -FilePath $PwdFile -Force -InputObject $PwdCertificates

        Write-Output "$(Get-Date) - Completed certificate creation for client $ClientNumb"
    }

    Write-Output "Root and Client Certificate creation completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}