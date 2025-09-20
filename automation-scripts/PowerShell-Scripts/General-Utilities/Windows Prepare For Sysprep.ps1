<#
.SYNOPSIS
    Windows Prepare For Sysprep

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
Write-Host " === Removing Microsoft.Winget.Source for all users"
Get-AppxPackage -AllUsers Microsoft.Winget.Source* | Remove-AppPackage -ErrorAction Continue
$wingetUrl = getNewestLink(" msixbundle" )
$wingetLicenseUrl = getNewestLink("License1.xml" )
Write-Host " === Downloadng winget bundle from $wingetUrl and its license from $wingetLicenseUrl";
$wingetPath = " $env:TEMP/winget.msixbundle"
Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath;
$wingetLicensePath = " $env:TEMP/winget-license.xml"
Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath
Write-Host " === Installing winget bundle from $wingetPath and license from $wingetLicensePath"
Add-AppxProvisionedPackage -Online -PackagePath $wingetPath -LicensePath $wingetLicensePath -ErrorAction Continue\n