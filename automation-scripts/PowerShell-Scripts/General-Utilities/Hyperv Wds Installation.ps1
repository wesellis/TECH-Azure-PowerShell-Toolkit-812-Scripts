#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Hyperv Wds Installation

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
    We Enhanced Hyperv Wds Installation

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

Write-Output " Installing Hyper-V..."
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools


Write-Output " Configuring firewall rules for Hyper-V..."
Set-NetFirewallRule -Name " Remote Desktop - User Mode (TCP-In)" -Enabled True
Set-NetFirewallRule -Name " Remote Desktop - User Mode (UDP-In)" -Enabled True
Set-NetFirewallRule -Name " Remote Event Log Management (RPC)" -Enabled True


Write-Output " Downloading Microsoft Deployment Toolkit..."
$mdtInstallerPath = " C:\Temp\MDT\MicrosoftDeploymentToolkit_x64.msi"; 
$mdtInstallerUrl = " https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi" ; 
$mdtInstallerFolder = Split-Path $mdtInstallerPath -Parent
if (!(Test-Path $mdtInstallerFolder)) {
    Write-Output " Creating directory $mdtInstallerFolder..."
    New-Item -Path $mdtInstallerFolder -ItemType Directory
}
Invoke-WebRequest -Uri $mdtInstallerUrl -OutFile $mdtInstallerPath


Write-Output " Installing Microsoft Deployment Toolkit..."
Start-Process -FilePath msiexec.exe -ArgumentList " /i `" $mdtInstallerPath`" /qn" -Wait


Write-Output " Configuring firewall rules for Microsoft Deployment Toolkit..."
New-NetFirewallRule -DisplayName " MDT Deployment Share" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow


Write-Output " Restarting the computer..."
Restart-Computer -Force



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
