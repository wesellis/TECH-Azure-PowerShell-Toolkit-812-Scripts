#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables and configures AppLocker application control policies

.DESCRIPTION
    This script enables AppLocker service and configures application control policies
    to enhance security by controlling which applications can run on the system.
    It can create default rules or import custom policy files.

.PARAMETER PolicyMode
    The enforcement mode for AppLocker policies: 'Enforce', 'AuditOnly', or 'NotConfigured'

.PARAMETER CreateDefaultRules
    Switch to create default AppLocker rules for administrators and everyone

.PARAMETER PolicyFilePath
    Path to an AppLocker policy XML file to import

.PARAMETER RuleCollections
    Array of rule collections to configure: 'Executable', 'WindowsInstaller', 'Script', 'Packaged', 'Dll'

.PARAMETER LogPath
    Path for AppLocker configuration logs

.EXAMPLE
    .\Enable-Applocker.ps1 -PolicyMode AuditOnly -CreateDefaultRules

.EXAMPLE
    .\Enable-Applocker.ps1 -PolicyMode Enforce -PolicyFilePath "C:\AppLockerPolicy.xml"

.EXAMPLE
    .\Enable-Applocker.ps1 -PolicyMode Enforce -CreateDefaultRules -RuleCollections @('Executable', 'Script')

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires administrative privileges
    AppLocker is available on Windows Server 2008 R2 and later, Windows 7 Enterprise/Ultimate and later
    Some features require Windows Server or Windows Enterprise/Education editions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Enforce', 'AuditOnly', 'NotConfigured')]
    [string]$PolicyMode,

    [Parameter()]
    [switch]$CreateDefaultRules,

    [Parameter()]
    [ValidateScript({
        if ($_ -and !(Test-Path -Path $_ -PathType Leaf)) {
            throw "Policy file not found: $_"
        }
        return $true
    })]
    [string]$PolicyFilePath,

    [Parameter()]
    [ValidateSet('Executable', 'WindowsInstaller', 'Script', 'Packaged', 'Dll')]
    [string[]]$RuleCollections = @('Executable', 'WindowsInstaller', 'Script'),

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = "C:\temp\AppLocker.log"
)

$ErrorActionPreference = "Stop"

function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Level = 'Information'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Ensure log directory exists
    $logDir = Split-Path -Path $LogPath -Parent
    if (!(Test-Path -Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # Write to log file
    $logMessage | Out-File -FilePath $LogPath -Append

    # Write to console
    switch ($Level) {
        'Information' { Write-Host $logMessage -ForegroundColor Green }
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message }
    }
}

function Test-AppLockerSupport {
    Write-Log "Checking AppLocker support on this system"

    # Check Windows version
    $osVersion = [System.Environment]::OSVersion.Version
    $isSupported = $false

    # AppLocker is supported on Windows 7/2008 R2 and later
    if ($osVersion.Major -gt 6 -or ($osVersion.Major -eq 6 -and $osVersion.Minor -ge 1)) {
        $isSupported = $true
    }

    if (-not $isSupported) {
        throw "AppLocker is not supported on this version of Windows"
    }

    # Check Windows edition for full AppLocker support
    $edition = (Get-WmiObject -Class Win32_OperatingSystem).OperatingSystemSKU
    $fullSupportSKUs = @(4, 27, 28, 48, 49, 161, 162, 164) # Enterprise, DataCenter, Education SKUs

    if ($edition -notin $fullSupportSKUs) {
        Write-Log "This Windows edition may have limited AppLocker support" -Level Warning
    }

    Write-Log "AppLocker is supported on this system"
}

function Enable-AppLockerService {
    Write-Log "Configuring Application Identity service"

    try {
        $service = Get-Service -Name "AppIDSvc" -ErrorAction Stop

        if ($service.StartType -ne "Automatic") {
            Set-Service -Name "AppIDSvc" -StartupType Automatic
            Write-Log "Application Identity service startup type set to Automatic"
        }

        if ($service.Status -ne "Running") {
            Start-Service -Name "AppIDSvc"
            Write-Log "Application Identity service started"
        }
        else {
            Write-Log "Application Identity service is already running"
        }
    }
    catch {
        throw "Failed to configure Application Identity service: $($_.Exception.Message)"
    }
}

