#Requires -Version 7.4

<#
.SYNOPSIS
    Installs and configures a GitHub Actions self-hosted runner agent.

.DESCRIPTION
    Downloads, installs, and configures a GitHub Actions self-hosted runner agent.
    Automatically retrieves the latest runner version and configures it to run as a service.

.PARAMETER GitHubRepo
    The GitHub repository (org/repo or user/repo format) to register the runner with.

.PARAMETER GitHubPAT
    Personal Access Token with appropriate permissions to register runners.

.PARAMETER AgentName
    Name for the runner agent and installation directory.

.EXAMPLE
    .\Installgithubagent.ps1 -GitHubRepo "myorg/myrepo" -GitHubPAT "ghp_xxxxxxxxxxxx" -AgentName "MyRunner01"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GitHubRepo,

    [Parameter(Mandatory = $true)]
    [string]$GitHubPAT,

    [Parameter(Mandatory = $true)]
    [string]$AgentName
)

$ErrorActionPreference = "Stop"

Write-Verbose "Entering InstallGitHubAgent.ps1" -Verbose
$CurrentLocation = Split-Path -Parent $MyInvocation.MyCommand.Definition
Write-Verbose "Current folder: $CurrentLocation" -Verbose

$AgentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $AgentTempFolderName
Write-Verbose "Temporary Agent download folder: $AgentTempFolderName" -Verbose

$ServerUrl = "https://github.com/$GitHubRepo"
Write-Verbose "Server URL: $ServerUrl" -Verbose

$RetryCount = 3
$retries = 1

Write-Verbose "Downloading Agent install files" -Verbose
do {
    try {
        Write-Verbose "Trying to get download URL for latest GitHub agent release..."
        $LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/actions/runner/releases"
        $LatestRelease = $LatestRelease | Where-Object assets -ne $null | Sort-Object created_at -Descending | Select-Object -First 1
        $AssetsURL = ($LatestRelease.assets).browser_download_url
        $LatestReleaseDownloadUrl = $AssetsURL -match 'win-x64' | Select-Object -First 1
        Invoke-WebRequest -Uri $LatestReleaseDownloadUrl -Method Get -OutFile "$AgentTempFolderName\agent.zip"
        Write-Verbose "Downloaded agent successfully on attempt $retries" -Verbose
        break
    }
    catch {
        $ExceptionText = ($_ | Out-String).Trim()
        Write-Verbose "Exception occurred downloading agent: $ExceptionText in try number $retries" -Verbose
        $retries++
        Start-Sleep -Seconds 30
    }
}
while ($retries -le $RetryCount)

$AgentInstallationPath = Join-Path "C:" $AgentName
New-Item -ItemType Directory -Force -Path $AgentInstallationPath
Write-Verbose "Extracting the zip file for the agent" -Verbose

$DestShellFolder = (New-Object -ComObject Shell.Application).namespace($AgentInstallationPath)
$DestShellFolder.CopyHere((New-Object -ComObject Shell.Application).namespace("$AgentTempFolderName\agent.zip").Items(), 16)

Write-Verbose "Unblocking files" -Verbose
Get-ChildItem -Recurse -Path $AgentInstallationPath | Unblock-File | Out-Null

$AgentConfigPath = [System.IO.Path]::Combine($AgentInstallationPath, 'config.cmd')
Write-Verbose "Agent Location = $AgentConfigPath" -Verbose

if (![System.IO.File]::Exists($AgentConfigPath)) {
    Write-Error "File not found: $AgentConfigPath" -Verbose
    return
}

Write-Verbose "Configuring agent" -Verbose
Push-Location -Path $AgentInstallationPath

Write-Verbose "Retrieving runner token" -Verbose
$BaseUri = "https://api.github.com/orgs"
if (-1 -ne $GitHubRepo.IndexOf("/")) {
    $BaseUri = "https://api.github.com/repos"
}

$headers = @{
    authorization = "token $GitHubPAT"
    accept = "application/vnd.github.everest-preview+json"
}

$r = Invoke-RestMethod -Uri "$BaseUri/$GitHubRepo/actions/runners/registration-token" -Headers $headers -Method POST
$GitHubToken = $r.token

.\config.cmd --unattended --url $ServerUrl --token $GitHubToken --runasservice

Pop-Location
Write-Verbose "Agent install output: $LASTEXITCODE" -Verbose
Write-Verbose "Exiting InstallGitHubAgent.ps1" -Verbose