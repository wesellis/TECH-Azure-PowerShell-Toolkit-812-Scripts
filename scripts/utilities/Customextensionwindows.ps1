#Requires -Version 7.4

<#
.SYNOPSIS
    Custom Extension Windows Installation Script

.DESCRIPTION
    Azure automation script for installing OpenVPN and configuring VPN client connections.
    This script downloads and installs OpenVPN, configures certificate policies, and sets up client connections.

.NOTES
    Version: 1.0
    Author: Wes Ellis (wes@wesellis.com)
    Requires appropriate permissions and modules
    Installs OpenVPN and configures VPN client connections
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Starting Custom Extension Windows installation..."

    # Download and install OpenVPN
    Write-Output "Downloading OpenVPN..."
    Invoke-WebRequest -Uri https://swupdate.openvpn.org/community/releases/OpenVPN-2.5-rc2-I601-2-amd64.msi -OutFile "C:\ovpn.msi"

    Write-Output "Installing OpenVPN..."
    Start-Process -FilePath "C:\ovpn.msi" -ArgumentList "/qn" -Wait
    Start-Sleep -Seconds 20

    # Set TLS 1.2 security protocol
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    function Ignore-SelfSignedCerts {
        <#
        .SYNOPSIS
            Configures the system to ignore self-signed certificate errors
        #>
        try {
            Write-Output "Adding TrustAllCertsPolicy type."
            Add-Type -TypeDefinition @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy
{
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem)
    {
        return true;
    }
}
"@
            Write-Output "TrustAllCertsPolicy type added."
        }
        catch {
            Write-Output $_ -ForegroundColor "Yellow"
        }
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }

    # Configure certificate policy to ignore self-signed certificates
    Ignore-SelfSignedCerts

    # VPN connection configuration
    $ip1 = "10.10.10.10"
    $user = "api"
    $pass = "VNS3Controller-10.10.10.10"
    $pair = "${user}:${pass}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $BasicAuthValue = "Basic $base64"

    # Create headers for API request
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $BasicAuthValue)
    $headers.Add("Accept", "application/octet-stream")

    # Download client configuration
    $clientpack1 = "100_127_255_193"
    Write-Output "Downloading VPN client configuration..."

    $configPath = "c:\Program Files\OpenVPN\config\$clientpack1.ovpn"
    Invoke-WebRequest -Uri "https://$ip1:8000/api/clientpack?name=$clientpack1&fileformat=ovpn" -UseBasicParsing -Headers $Headers -ContentType "application/json" -Method GET -OutFile $configPath

    # Start OpenVPN service
    Write-Output "Starting OpenVPN service..."
    Start-Service -Name "OpenVPNServiceInteractive"

    Write-Output "Custom Extension Windows installation completed successfully."
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}