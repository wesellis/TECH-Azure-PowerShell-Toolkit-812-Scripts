#Requires -Version 7.4

<#`n.SYNOPSIS
    Winrm

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$params = @{
    CertStoreLocation = "cert:\LocalMachine\My"
    FriendlyName = "Test WinRM Cert"
    DnsName = $RemoteHostName, $ComputerName
}
$Cert @params
$Cert | Out-String
$Thumbprint = $Cert.Thumbprint
Write-Output "Enable HTTPS in WinRM" ;
$WinRmHttps = " @{Hostname=`" $RemoteHostName`" ; CertificateThumbprint=`" $Thumbprint`" }"
winrm create winrm/config/Listener?Address=*+Transport=HTTPS $WinRmHttps
Write-Output "Set Basic Auth in WinRM"
$WinRmBasic = " @{Basic=`" true`" }"
winrm set winrm/config/service/Auth $WinRmBasic
Write-Output "Open Firewall Port"
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5985



