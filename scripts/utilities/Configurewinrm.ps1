#Requires -Version 7.4

<#
.SYNOPSIS
    Configure WinRM for HTTPS

.DESCRIPTION
    Azure automation script to configure WinRM with HTTPS listener and certificate

.PARAMETER HostName
    The hostname for the WinRM HTTPS configuration

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$HostName
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Verbose "[$Timestamp] [$Level] $Message"
}

function Remove-WinRMListener {
    Write-Log "Checking for existing HTTPS listeners..."

    try {
        $config = winrm enumerate winrm/config/listener
        foreach ($conf in $config) {
            if ($conf.Contains("HTTPS")) {
                Write-Log "HTTPS is already configured. Deleting the existing configuration."
                winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
                break
            }
        }
    }
    catch {
        Write-Log "Exception while deleting the listener: $($_.Exception.Message)" "WARN"
    }
}

function New-WinRMCertificate {
    param(
        [string]$HostName
    )

    Write-Log "Creating new certificate for hostname: $HostName"

    # Check if makecert.exe exists
    $makecertPath = ".\makecert.exe"
    if (-not (Test-Path $makecertPath)) {
        Write-Log "makecert.exe not found, using New-SelfSignedCertificate instead" "WARN"

        # Use PowerShell cmdlet instead
        $cert = New-SelfSignedCertificate -DnsName $HostName `
                                         -CertStoreLocation "Cert:\LocalMachine\My" `
                                         -KeyExportPolicy Exportable `
                                         -KeySpec KeyExchange `
                                         -KeyLength 2048 `
                                         -KeyUsageProperty All `
                                         -Provider "Microsoft RSA SChannel Cryptographic Provider" `
                                         -NotAfter (Get-Date).AddYears(1)

        return $cert.Thumbprint
    }
    else {
        $serial = Get-Random
        $EndDate = (Get-Date).AddYears(1).ToString("MM/dd/yyyy")

        & $makecertPath -r -pe -n "CN=$HostName" -b 01/01/2012 -e $EndDate `
                       -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localmachine -sky exchange `
                       -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12 -# $serial 2>&1 | Out-Null

        $thumbprint = (Get-ChildItem cert:\LocalMachine\my |
                      Where-Object { $_.Subject -eq "CN=$HostName" } |
                      Select-Object -Last 1).Thumbprint

        if (-not $thumbprint) {
            throw "Failed to create the test certificate."
        }

        return $thumbprint
    }
}

function Set-WinRMHttpsListener {
    param(
        [string]$HostName,
        [string]$Port = "5986"
    )

    Write-Log "Configuring WinRM HTTPS listener on port $Port"

    Remove-WinRMListener

    # Get existing certificate or create new one
    $cert = Get-ChildItem cert:\LocalMachine\My |
            Where-Object { $_.Subject -eq "CN=$HostName" } |
            Select-Object -Last 1

    $thumbprint = $cert.Thumbprint

    if (-not $thumbprint) {
        $thumbprint = New-WinRMCertificate -HostName $HostName
    }
    elseif (-not $cert.PrivateKey) {
        Write-Log "Certificate exists but has no private key, recreating..." "WARN"
        Remove-Item -Path "Cert:\LocalMachine\My\$thumbprint" -Force
        $thumbprint = New-WinRMCertificate -HostName $HostName
    }

    Write-Log "Using certificate with thumbprint: $thumbprint"

    # Create WinRM HTTPS listener
    $WinrmCreate = "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=`"$HostName`";CertificateThumbprint=`"$thumbprint`"}"
    Invoke-Expression $WinrmCreate

    # Enable basic authentication
    winrm set winrm/config/service/auth '@{Basic="true"}'

    Write-Log "WinRM HTTPS listener configured successfully"
}

function Add-FirewallException {
    param(
        [string]$Port
    )

    Write-Log "Adding firewall exception for port $Port"

    # Remove existing rule if it exists
    netsh advfirewall firewall delete rule name="Windows Remote Management (HTTPS-In)" dir=in protocol=TCP localport=$Port 2>$null

    # Add new firewall rule
    netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" `
                                       dir=in action=allow protocol=TCP localport=$Port

    Write-Log "Firewall exception added successfully"
}

try {
    $WinrmHttpsPort = 5986

    Write-Log "Starting WinRM HTTPS configuration for hostname: $HostName"

    # Set WinRM max envelope size
    winrm set winrm/config '@{MaxEnvelopeSizekb="8192"}'

    # Configure WinRM HTTPS listener
    Set-WinRMHttpsListener -HostName $HostName -Port $WinrmHttpsPort

    # Add firewall exception
    Add-FirewallException -Port $WinrmHttpsPort

    Write-Log "WinRM HTTPS configuration completed successfully"
}
catch {
    Write-Error "Failed to configure WinRM: $($_.Exception.Message)"
    throw
}