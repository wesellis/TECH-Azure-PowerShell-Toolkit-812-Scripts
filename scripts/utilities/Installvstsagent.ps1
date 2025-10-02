#Requires -Version 7.4

<#
.SYNOPSIS
    Install Azure DevOps Agent

.DESCRIPTION
    Installs and configures Azure DevOps agent with autologon support

.PARAMETER VSTSAccount
    Azure DevOps organization name

.PARAMETER PersonalAccessToken
    Personal Access Token for Azure DevOps authentication

.PARAMETER AgentName
    Name for the agent

.PARAMETER PoolName
    Agent pool name

.PARAMETER RunAsAutoLogon
    Whether to run as autologon

.PARAMETER VmAdminUserName
    VM administrator username

.PARAMETER VmAdminPassword
    VM administrator password

.EXAMPLE
    .\Installvstsagent.ps1 -VSTSAccount "myorg" -PersonalAccessToken "token" -AgentName "agent1" -PoolName "default" -RunAsAutoLogon "false"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VSTSAccount,

    [Parameter(Mandatory = $true)]
    [string]$PersonalAccessToken,

    [Parameter(Mandatory = $true)]
    [string]$AgentName,

    [Parameter(Mandatory = $true)]
    [string]$PoolName,

    [Parameter(Mandatory = $true)]
    [string]$RunAsAutoLogon,

    [Parameter(Mandatory = $false)]
    [string]$VmAdminUserName,

    [Parameter(Mandatory = $false)]
    [string]$VmAdminPassword
)

$ErrorActionPreference = "Stop"
function PrepMachineForAutologon {
    $ComputerName = "localhost"
    $password = Read-Host -Prompt "Enter secure value" -AsSecureString
    if ($VmAdminUserName.Split("\").Count -eq 2) {
        $domain = $VmAdminUserName.Split("\")[0]
        $UserName = $VmAdminUserName.Split('\')[1]
    }
    else {
        $domain = $Env:ComputerName
        $UserName = $VmAdminUserName
        Write-Verbose "Username constructed to use for creating a PSSession: $domain\$UserName"
    }
    $credentials = New-Object -ErrorAction Stop System.Management.Automation.PSCredential("$domain\$UserName", $password)
    Enter-PSSession -ComputerName $ComputerName -Credential $credentials
    Exit-PSSession
    $ErrorActionPreference = "stop"
    try {
        Get-PSDrive -PSProvider Registry -Name HKU | Out-Null
    $CanCheckRegistry = $true
    }
    catch [System.Management.Automation.DriveNotFoundException] {
        try {
            New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
    $CanCheckRegistry = $true
        }
        catch {
            Write-Warning "Moving ahead with agent setup as the script failed to create HKU drive necessary for checking if the registry entry for the user's SId exists. $_"
        }
    }
    $timeout = 120
    while ($timeout -ge 0 -and $CanCheckRegistry) {
    $ObjUser = New-Object -ErrorAction Stop System.Security.Principal.NTAccount($VmAdminUserName)
    $SecurityId = $ObjUser.Translate([System.Security.Principal.SecurityIdentifier])
    $SecurityId = $SecurityId.Value
        if (Test-Path "HKU:\$SecurityId") {
            if (!(Test-Path "HKU:\$SecurityId\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")) {
                New-Item -Path "HKU:\$SecurityId\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Force
                Write-Output "Created the registry entry path required to enable autologon."
            }
            break
        }
        else {
            $timeout -= 10
            Start-Sleep(10)
        }
    }
    if ($timeout -lt 0) {
        Write-Warning "Failed to find the registry entry for the SId of the user, this is required to enable autologon. Trying to start the agent anyway."
    }
}
Write-Verbose "Entering InstallVSOAgent.ps1" -verbose
    $CurrentLocation = Split-Path -parent $MyInvocation.MyCommand.Definition
Write-Verbose "Current folder: $CurrentLocation" -verbose
    $AgentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $AgentTempFolderName
Write-Verbose "Temporary Agent download folder: $AgentTempFolderName" -verbose
    $ServerUrl = "https://dev.azure.com/$VSTSAccount"
Write-Verbose "Server URL: $ServerUrl" -verbose
    $RetryCount = 3
    $retries = 1
Write-Verbose "Downloading Agent install files" -verbose
do {
    try {
        Write-Verbose "Trying to get download URL for latest Azure DevOps agent release..."
        $LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases"
        $LatestRelease = $LatestRelease | Where-Object assets -ne $null | Sort-Object created_at -Descending | Select-Object -First 1
        $AssetsURL = ($LatestRelease.assets).browser_download_url
        $LatestReleaseDownloadUrl = ((Invoke-RestMethod -Uri $AssetsURL) -match 'win-x64').downloadurl
        Invoke-WebRequest -Uri $LatestReleaseDownloadUrl -Method Get -OutFile "$AgentTempFolderName\agent.zip"
        Write-Verbose "Downloaded agent successfully on attempt $retries" -verbose
        break
    }
    catch {
        $ExceptionText = ($_ | Out-String).Trim()
        Write-Verbose "Exception occurred downloading agent: $ExceptionText in try number $retries" -verbose
        $retries++
        Start-Sleep -Seconds 30
    }
}
while ($retries -le $RetryCount)
    $AgentInstallationPath = Join-Path "C:" $AgentName
New-Item -ItemType Directory -Force -Path $AgentInstallationPath
New-Item -ItemType Directory -Force -Path (Join-Path $AgentInstallationPath $WorkFolder)
Write-Verbose "Extracting the zip file for the agent" -verbose;
    $DestShellFolder = (New-Object -ComObject shell.application).namespace("$AgentInstallationPath")
    $DestShellFolder.CopyHere((New-Object -ComObject shell.application).namespace("$AgentTempFolderName\agent.zip").Items(), 16)
Write-Verbose "Unblocking files" -verbose
Get-ChildItem -Recurse -Path $AgentInstallationPath | Unblock-File | out-null
    $AgentConfigPath = [System.IO.Path]::Combine($AgentInstallationPath, 'config.cmd')
Write-Verbose "Agent Location = $AgentConfigPath" -Verbose
if (![System.IO.File]::Exists($AgentConfigPath)) {
    Write-Error "File not found: $AgentConfigPath" -Verbose
    return
}
Write-Verbose "Configuring agent" -Verbose
Push-Location -Path $AgentInstallationPath
if ($RunAsAutoLogon -ieq "true") {
    PrepMachineForAutologon
    .\config.cmd --unattended --url $ServerUrl --auth PAT --token $PersonalAccessToken --pool $PoolName --agent $AgentName --runAsAutoLogon --overwriteAutoLogon --windowslogonaccount $VmAdminUserName --windowslogonpassword $VmAdminPassword
}
else {
    .\config.cmd --unattended --url $ServerUrl --auth PAT --token $PersonalAccessToken --pool $PoolName --agent $AgentName --runasservice
}
Pop-Location
Write-Verbose "Agent install output: $LASTEXITCODE" -Verbose
Write-Verbose "Exiting InstallVSTSAgent.ps1" -Verbose



