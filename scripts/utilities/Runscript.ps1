#Requires -Version 7.4

<#
.SYNOPSIS
    Apply Azure Baseline to Windows

.DESCRIPTION
    Azure automation script that downloads PowerShell, installs GuestConfiguration module,
    and applies Azure baseline security configurations to Windows systems.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions
    Applies Azure Windows baseline security configurations
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Starting script to apply Azure baseline to Windows"

    # Enable TLS 1.2
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

    # Create GuestConfig directory
    $GcFolder = New-Item -Path 'C:\ProgramData\' -Name 'GuestConfig' -ItemType 'Directory' -Force

    # Get latest PowerShell release info
    Write-Output "Getting latest PowerShell release information"
    $PwshLatestRelease = Invoke-RestMethod 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'
    $PwshLatestAssets = Invoke-RestMethod $PwshLatestRelease.assets_url
    $PwshDownloadUrl = ($PwshLatestAssets | Where-Object { $_.browser_download_url -like "*win-x64.zip" }).browser_download_url

    if (-not $PwshDownloadUrl) {
        throw "Could not find PowerShell download URL"
    }

    $PwshZipFileName = $PwshDownloadUrl.Split('/')[-1]

    # Download PowerShell
    Write-Output "Downloading PowerShell stand-alone binaries"
    $PwshZipDownloadPath = Join-Path -Path $GcFolder -ChildPath $PwshZipFileName

    $InvokeWebParams = @{
        Uri     = $PwshDownloadUrl
        OutFile = $PwshZipDownloadPath
    }
    Invoke-WebRequest @InvokeWebParams

    # Extract PowerShell
    Write-Output "Extracting PowerShell package"
    $ZipDestinationPath = Join-Path -Path $GcFolder -ChildPath $PwshZipFileName.Replace('.zip', '')
    Expand-Archive -Path $PwshZipDownloadPath -DestinationPath $ZipDestinationPath -Force

    $PwshExePath = Join-Path -Path $ZipDestinationPath -ChildPath 'pwsh.exe'

    if (-not (Test-Path $PwshExePath)) {
        throw "PowerShell executable not found at: $PwshExePath"
    }

    # Install GuestConfiguration module
    Write-Output "Saving GuestConfiguration module"
    $ModulesFolder = New-Item -Path 'C:\ProgramData\GuestConfig' -Name 'modules' -ItemType 'Directory' -Force

    Install-PackageProvider -Name "NuGet" -Scope CurrentUser -Force
    Save-Module -Name GuestConfiguration -Path $ModulesFolder -Force

    # Import and configure GuestConfiguration module
    [scriptblock]$GcModuleDetails = {
        $env:PSModulePath += ';C:\ProgramData\GuestConfig\modules'
        Import-Module 'GuestConfiguration'
        Get-Module 'GuestConfiguration'
    }

    $GcModule = & $PwshExePath -Command $GcModuleDetails

    if ($GcModule) {
        $GcModulePath = Join-Path -Path $GcModule.ModuleBase -ChildPath $GcModule.RootModule
        (Get-Content -Path $GcModulePath).Replace('metaConfig.Type', 'true') | Set-Content -Path $GcModulePath
    }

    # Apply Azure baseline
    Write-Output "Applying Azure baseline"

    [scriptblock]$remediation = {
        $env:PSModulePath += ';C:\ProgramData\GuestConfig\modules'
        Import-Module 'GuestConfiguration'

        # Define parameters for baseline configuration
        $Parameters = @(
            @{
                ResourceType          = ''
                ResourceId            = 'User Account Control: Admin Approval Mode for the Built-in Administrator account'
                ResourcePropertyName  = 'ExpectedValue'
                ResourcePropertyValue = '0'
            },
            @{
                ResourceType          = ''
                ResourceId            = 'User Account Control: Admin Approval Mode for the Built-in Administrator account'
                ResourcePropertyName  = 'RemediateValue'
                ResourcePropertyValue = '0'
            }
        )

        # Apply Azure Windows Baseline
        Start-GuestConfigurationPackageRemediation -Path 'https://oaasguestconfigwcuss1.blob.core.windows.net/builtinconfig/AzureWindowsBaseline/AzureWindowsBaseline_1.2.0.0.zip'

        # Apply Filter Administrator Token configuration
        Start-GuestConfigurationPackageRemediation -Path 'https://oaasguestconfigeaps1.blob.core.windows.net/builtinconfig/FilterAdministratorToken/FilterAdministratorToken_1.10.0.0.zip'
    }

    & $PwshExePath -Command $remediation

    # Create scheduled task for FilterAdministratorToken
    Write-Output "Creating scheduled task for FilterAdministratorToken"

    $command = @'
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name FilterAdministratorToken -Value 1 -Type DWord
$SchedServiceCom = New-Object -ComObject "Schedule.Service"
$SchedServiceCom.Connect()
$RootTaskFolder = $SchedServiceCom.GetFolder('\')
$RootTaskFolder.DeleteTask('FilterAdministratorTokenEnablement', 0)
'@

    $EncodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))

    $TaskDefinition = @"
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <URI>\FilterAdministratorTokenEnablement</URI>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>false</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\System32\cmd.exe</Command>
      <Arguments>/c PowerShell -ExecutionPolicy Bypass -OutputFormat Text -EncodedCommand $EncodedCommand</Arguments>
    </Exec>
  </Actions>
</Task>
"@

    # Register scheduled task
    $SchedServiceCom = New-Object -ComObject "Schedule.Service"
    $SchedServiceCom.Connect()
    $FilterAdminTokenTask = $SchedServiceCom.NewTask($null)
    $FilterAdminTokenTask.XmlText = $TaskDefinition
    $RootTaskFolder = $SchedServiceCom.GetFolder('\')
    [void]$RootTaskFolder.RegisterTaskDefinition('FilterAdministratorTokenEnablement', $FilterAdminTokenTask, 6, 'SYSTEM', $null, 1, $null)

    Write-Output "Scheduled task created successfully"

    # Cleanup
    Write-Output "Performing cleanup"
    Remove-Item -Path 'C:\ProgramData\GuestConfig' -Recurse -Force -ErrorAction SilentlyContinue

    $nugetPath = Join-Path $env:LOCALAPPDATA 'PackageManagement\ProviderAssemblies\NuGet'
    if (Test-Path $nugetPath) {
        Remove-Item -Path $nugetPath -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Output "Azure baseline application completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}