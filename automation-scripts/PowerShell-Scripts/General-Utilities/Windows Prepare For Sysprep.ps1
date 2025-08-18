<#
.SYNOPSIS
    We Enhanced Windows Prepare For Sysprep

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

$WEErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$WEProgressPreference = 'SilentlyContinue'

function getNewestLink($match) {
    $uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $get = Invoke-RestMethod -uri $uri -Method Get
    $data = $get[0].assets | Where-Object name -Match $match
    return $data.browser_download_url
}


Write-WELog " === Removing Microsoft.Winget.Source for all users" " INFO"
Get-AppxPackage -AllUsers Microsoft.Winget.Source* | Remove-AppPackage -ErrorAction Continue


$wingetUrl = getNewestLink(" msixbundle")
$wingetLicenseUrl = getNewestLink(" License1.xml")

Write-WELog " === Downloadng winget bundle from $wingetUrl and its license from $wingetLicenseUrl" " INFO"
$wingetPath = " $env:TEMP/winget.msixbundle"
Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath; 
$wingetLicensePath = " $env:TEMP/winget-license.xml"
Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath

Write-WELog " === Installing winget bundle from $wingetPath and license from $wingetLicensePath" " INFO"
Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $wingetLicensePath -ErrorAction Continue


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================