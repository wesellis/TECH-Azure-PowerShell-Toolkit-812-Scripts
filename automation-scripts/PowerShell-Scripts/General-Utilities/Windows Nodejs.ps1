<#
.SYNOPSIS
    Windows Nodejs

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string]$Version = " 18.20.2" ,
    [bool]$UninstallExistingNodeVersion = $false
)
function Uninstall-ExistingNode {
    if ($UninstallExistingNodeVersion) {
        Write-Host "Checking for existing Node.js installations..."
        $node = Get-CimInstance -Class Win32_Product | Where-Object { $_.Name -match "Node.js" }
        if ($null -ne $node) {
            Write-Host "Existing Node.js installation found: $($node.Name), Version: $($node.Version). Uninstalling..."
            $uninstallResult = $node.Uninstall()
            if ($uninstallResult.ReturnValue -eq 0) {
                Write-Host "Successfully uninstalled existing Node.js version."
            } else {
                Write-Host "Failed to uninstall existing Node.js version. ReturnValue: $($uninstallResult.ReturnValue)"
            }
        } else {
            Write-Host "No existing Node.js installations found."
        }
    } else {
        Write-Host "Skipping uninstallation of existing Node.js versions."
    }
}
Uninstall-ExistingNode
try {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    $source = "https://nodejs.org/dist/v$Version/node-v$Version-x64.msi"
$destination = " $env:TEMP\node-$Version-x64.msi"
$InstallerArgs = " /i `" $destination`" /qn"
    Write-Host "Downloading NodeJS"
    Write-Host "Source: $source"
    Write-Host "Destination: $destination"
    Write-Host "Downloading Node.js version $Version"
    Invoke-WebRequest $source -OutFile $destination
    Write-Host "Download Complete, beginning installation..."
    Start-Process -FilePath msiexec -ArgumentList $InstallerArgs -Wait -NoNewWindow
    Write-Host "Node.js version $Version installation complete."
} catch {
    Write-Output $_
    Write-Error -Exception $_.Exception -ErrorAction Stop
}

