<#
.SYNOPSIS
    Winrm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Winrm

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WECert = New-SelfSignedCertificate -DnsName $WERemoteHostName, $WEComputerName `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -FriendlyName " Test WinRM Cert"

$WECert | Out-String
; 
$WEThumbprint = $WECert.Thumbprint

Write-WELog " Enable HTTPS in WinRM" " INFO" ; 
$WEWinRmHttps = " @{Hostname=`" $WERemoteHostName`" ; CertificateThumbprint=`" $WEThumbprint`" }"
winrm create winrm/config/Listener?Address=*+Transport=HTTPS $WEWinRmHttps

Write-WELog " Set Basic Auth in WinRM" " INFO"
$WEWinRmBasic = " @{Basic=`" true`" }"
winrm set winrm/config/service/Auth $WEWinRmBasic

Write-WELog " Open Firewall Port" " INFO"
netsh advfirewall firewall add rule name=" Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5985


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================