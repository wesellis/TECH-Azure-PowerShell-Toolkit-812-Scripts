#Requires -Version 7.4
#Requires -Modules PsDesiredStateConfiguration

<#
.SYNOPSIS
    DSC Configuration for deploying Azure DevOps agents

.DESCRIPTION
    This DSC configuration deploys and configures Azure DevOps (formerly VSTS) agents on Windows VMs.
    It downloads the latest agent, installs multiple instances, and configures them as Windows services.

.PARAMETER MachineName
    The target machine name for the DSC configuration

.PARAMETER UserName
    Username for agent service account

.PARAMETER Password
    Password for agent service account

.PARAMETER VSTSAccount
    Azure DevOps organization name

.PARAMETER PersonalAccessToken
    Personal Access Token for Azure DevOps authentication

.PARAMETER AgentName
    Base name for the agents (will be numbered sequentially)

.PARAMETER PoolName
    Name of the agent pool to join

.PARAMETER AgentCount
    Number of agents to install

.PARAMETER Modules
    PowerShell modules to install for the agents

.EXAMPLE
    DeployVSTSAgent -MachineName "BuildServer01" -UserName "builduser" -Password "password" -VSTSAccount "myorg" -PersonalAccessToken "pat" -AgentName "BuildAgent" -PoolName "Default" -AgentCount 2 -Modules @("Az")

.AUTHOR
    Sampanna Mohite / Nazakat Hussain
    Modified by Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Creation Date: 12/03/2018
    Purpose/Change: Automated Deployments of Azure DevOps Agents
#>

Configuration DeployVSTSAgent {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$MachineName = $env:COMPUTERNAME,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Password,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$VSTSAccount,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PersonalAccessToken,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AgentName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PoolName,

        [Parameter(Mandatory)]
        [int]$AgentCount,

        [Parameter(Mandatory)]
        [string[]]$Modules
    )

    Import-DscResource -ModuleName PsDesiredStateConfiguration

    Node $MachineName {
        Script SetVstsAgents {
            GetScript = {
                @{
                    Result = "Azure DevOps agents configuration"
                }
            }
            TestScript = {
                $false
            }
            SetScript = {
                $ErrorActionPreference = "Stop"

                Write-Verbose "Azure DevOps Account: $using:VSTSAccount" -Verbose
                Write-Verbose "Agent count: $using:AgentCount" -Verbose
                Write-Verbose "Starting Azure DevOps agent deployment" -Verbose

                $AgentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName()).replace('.', '')
                New-Item -ItemType Directory -Force -Path $AgentTempFolderName
                Write-Verbose "Temporary Agent download folder: $AgentTempFolderName" -Verbose

                $ServerUrl = "https://dev.azure.com/$using:VSTSAccount"
                Write-Verbose "Server URL: $ServerUrl" -Verbose

                $RetryCount = 3
                $retries = 1

                Write-Verbose "Downloading Agent install files" -Verbose
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                do {
                    try {
                        Write-Verbose "Trying to get download URL for latest Azure DevOps agent release..." -Verbose
                        $LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases"
                        $LatestRelease = $LatestRelease | Where-Object assets -ne $null | Sort-Object created_at -Descending | Select-Object -First 1
                        $WindowsAsset = $LatestRelease.assets | Where-Object { $_.name -like "*win-x64*" }
                        $LatestReleaseDownloadUrl = $WindowsAsset.browser_download_url

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

                Write-Verbose "Installing $using:AgentCount agents" -Verbose

                for ($i = 0; $i -lt $using:AgentCount; $i++) {
                    $Agent = ($using:AgentName + "-" + ($i + 1))
                    Write-Verbose "Installing agent: $Agent" -Verbose

                    $AgentInstallationPath = Join-Path "C:" $Agent
                    New-Item -ItemType Directory -Force -Path $AgentInstallationPath

                    Push-Location -Path $AgentInstallationPath

                    Write-Verbose "Extracting the zip file for the agent" -Verbose
                    Expand-Archive -Path "$AgentTempFolderName\agent.zip" -DestinationPath $AgentInstallationPath -Force

                    Write-Verbose "Unblocking files" -Verbose
                    Get-ChildItem -Recurse -Path $AgentInstallationPath | Unblock-File

                    $AgentConfigPath = [System.IO.Path]::Combine($AgentInstallationPath, 'config.cmd')
                    Write-Verbose "Agent Location = $AgentConfigPath" -Verbose

                    if (![System.IO.File]::Exists($AgentConfigPath)) {
                        Write-Error "File not found: $AgentConfigPath"
                        return
                    }

                    Write-Verbose "Configuring agent '$Agent'" -Verbose
                    $pat = $using:PersonalAccessToken
                    & .\config.cmd --unattended --url $ServerUrl --auth PAT --token $pat --pool $using:PoolName --agent $Agent --runasservice
                    Write-Verbose "Agent install exit code: $LASTEXITCODE" -Verbose

                    Pop-Location
                }

                $CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
                [Environment]::SetEnvironmentVariable("PSModulePath", $CurrentValue + ";C:\Modules", "Machine")
                $NewValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
                Write-Verbose "New PSModulePath: $NewValue" -Verbose

                if (!(Test-Path -Path C:\Modules -ErrorAction SilentlyContinue)) {
                    New-Item -ItemType Directory -Name Modules -Path C:\ -Verbose
                }

                foreach ($Module in $using:Modules) {
                    try {
                        if (Get-Module -Name $Module -ListAvailable -ErrorAction SilentlyContinue) {
                            Remove-Module -Name $Module -Force -ErrorAction SilentlyContinue
                        }
                        Find-Module -Name $Module -Repository PSGallery -Verbose | Install-Module -Force -Confirm:$false -SkipPublisherCheck -Verbose
                    }
                    catch {
                        Write-Warning "Failed to install module $Module : $($_.Exception.Message)"
                    }
                }

                Write-Verbose "Azure DevOps agent deployment completed" -Verbose
            }
        }
    }
}