function New-AppLockerDefaultRules {
    param(
        [Parameter(Mandatory)]
        [string[]]$Collections
    )

    Write-Log "Creating default AppLocker rules for collections: $($Collections -join ', ')"

    $policyXml = @"
<AppLockerPolicy Version="1">
"@

    foreach ($collection in $Collections) {
        Write-Log "Creating default rules for $collection collection"

        switch ($collection) {
            'Executable' {
                $policyXml += @"
    <RuleCollection Type="Exe" EnforcementMode="$PolicyMode">
        <FilePathRule Id="{921cc481-6e17-4653-8f75-050b80acca20}" Name="(Default Rule) All files located in the Program Files folder" Description="Allows members of the Everyone group to run applications that are located in the Program Files folder." UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePathCondition Path="%PROGRAMFILES%\*"/>
            </Conditions>
        </FilePathRule>
        <FilePathRule Id="{a61c8b2c-a319-4cd0-9690-d2177cad7b51}" Name="(Default Rule) All files located in the Windows folder" Description="Allows members of the Everyone group to run applications that are located in the Windows folder." UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePathCondition Path="%WINDIR%\*"/>
            </Conditions>
        </FilePathRule>
        <FilePathRule Id="{fd686d83-a829-4351-8ff4-27c7de5755d2}" Name="(Default Rule) All files" Description="Allows members of the local Administrators group to run all applications." UserOrGroupSid="S-1-5-32-544" Action="Allow">
            <Conditions>
                <FilePathCondition Path="*"/>
            </Conditions>
        </FilePathRule>
    </RuleCollection>
"@
            }
            'WindowsInstaller' {
                $policyXml += @"
    <RuleCollection Type="Msi" EnforcementMode="$PolicyMode">
        <FilePathRule Id="{b7af7102-efde-4369-8a89-7a6a392d1473}" Name="(Default Rule) All Windows Installer files in %systemdrive%\Windows\Installer" Description="Allows members of the Everyone group to run packaged apps that are signed." UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePathCondition Path="%WINDIR%\Installer\*"/>
            </Conditions>
        </FilePathRule>
        <FilePathRule Id="{5b290184-345a-4453-b184-45305f6d9a54}" Name="(Default Rule) All Windows Installer files" Description="Allows members of the local Administrators group to run all Windows Installer files." UserOrGroupSid="S-1-5-32-544" Action="Allow">
            <Conditions>
                <FilePathCondition Path="*.*"/>
            </Conditions>
        </FilePathRule>
    </RuleCollection>
"@
            }
            'Script' {
                $policyXml += @"
    <RuleCollection Type="Script" EnforcementMode="$PolicyMode">
        <FilePathRule Id="{06dce67b-934c-454f-a263-2515c8796a5d}" Name="(Default Rule) All scripts located in the Program Files folder" Description="Allows members of the Everyone group to run scripts that are located in the Program Files folder." UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePathCondition Path="%PROGRAMFILES%\*"/>
            </Conditions>
        </FilePathRule>
        <FilePathRule Id="{9428c672-5fc3-47f4-808a-a0011f36dd2c}" Name="(Default Rule) All scripts located in the Windows folder" Description="Allows members of the Everyone group to run scripts that are located in the Windows folder." UserOrGroupSid="S-1-1-0" Action="Allow">
            <Conditions>
                <FilePathCondition Path="%WINDIR%\*"/>
            </Conditions>
        </FilePathRule>
        <FilePathRule Id="{ed97d0cb-15ff-430f-b82c-8d7832957725}" Name="(Default Rule) All scripts" Description="Allows members of the local Administrators group to run all scripts." UserOrGroupSid="S-1-5-32-544" Action="Allow">
            <Conditions>
                <FilePathCondition Path="*"/>
            </Conditions>
        </FilePathRule>
    </RuleCollection>
"@
            }
        }
    }

    $policyXml += "</AppLockerPolicy>"

    # Save and apply the policy
    $tempPolicyPath = "$env:TEMP\AppLockerDefaultPolicy.xml"
    $policyXml | Out-File -FilePath $tempPolicyPath -Encoding UTF8

    try {
        Set-AppLockerPolicy -XmlPolicy $tempPolicyPath
        Write-Log "Default AppLocker policy applied successfully"
    }
    finally {
        Remove-Item -Path $tempPolicyPath -Force -ErrorAction SilentlyContinue
    }
}

function Import-AppLockerPolicyFile {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    Write-Log "Importing AppLocker policy from: $FilePath"

    try {
        Set-AppLockerPolicy -XmlPolicy $FilePath
        Write-Log "AppLocker policy imported successfully"
    }
    catch {
        throw "Failed to import AppLocker policy: $($_.Exception.Message)"
    }
}

function Get-AppLockerStatus {
    Write-Log "Checking AppLocker configuration status"

    try {
        $policy = Get-AppLockerPolicy -Effective
        $collections = $policy.RuleCollections

        Write-Log "Current AppLocker Policy Status:"
        foreach ($collection in $collections) {
            $ruleCount = ($collection.Rules | Measure-Object).Count
            Write-Log "  $($collection.RuleCollectionType): $($collection.EnforcementMode) ($ruleCount rules)"
        }

        $appIdService = Get-Service -Name "AppIDSvc"
        Write-Log "Application Identity Service: $($appIdService.Status) (Startup: $($appIdService.StartType))"
    }
    catch {
        Write-Log "Could not retrieve AppLocker status: $($_.Exception.Message)" -Level Warning
    }
}

try {
    Write-Log "Starting AppLocker configuration"

    # Check system support
    Test-AppLockerSupport

    # Enable AppLocker service
    Enable-AppLockerService

    # Configure AppLocker policy
    if ($PolicyFilePath) {
        Import-AppLockerPolicyFile -FilePath $PolicyFilePath
    }
    elseif ($CreateDefaultRules) {
        New-AppLockerDefaultRules -Collections $RuleCollections
    }
    else {
        Write-Log "No policy specified. AppLocker service is enabled but no rules are configured." -Level Warning
        Write-Log "Use -CreateDefaultRules or -PolicyFilePath to configure rules."
    }

    # Display current status
    Get-AppLockerStatus

    Write-Log "AppLocker configuration completed successfully"

    # Provide guidance
    Write-Log "Important Notes:"
    Write-Log "1. Test AppLocker policies in AuditOnly mode before enforcing"
    Write-Log "2. Monitor AppLocker event logs for policy violations"
    Write-Log "3. Consider creating custom rules for your specific applications"
    Write-Log "4. Review and update policies regularly"

    if ($PolicyMode -eq "Enforce") {
        Write-Log "AppLocker is now in ENFORCE mode - applications will be blocked according to policy" -Level Warning
    }
}
catch {
    $errorMessage = "AppLocker configuration failed: $($_.Exception.Message)"
    Write-Log $errorMessage -Level Error
    throw
}
finally {
    Write-Log "Configuration log saved to: $LogPath"
}