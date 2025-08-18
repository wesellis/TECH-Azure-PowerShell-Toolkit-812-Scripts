<#
.SYNOPSIS
    Windows Nodejs

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
    We Enhanced Windows Nodejs

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [string]$WEVersion = " 18.20.2" ,
    [bool]$WEUninstallExistingNodeVersion = $false
)

function WE-Uninstall-ExistingNode {
    if ($WEUninstallExistingNodeVersion) {
        Write-WELog " Checking for existing Node.js installations..." " INFO"
        $node = Get-CimInstance -Class Win32_Product | Where-Object { $_.Name -match " Node.js" }
        if ($null -ne $node) {
            Write-WELog " Existing Node.js installation found: $($node.Name), Version: $($node.Version). Uninstalling..." " INFO"
            $uninstallResult = $node.Uninstall()
            if ($uninstallResult.ReturnValue -eq 0) {
                Write-WELog " Successfully uninstalled existing Node.js version." " INFO"
            } else {
                Write-WELog " Failed to uninstall existing Node.js version. ReturnValue: $($uninstallResult.ReturnValue)" " INFO"
            }
        } else {
            Write-WELog " No existing Node.js installations found." " INFO"
        }
    } else {
        Write-WELog " Skipping uninstallation of existing Node.js versions." " INFO"
    }
}


Uninstall-ExistingNode


try {
    $WEErrorActionPreference = 'Stop'
    $WEProgressPreference = 'SilentlyContinue'
    $source = " https://nodejs.org/dist/v$WEVersion/node-v$WEVersion-x64.msi"
   ;  $destination = " $env:TEMP\node-$WEVersion-x64.msi"

   ;  $WEInstallerArgs = " /i `" $destination`" /qn"

    Write-WELog " Downloading NodeJS" " INFO"
    Write-WELog " Source: $source" " INFO"
    Write-WELog " Destination: $destination" " INFO"
    Write-WELog " Downloading Node.js version $WEVersion" " INFO"
    Invoke-WebRequest $source -OutFile $destination
    Write-WELog " Download Complete, beginning installation..." " INFO"

    Start-Process -FilePath msiexec -ArgumentList $WEInstallerArgs -Wait -NoNewWindow
    Write-WELog " Node.js version $WEVersion installation complete." " INFO"
} catch {
    Write-Output $_
    Write-Error -Exception $_.Exception -ErrorAction Stop
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================