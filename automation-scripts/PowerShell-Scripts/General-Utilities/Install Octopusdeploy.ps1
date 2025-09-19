#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Install Octopusdeploy

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
    We Enhanced Install Octopusdeploy

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
  [string] $WESqlDbConnectionString,
  [string] $WELicenseFullName,
  [string] $WELicenseOrganisationName,
  [string] $WELicenseEmailAddress,
  [string] $WEOctopusAdminUsername,
  [string] $WEOctopusAdminPassword
)

#region Functions

$config = @{}
$octopusDeployVersion = " Octopus.3.0.12.2366-x64"
$msiFileName = " Octopus.3.0.12.2366-x64.msi"
$downloadBaseUrl = " https://download.octopusdeploy.com/octopus/"
$downloadUrl = $downloadBaseUrl + $msiFileName
$installBasePath = " D:\Install\"
$msiPath = $installBasePath + $msiFileName
$msiLogPath = $installBasePath + $msiFileName + '.log'
$installerLogPath = $installBasePath + 'Install-OctopusDeploy.ps1.log'
$octopusLicenseUrl = " https://octopusdeploy.com/api/licenses/trial"
$WEOFS = " `r`n"

[CmdletBinding()]
function WE-Write-Log
{
  [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [string] $message
  )
  
  $timestamp = ([System.DateTime]::UTCNow).ToString(" yyyy'-'MM'-'dd'T'HH':'mm':'ss" )
  Write-Output " [$timestamp] $message"
}

[CmdletBinding()]
function WE-Write-CommandOutput 
{
  [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [string] $output
  )    
  
  if ($output -eq "" ) { return }
  
  Write-Output ""
  $output.Trim().Split(" `n" ) |% { Write-Output " `t| $($_.Trim())" }
  Write-Output ""
}

[CmdletBinding()]
function WE-Get-Config -ErrorAction Stop
{
  Write-Log " ======================================"
  Write-Log " Get Config"
  Write-Log ""    
  Write-Log " Parsing script parameters ..."
    
  $config.Add(" sqlDbConnectionString" , [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($WESqlDbConnectionString)))
  $config.Add(" licenseFullName" , [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($WELicenseFullName)))
  $config.Add(" licenseOrganisationName" , [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($WELicenseOrganisationName)))
  $config.Add(" licenseEmailAddress" , [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($WELicenseEmailAddress)))
  $config.Add(" octopusAdminUsername" , [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($WEOctopusAdminUsername)))
  $config.Add(" octopusAdminPassword" , [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($WEOctopusAdminPassword)))
  
  Write-Log " done."
  Write-Log ""
}

[CmdletBinding()]
function WE-Create-InstallLocation
{
  Write-Log " ======================================"
  Write-Log " Create Install Location"
  Write-Log ""
    
  if (!(Test-Path $installBasePath))
  {
    Write-Log " Creating installation folder at '$installBasePath' ..."
    New-Item -ItemType Directory -Path $installBasePath | Out-Null
    Write-Log " done."
  }
  else
  {
    Write-Log " Installation folder at '$installBasePath' already exists."
  }
  
  Write-Log ""
}

[CmdletBinding()]
function WE-Install-OctopusDeploy
{
  Write-Log " ======================================"
  Write-Log " Install Octopus Deploy"
  Write-Log ""
    
  Write-Log " Downloading Octopus Deploy installer '$downloadUrl' to '$msiPath' ..."
  (New-Object -ErrorAction Stop Net.WebClient).DownloadFile($downloadUrl, $msiPath)
  Write-Log " done."
  
  Write-Log " Installing via '$msiPath' ..."
  $exe = 'msiexec.exe'
  $args = @(
    '/qn', 
    '/i', $msiPath, 
    '/l*v', $msiLogPath
  )
  $output = .$exe $args
  Write-CommandOutput $output
  Write-Log " done."
    
  Write-Log ""
}

