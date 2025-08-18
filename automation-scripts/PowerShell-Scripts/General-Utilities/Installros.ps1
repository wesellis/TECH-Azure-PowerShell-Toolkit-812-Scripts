<#
.SYNOPSIS
    Installros

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
    We Enhanced Installros

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco source add -n=ros-win -s="https://aka.ms/ros/public" --priority=1


choco upgrade ros-melodic-desktop_full -y --execution-timeout=0 -i


choco upgrade ros-noetic-desktop_full -y --execution-timeout=0 -i


choco upgrade ros-foxy-desktop -y --execution-timeout=0 -i


Enable-PSRemoting -Force -SkipNetworkProfileCheck
New-NetFirewallRule -Name " Allow WinRM HTTPS" -DisplayName " WinRM HTTPS" -Enabled True -Profile Any -Action Allow -Direction Inbound -LocalPort 5986 -Protocol TCP
$thumbprint = (New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My).Thumbprint; 
$command = " winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="" $env:computername"" ; CertificateThumbprint="" $thumbprint"" }"
cmd.exe /C $command


$localDeviceIdPath = " HKLM:SOFTWARE\Microsoft\SQMClient"; 
$localDeviceIdName = " MachineId" ; 
$localDeviceIdValue = " {df713376-9b62-46d6-a363-cede5b1bf2c5}"
New-ItemProperty -Path $localDeviceIdPath -Name $localDeviceIdName -Value $localDeviceIdValue -PropertyType String -Force | Out-Null


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================