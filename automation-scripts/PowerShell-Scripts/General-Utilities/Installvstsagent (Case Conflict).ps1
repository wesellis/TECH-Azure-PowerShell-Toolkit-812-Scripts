#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Installvstsagent (Case Conflict)

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
    We Enhanced Installvstsagent (Case Conflict)

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
	[Parameter(Mandatory=$true)]
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVSTSAccount,

	[Parameter(Mandatory=$true)]
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPersonalAccessToken,

	[Parameter(Mandatory=$true)]
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAgentName,

	[Parameter(Mandatory=$true)]
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEPoolName,

	[Parameter(Mandatory=$true)]
	[int]$WEAgentCount,

	[Parameter(Mandatory=$true)]
	[Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAdminUser,

	[Parameter(Mandatory=$true)]
	[array]$WEModules,
	
	[boolean]$prerelease=$false
)

#region Functions

Write-Verbose " Entering InstallVSOAgent.ps1" -verbose

$currentLocation = Split-Path -parent $WEMyInvocation.MyCommand.Definition
Write-Verbose " Current folder: $currentLocation" -verbose


$agentTempFolderName = Join-Path $env:temp ([System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Force -Path $agentTempFolderName
Write-Verbose " Temporary Agent download folder: $agentTempFolderName" -verbose

$serverUrl = " https://dev.azure.com/$WEVSTSAccount"
Write-Verbose " Server URL: $serverUrl" -verbose

$retryCount = 3
$retries = 1
Write-Verbose " Downloading Agent install files" -verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
do
{
  try
  {
    Write-Verbose " Trying to get download URL for latest VSTS agent release..."
    $latestRelease = Invoke-RestMethod -Uri " https://api.github.com/repos/Microsoft/vsts-agent/releases"
	$latestRelease = $latestRelease |  Where-Object prerelease -eq $prerelease |where-object assets -ne $null | Sort-Object created_at -Descending | Select-Object -First 1
    $assetsURL = ($latestRelease.assets).browser_download_url
   ;  $latestReleaseDownloadUrl = ((Invoke-RestMethod -Uri $assetsURL) -match 'win-x64').downloadurl
    Invoke-WebRequest -Uri $latestReleaseDownloadUrl -Method Get -OutFile " $agentTempFolderName\agent.zip"
    Write-Verbose " Downloaded agent successfully on attempt $retries" -verbose
    break
  }
  catch
  {
   ;  $exceptionText = ($_ | Out-String).Trim()
    Write-Verbose " Exception occured downloading agent: $exceptionText in try number $retries" -verbose
    $retries++
    Start-Sleep -Seconds 30 
  }
} 
while ($retries -le $retryCount)

for ($i=0; $i -lt $WEAgentCount; $i++)
{
	$WEAgent = ($WEAgentName + " -" + $i)

	# Construct the agent folder under the main (hardcoded) C: drive.
	$agentInstallationPath = Join-Path " C:" $WEAgent

	# Create the directory for this agent.
	New-Item -ItemType Directory -Force -Path $agentInstallationPath

	# Set the current directory to the agent dedicated one previously created.
	Push-Location -Path $agentInstallationPath
	
	Write-Verbose " Extracting the zip file for the agent" -verbose
	$destShellFolder = (new-object -com shell.application).namespace(" $agentInstallationPath" )
	$destShellFolder.CopyHere((new-object -com shell.application).namespace(" $agentTempFolderName\agent.zip" ).Items(),16)

	# Removing the ZoneIdentifier from files downloaded from the internet so the plugins can be loaded
	# Don't recurse down _work or _diag, those files are not blocked and cause the process to take much longer
	Write-Verbose " Unblocking files" -verbose
	Get-ChildItem -Recurse -Path $agentInstallationPath | Unblock-File | out-null

	# Retrieve the path to the config.cmd file.
; 	$agentConfigPath = [System.IO.Path]::Combine($agentInstallationPath, 'config.cmd')
	Write-Verbose " Agent Location = $agentConfigPath" -Verbose
	if (![System.IO.File]::Exists($agentConfigPath))
	{
		Write-Error " File not found: $agentConfigPath" -Verbose
		return
	}

	# Call the agent with the configure command and all the options (this creates the settings file) without prompting
	# the user or blocking the cmd execution
	Write-Verbose " Configuring agent '$($WEAgent)'" -Verbose		
	.\config.cmd --unattended --url $serverUrl --auth PAT --token $WEPersonalAccessToken --pool $WEPoolName --agent $WEAgent --runasservice
	
	Write-Verbose " Agent install output: $WELASTEXITCODE" -Verbose
	
	Pop-Location
}

; 
$WECurrentValue = [Environment]::GetEnvironmentVariable(" PSModulePath" , " Machine" )
[Environment]::SetEnvironmentVariable(" PSModulePath" , $WECurrentValue + " ;C:\Modules" , " Machine" )
$WENewValue = [Environment]::GetEnvironmentVariable(" PSModulePath" , " Machine" )
Write-Verbose " new Path is: $($WENewValue)" -verbose


if (!(Test-Path -Path C:\Modules -ErrorAction SilentlyContinue))
{	New-Item -ItemType Directory -Name Modules -Path C:\ -Verbose }


Install-PackageProvider NuGet -Force
Import-PackageProvider NuGet -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted


Foreach ($WEModule in $WEModules)
{	Find-Module -Name $WEModule.Name -RequiredVersion $WEModule.Version -Repository PSGallery -Verbose | Save-Module -Path C:\Modules -Verbose	}

$WEDefaultModules = " PowerShellGet" , " PackageManagement" ," Pester"

Foreach ($WEModule in $WEDefaultModules)
{
	if ($tmp = Get-Module -ErrorAction Stop $WEModule -ErrorAction SilentlyContinue) {	Remove-Module -ErrorAction Stop $WEModule -Force	}
	Find-Module -Name $WEModule -Repository PSGallery -Verbose | Install-Module -Force -Confirm:$false -SkipPublisherCheck -Verbose
}

; 
$programName = " Microsoft Azure PowerShell" ; 
$app = Get-CimInstance -Class Win32_Product -Filter " Name Like '$($programName)%'" -Verbose
$app.Uninstall()

Write-Verbose " Exiting InstallVSTSAgent.ps1" -Verbose


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
