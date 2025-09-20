#Requires -Version 7.0

<#`n.SYNOPSIS
    Chocoinstall

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()
try {
    # Main script execution
]
$ErrorActionPreference = "Stop"
[CmdletBinding()]
param([Parameter(Mandatory)][Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$chocoPackages)
Write-Host "File packages URL: $linktopackages"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
$sb = { iex ((new-object -ErrorAction Stop net.webclient).DownloadString('https://chocolatey.org/install.ps1')) }
Invoke-Command -ScriptBlock $sb
$sb = { Set-ItemProperty -path HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System -name EnableLua -value 0 }
Invoke-Command -ScriptBlock $sb
$chocoPackages.Split(" ;" ) | ForEach {
    choco install $_ -y -force
}
Write-Host "Packages from choco.org were installed"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
