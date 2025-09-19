#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Installgithubagent

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
    We Enhanced Installgithubagent

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)]$WEGitHubRepo,
    [Parameter(Mandatory = $true)]$WEGitHubPAT,
    [Parameter(Mandatory = $true)]$WEAgentName
)

#region Functions

Write-Verbose " Entering InstallGitHubAgent.ps1" -verbose

$currentLocation = Split-Path -parent $WEMyInvocation.MyCommand.Definition
Write-Verbose " Current folder: $currentLocation" -verbose


$agentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $agentTempFolderName
Write-Verbose " Temporary Agent download folder: $agentTempFolderName" -verbose

$serverUrl = " https://github.com/$WEGitHubRepo"
Write-Verbose " Server URL: $serverUrl" -verbose

$retryCount = 3
$retries = 1
Write-Verbose " Downloading Agent install files" -verbose
do {
    try {
        Write-Verbose " Trying to get download URL for latest GitHub agent release..."
        $latestRelease = Invoke-RestMethod -Uri " https://api.github.com/repos/actions/runner/releases"
        $latestRelease = $latestRelease | Where-Object assets -ne $null | Sort-Object created_at -Descending | Select-Object -First 1
        $assetsURL = ($latestRelease.assets).browser_download_url
        $latestReleaseDownloadUrl = $assetsURL -match 'win-x64' | Select-Object -First 1
        Invoke-WebRequest -Uri $latestReleaseDownloadUrl -Method Get -OutFile " $agentTempFolderName\agent.zip"
        Write-Verbose " Downloaded agent successfully on attempt $retries" -verbose
        break
    }
    catch {
        $exceptionText = ($_ | Out-String).Trim()
        Write-Verbose " Exception occured downloading agent: $exceptionText in try number $retries" -verbose
        $retries++
        Start-Sleep -Seconds 30 
    }
} 
while ($retries -le $retryCount)


$agentInstallationPath = Join-Path " C:" $WEAgentName 

New-Item -ItemType Directory -Force -Path $agentInstallationPath 


New-Item -ItemType Directory -Force -Path (Join-Path $agentInstallationPath $WEWorkFolder)

Write-Verbose " Extracting the zip file for the agent" -verbose
$destShellFolder = (new-object -com shell.application).namespace(" $agentInstallationPath" )
$destShellFolder.CopyHere((new-object -com shell.application).namespace(" $agentTempFolderName\agent.zip" ).Items(), 16)


Write-Verbose " Unblocking files" -verbose
Get-ChildItem -Recurse -Path $agentInstallationPath | Unblock-File | out-null


$agentConfigPath = [System.IO.Path]::Combine($agentInstallationPath, 'config.cmd')
Write-Verbose " Agent Location = $agentConfigPath" -Verbose
if (![System.IO.File]::Exists($agentConfigPath)) {
    Write-Error " File not found: $agentConfigPath" -Verbose
    return
}



Write-Verbose " Configuring agent" -Verbose


Push-Location -Path $agentInstallationPath

Write-Verbose " Retrieving runner token" -Verbose

$baseUri = " https://api.github.com/orgs"
if (-1 -ne $WEGitHubRepo.IndexOf(" /" )) {
    $baseUri = " https://api.github.com/repos"
}

$headers = @{
    authorization = " token $WEGitHubPAT"
    accept = " application/vnd.github.everest-preview+json"
}
; 
$r = Invoke-RestMethod -Uri " $baseUri/$WEGitHubRepo/actions/runners/registration-token" -Headers $headers -Method POST; 
$WEGitHubToken = $r.token


.\config.cmd --unattended --url $serverUrl --token $WEGitHubToken --runasservice

Pop-Location

Write-Verbose " Agent install output: $WELASTEXITCODE" -Verbose

Write-Verbose " Exiting InstallGitHubAgent.ps1" -Verbose



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
