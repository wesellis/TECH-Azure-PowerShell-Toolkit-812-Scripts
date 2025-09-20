#Requires -Version 7.0

<#`n.SYNOPSIS
    Installvstsagent

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory = $true)]$VSTSAccount,
    [Parameter(Mandatory = $true)]$PersonalAccessToken,
    [Parameter(Mandatory = $true)]$AgentName,
    [Parameter(Mandatory = $true)]$PoolName,
    [Parameter(Mandatory = $true)]$runAsAutoLogon,
    [Parameter(Mandatory = $false)]$vmAdminUserName,
    [Parameter(Mandatory = $false)]$vmAdminPassword
)
function PrepMachineForAutologon () {
    # Create a PS session for the user to trigger the creation of the registry entries required for autologon
    $computerName = " localhost"
    $password = Read-Host -Prompt "Enter secure value" -AsSecureString
    if ($vmAdminUserName.Split(" \" ).Count -eq 2) {
        $domain = $vmAdminUserName.Split(" \" )[0]
        $userName = $vmAdminUserName.Split('\')[1]
    }
    else {
        $domain = $Env:ComputerName
        $userName = $vmAdminUserName
        Write-Verbose "Username constructed to use for creating a PSSession: $domain\\$userName"
    }
    $credentials = New-Object -ErrorAction Stop System.Management.Automation.PSCredential(" $domain\\$userName" , $password)
    Enter-PSSession -ComputerName $computerName -Credential $credentials
    Exit-PSSession
    $ErrorActionPreference = " stop"
    try {
        # Check if the HKU drive already exists
        Get-PSDrive -PSProvider Registry -Name HKU | Out-Null
        $canCheckRegistry = $true
    }
    catch [System.Management.Automation.DriveNotFoundException] {
        try {
            # Create the HKU drive
            New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
            $canCheckRegistry = $true
        }
        catch {
            # Ignore the failure to create the drive and go ahead with trying to set the agent up
            Write-Warning "Moving ahead with agent setup as the script failed to create HKU drive necessary for checking if the registry entry for the user's SId exists.
$_"
        }
    }
    # 120 seconds timeout
    $timeout = 120
    # Check if the registry key required for enabling autologon is present on the machine, if not wait for 120 seconds in case the user profile is still getting created
    while ($timeout -ge 0 -and $canCheckRegistry) {
        $objUser = New-Object -ErrorAction Stop System.Security.Principal.NTAccount($vmAdminUserName)
        $securityId = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        $securityId = $securityId.Value
        if (Test-Path "HKU:\\$securityId" ) {
            if (!(Test-Path "HKU:\\$securityId\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run" )) {
                New-Item -Path "HKU:\\$securityId\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run" -Force
                Write-Host "Created the registry entry path required to enable autologon."
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
$currentLocation = Split-Path -parent $MyInvocation.MyCommand.Definition
Write-Verbose "Current folder: $currentLocation" -verbose
$agentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $agentTempFolderName
Write-Verbose "Temporary Agent download folder: $agentTempFolderName" -verbose
$serverUrl = "https://dev.azure.com/$VSTSAccount"
Write-Verbose "Server URL: $serverUrl" -verbose
$retryCount = 3
$retries = 1
Write-Verbose "Downloading Agent install files" -verbose
do {
    try {
        Write-Verbose "Trying to get download URL for latest VSTS agent release..."
        $latestRelease = Invoke-RestMethod -Uri " https://api.github.com/repos/Microsoft/vsts-agent/releases"
        $latestRelease = $latestRelease | Where-Object assets -ne $null | Sort-Object created_at -Descending | Select-Object -First 1
        $assetsURL = ($latestRelease.assets).browser_download_url
        $latestReleaseDownloadUrl = ((Invoke-RestMethod -Uri $assetsURL) -match 'win-x64').downloadurl
        Invoke-WebRequest -Uri $latestReleaseDownloadUrl -Method Get -OutFile " $agentTempFolderName\agent.zip"
        Write-Verbose "Downloaded agent successfully on attempt $retries" -verbose
        break
    }
    catch {
        $exceptionText = ($_ | Out-String).Trim()
        Write-Verbose "Exception occured downloading agent: $exceptionText in try number $retries" -verbose
        $retries++
        Start-Sleep -Seconds 30
    }
}
while ($retries -le $retryCount)
$agentInstallationPath = Join-Path "C:" $AgentName
New-Item -ItemType Directory -Force -Path $agentInstallationPath
New-Item -ItemType Directory -Force -Path (Join-Path $agentInstallationPath $WorkFolder)
Write-Verbose "Extracting the zip file for the agent" -verbose;
$destShellFolder = (new-object -com shell.application).namespace(" $agentInstallationPath" )
$destShellFolder.CopyHere((new-object -com shell.application).namespace(" $agentTempFolderName\agent.zip" ).Items(), 16)
Write-Verbose "Unblocking files" -verbose
Get-ChildItem -Recurse -Path $agentInstallationPath | Unblock-File | out-null
$agentConfigPath = [System.IO.Path]::Combine($agentInstallationPath, 'config.cmd')
Write-Verbose "Agent Location = $agentConfigPath" -Verbose
if (![System.IO.File]::Exists($agentConfigPath)) {
    Write-Error "File not found: $agentConfigPath" -Verbose
    return
}
Write-Verbose "Configuring agent" -Verbose
Push-Location -Path $agentInstallationPath
if ($runAsAutoLogon -ieq " true" ) {
    PrepMachineForAutologon
    # Setup the agent with autologon enabled
    .\config.cmd --unattended --url $serverUrl --auth PAT --token $PersonalAccessToken --pool $PoolName --agent $AgentName --runAsAutoLogon --overwriteAutoLogon --windowslogonaccount $vmAdminUserName --windowslogonpassword $vmAdminPassword
}
else {
    # Setup the agent as a service
    .\config.cmd --unattended --url $serverUrl --auth PAT --token $PersonalAccessToken --pool $PoolName --agent $AgentName --runasservice
}
Pop-Location
Write-Verbose "Agent install output: $LASTEXITCODE" -Verbose
Write-Verbose "Exiting InstallVSTSAgent.ps1" -Verbose
