#Requires -Version 7.4

<#
.SYNOPSIS
    Install NetApp PowerShell Toolkit

.DESCRIPTION
    Downloads and installs the NetApp PowerShell Toolkit for Azure automation tasks.
    Creates necessary directories and configures the toolkit for use.

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: Administrative permissions and internet connectivity
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    # Create NetApp directory
    $netAppPath = "C:\NetApp"
    Write-Verbose "Creating directory: $netAppPath"
    New-Item -Path $netAppPath -ItemType Directory -Force -ErrorAction Stop | Out-Null

    # Download NetApp PowerShell Toolkit
    $downloadUrl = "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/application-workloads/netapp/netapp-ontap-sql/scripts/NetApp_PowerShell_Toolkit_4.3.0.msi"
    $installerPath = "$netAppPath\NetApp_PowerShell_Toolkit_4.3.0.msi"

    Write-Verbose "Downloading NetApp PowerShell Toolkit from: $downloadUrl"
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, $installerPath)
    $webClient.Dispose()

    # Install the toolkit
    Write-Verbose "Installing NetApp PowerShell Toolkit"
    $msiArgs = "/i `"$installerPath`" /qn ADDLOCAL=F.PSTKDOT"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -NoNewWindow

    Write-Output "NetApp PowerShell Toolkit installation completed successfully"
}
catch {
    Write-Error "Failed to install NetApp PowerShell Toolkit: $($_.Exception.Message)"
    throw
}