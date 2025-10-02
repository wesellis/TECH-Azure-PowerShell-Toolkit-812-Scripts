#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Nodejs

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
    $ErrorActionPreference = "Stop"
param(
    $Version = " 18.20.2" ,
    [bool]$UninstallExistingNodeVersion = $false
)
function Uninstall-ExistingNode {
    if ($UninstallExistingNodeVersion) {
        Write-Output "Checking for existing Node.js installations..."
    $node = Get-CimInstance -Class Win32_Product | Where-Object { $_.Name -match "Node.js" }
        if ($null -ne $node) {
            Write-Output "Existing Node.js installation found: $($node.Name), Version: $($node.Version). Uninstalling..."
    $UninstallResult = $node.Uninstall()
            if ($UninstallResult.ReturnValue -eq 0) {
                Write-Output "Successfully uninstalled existing Node.js version."
            } else {
                Write-Output "Failed to uninstall existing Node.js version. ReturnValue: $($UninstallResult.ReturnValue)"
            }
        } else {
            Write-Output "No existing Node.js installations found."
        }
    } else {
        Write-Output "Skipping uninstallation of existing Node.js versions."
    }
}
Uninstall-ExistingNode
try {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $source = "https://nodejs.org/dist/v$Version/node-v$Version-x64.msi"
    $destination = " $env:TEMP
ode-$Version-x64.msi"
    $InstallerArgs = "/i `" $destination`"/qn"
    Write-Output "Downloading NodeJS"
    Write-Output "Source: $source"
    Write-Output "Destination: $destination"
    Write-Output "Downloading Node.js version $Version"
    Invoke-WebRequest $source -OutFile $destination
    Write-Output "Download Complete, beginning installation..."
    Start-Process -FilePath msiexec -ArgumentList $InstallerArgs -Wait -NoNewWindow
    Write-Output "Node.js version $Version installation complete."
} catch {
    Write-Output $_
    Write-Error -Exception $_.Exception -ErrorAction Stop`n}