[CmdletBinding()]
function WE-Configure-OctopusDeploy
{
  Write-Log " ======================================"
  Write-Log " Configure Octopus Deploy"
  Write-Log ""
    
  $exe = '${env:ProgramFiles}\Octopus Deploy\Octopus\Octopus.Server.exe'
    
  $count = 0
  while(!(Test-Path $exe) -and $count -lt 5)
  {
    Write-Log " $exe - not available yet ... waiting 10s ..."
    Start-Sleep -s 10
    $count = $count + 1
  }
    
  Write-Log " Creating Octopus Deploy instance ..."
  $args = @(
    'create-instance', 
    '--console', 
    '--instance', 'OctopusServer', 
    '--config', 'C:\Octopus\OctopusServer.config'     
  )
  $output = .$exe $args
  Write-CommandOutput $output
  Write-Log " done."
  
  Write-Log " Configuring Octopus Deploy instance ..."
  $args = @(
    'configure', 
    '--console',
    '--instance', 'OctopusServer', 
    '--home', 'C:\Octopus', 
    '--storageConnectionString', $($config.sqlDbConnectionString), 
    '--upgradeCheck', 'True', 
    '--upgradeCheckWithStatistics', 'True', 
    '--webAuthenticationMode', 'UsernamePassword', 
    '--webForceSSL', 'False', 
    '--webListenPrefixes', 'http://localhost:80/', 
    '--commsListenPort', '10943'     
  )
  $output = .$exe $args
  Write-CommandOutput $output
  Write-Log " done."
    
  Write-Log " Creating Octopus Deploy database ..."
  $args = @(
    'database', 
    '--console',
    '--instance', 'OctopusServer', 
    '--create'
  )
  $output = .$exe $args
  Write-CommandOutput $output
  Write-Log " done."
    
  Write-Log " Stopping Octopus Deploy instance ..."
  $args = @(
    'service', 
    '--console',
    '--instance', 'OctopusServer', 
    '--stop'
  )
  $output = .$exe $args
  Write-CommandOutput $output
  Write-Log " done."
    
  Write-Log " Creating Admin User for Octopus Deploy instance ..."
  $args = @(
    'admin', 
    '--console',
    '--instance', 'OctopusServer', 
    '--username', $($config.octopusAdminUserName), 
    '--password', $($config.octopusAdminPassword)
  )
 ;  $output = .$exe $args
  Write-CommandOutput $output
  Write-Log " done."  

  Write-Log " Obtaining a trial license for Full Name: $($config.licenseFullName), Organisation Name: $($config.licenseOrganisationName), Email Address: $($config.licenseEmailAddress) ..."
 ;  $postParams = @{ FullName=" $($config.licenseFullName)" ;Organization=" $($config.licenseOrganisationName)" ;EmailAddress=" $($config.licenseEmailAddress)" }
  $response = Invoke-WebRequest -UseBasicParsing -Uri " $octopusLicenseUrl" -Method POST -Body $postParams
  $utf8NoBOM = New-Object -ErrorAction Stop System.Text.UTF8Encoding($false)
  $bytes  = $utf8NoBOM.GetBytes($response.Content)
  $licenseBase64 = [System.Convert]::ToBase64String($bytes)
  Write-Log " done."
    
  Write-Log " Installing license for Octopus Deploy instance ..."
  $args = @(
    'license', 
    '--console',
    '--instance', 'OctopusServer', 
    '--licenseBase64', $licenseBase64
  )
  $output = .$exe $args
  Write-CommandOutput $output
  Write-Log " done."
    
  Write-Log " Reconfigure and start Octopus Deploy instance ..."
  $args = @(
    'service',
    '--console', 
    '--instance', 'OctopusServer', 
    '--install', 
    '--reconfigure', 
    '--start'
  )
  $output = .$exe $args
  Write-CommandOutput $output
  Write-Log " done."
    
  Write-Log ""
} 

[CmdletBinding()]
function WE-Configure-Firewall
{
  Write-Log " ======================================"
  Write-Log " Configure Firewall"
  Write-Log ""
    
  $firewallRuleName = " Allow_Port80_HTTP"
    
  if ((Get-NetFirewallRule -Name $firewallRuleName -ErrorAction Ignore) -eq $null)
  {
    Write-Log " Creating firewall rule to allow port 80 HTTP traffic ..."
   ;  $firewallRule = @{
      Name=$firewallRuleName
      DisplayName =" Allow Port 80 (HTTP)"
      Description=" Port 80 for HTTP traffic"
      Direction='Inbound'
      Protocol='TCP'
      LocalPort=80
      Enabled='True'
      Profile='Any'
      Action='Allow'
    }
   ;  $output = (New-NetFirewallRule -ErrorAction Stop @firewallRule | Out-String)
    Write-CommandOutput $output
    Write-Log " done."
  }
  else
  {
    Write-Log " Firewall rule to allow port 80 HTTP traffic already exists."
  }
  
  Write-Log ""
}

try
{
  Write-Log " ======================================"
  Write-Log " Installing '$octopusDeployVersion'"
  Write-Log " ======================================"
  Write-Log ""
  
  Get-Config -ErrorAction Stop
  Create-InstallLocation
  Install-OctopusDeploy
  Configure-OctopusDeploy
  Configure-Firewall
  
  Write-Log " Installation successful."
  Write-Log ""
}
catch
{
  Write-Log $_
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
