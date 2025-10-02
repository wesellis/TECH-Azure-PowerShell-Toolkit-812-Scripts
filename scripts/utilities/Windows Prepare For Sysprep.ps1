#Requires -Version 7.4

<#`n.SYNOPSIS
    Windows Prepare For Sysprep

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'
function getNewestLink($match) {
    $uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $get = Invoke-RestMethod -uri $uri -Method Get
    $data = $get[0].assets | Where-Object name -Match $match
    return $data.browser_download_url
}
Write-Output " === Removing Microsoft.Winget.Source for all users"
Get-AppxPackage -AllUsers Microsoft.Winget.Source* | Remove-AppPackage -ErrorAction Continue
$WingetUrl = getNewestLink(" msixbundle" )
$WingetLicenseUrl = getNewestLink("License1.xml" )
Write-Output " === Downloadng winget bundle from $WingetUrl and its license from $WingetLicenseUrl";
$WingetPath = " $env:TEMP/winget.msixbundle"
Invoke-WebRequest -Uri $WingetUrl -OutFile $WingetPath;
$WingetLicensePath = " $env:TEMP/winget-license.xml"
Invoke-WebRequest -Uri $WingetLicenseUrl -OutFile $WingetLicensePath
Write-Output " === Installing winget bundle from $WingetPath and license from $WingetLicensePath"
Add-AppxProvisionedPackage -Online -PackagePath $WingetPath -LicensePath $WingetLicensePath -ErrorAction Continue


