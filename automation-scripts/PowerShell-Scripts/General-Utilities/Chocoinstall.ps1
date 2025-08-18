<#
.SYNOPSIS
    We Enhanced Chocoinstall

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

[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
param([Parameter(Mandatory=$true)][Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$chocoPackages)

Write-WELog "File packages URL: $linktopackages" " INFO"


Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force


[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072


$sb = { iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) }
Invoke-Command -ScriptBlock $sb 
; 
$sb = { Set-ItemProperty -path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -name EnableLua -value 0 }
Invoke-Command -ScriptBlock $sb 


$chocoPackages.Split(" ;") | ForEach {
    choco install $_ -y -force
}

Write-WELog " Packages from choco.org were installed" " INFO"


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
