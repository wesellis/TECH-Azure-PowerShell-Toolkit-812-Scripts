#Requires -Version 7.4
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables and configures PowerShell Desired State Configuration (DSC)

.DESCRIPTION
    This script enables PowerShell DSC on the local machine and configures it for use.
    It can set up DSC in push mode, pull mode, or configure it to work with Azure Automation DSC.
    The script also installs required DSC modules and configures the Local Configuration Manager (LCM).

.PARAMETER Mode
    DSC configuration mode: 'Push', 'Pull', or 'AzureAutomation'

.PARAMETER PullServerUrl
    URL of the DSC pull server (required for Pull mode)

.PARAMETER RegistrationKey
    Registration key for DSC pull server (required for Pull mode)

.PARAMETER ConfigurationNames
    Array of configuration names to apply (for Pull mode)

.PARAMETER RefreshFrequencyMins
    How often to check for configuration updates in minutes (default: 30)

.PARAMETER ConfigurationModeFrequencyMins
    How often to apply configuration in minutes (default: 15)

.PARAMETER RebootNodeIfNeeded
    Whether DSC can reboot the node if needed (default: true)

.PARAMETER ActionAfterReboot
    Action to take after reboot: 'ContinueConfiguration' or 'StopConfiguration'

.PARAMETER AllowModuleOverwrite
    Whether to allow DSC to overwrite existing modules (default: true)

.PARAMETER ConfigurationMode
    Configuration mode: 'ApplyOnly', 'ApplyAndMonitor', or 'ApplyAndAutoCorrect'

.EXAMPLE
    .\Enable-Desiredstateconfiguration.ps1 -Mode Push

.EXAMPLE
    .\Enable-Desiredstateconfiguration.ps1 -Mode Pull -PullServerUrl "https://dsc.contoso.com:8080/PSDSCPullServer.svc" -RegistrationKey "12345678-1234-1234-1234-123456789012"

.EXAMPLE
    .\Enable-Desiredstateconfiguration.ps1 -Mode AzureAutomation -ConfigurationMode ApplyAndAutoCorrect

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires administrative privileges
    PowerShell 5.0 or later required for full DSC functionality
    For Azure Automation DSC, additional configuration may be required
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Push', 'Pull', 'AzureAutomation')]
    [string]$Mode,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$PullServerUrl,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RegistrationKey,

    [Parameter()]
    [string[]]$ConfigurationNames = @(),

    [Parameter()]
    [ValidateRange(15, 44640)]
    [int]$RefreshFrequencyMins = 30,

    [Parameter()]
    [ValidateRange(15, 44640)]
    [int]$ConfigurationModeFrequencyMins = 15,

    [Parameter()]
    [bool]$RebootNodeIfNeeded = $true,

    [Parameter()]
    [ValidateSet('ContinueConfiguration', 'StopConfiguration')]
    [string]$ActionAfterReboot = 'ContinueConfiguration',

    [Parameter()]
    [bool]$AllowModuleOverwrite = $true,

    [Parameter()]
    [ValidateSet('ApplyOnly', 'ApplyAndMonitor', 'ApplyAndAutoCorrect')]
    [string]$ConfigurationMode = 'ApplyAndMonitor',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogPath = "C:\temp\DSCConfiguration.log"
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

function Test-DSCPrerequisites {
    Write-Log "Checking DSC prerequisites"

    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        throw "PowerShell 5.0 or later is required for full DSC functionality. Current version: $($psVersion.ToString())"
    }

    Write-Log "PowerShell version $($psVersion.ToString()) - OK"

    # Check if WMF is properly installed
    try {
        Get-DscLocalConfigurationManager | Out-Null
        Write-Log "DSC Local Configuration Manager is available"
    }
    catch {
        throw "DSC Local Configuration Manager is not available. Please ensure Windows Management Framework is properly installed."
    }

    # Check WinRM service
    $winrmService = Get-Service -Name "WinRM" -ErrorAction SilentlyContinue
    if ($winrmService.Status -ne "Running") {
        Write-Log "Starting WinRM service"
        Start-Service -Name "WinRM"
    }
    else {
        Write-Log "WinRM service is running"
    }
}

function Install-RequiredModules {
    Write-Log "Installing required DSC modules"

    $requiredModules = @(
        'PSDesiredStateConfiguration'
    )

    foreach ($module in $requiredModules) {
        try {
            if (!(Get-Module -Name $module -ListAvailable)) {
                Write-Log "Installing module: $module"
                Install-Module -Name $module -Force -AllowClobber -Scope AllUsers
            }
            else {
                Write-Log "Module $module is already installed"
            }
        }
        catch {
            Write-Log "Failed to install module $module : $($_.Exception.Message)" -Level Warning
        }
    }
}

function Set-DSCLocalConfigurationManager {
    param(
        [Parameter(Mandatory)]
        [string]$DscMode
    )

    Write-Log "Configuring Local Configuration Manager for $DscMode mode"

    $configData = @{
        AllNodes = @(
            @{
                NodeName = 'localhost'
                PSDscAllowPlainTextPassword = $true
            }
        )
    }

    switch ($DscMode) {
        'Push' {
            [DSCLocalConfigurationManager()]
            Configuration LCMPushMode {
                Node localhost {
                    Settings {
                        RefreshMode = 'Push'
                        RefreshFrequencyMins = $RefreshFrequencyMins
                        ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
                        ConfigurationMode = $ConfigurationMode
                        RebootNodeIfNeeded = $RebootNodeIfNeeded
                        ActionAfterReboot = $ActionAfterReboot
                        AllowModuleOverwrite = $AllowModuleOverwrite
                    }
                }
            }

            LCMPushMode -ConfigurationData $configData -OutputPath "$env:TEMP\DSCConfig"
            Set-DscLocalConfigurationManager -Path "$env:TEMP\DSCConfig" -Verbose
        }

        'Pull' {
            if (-not $PullServerUrl -or -not $RegistrationKey) {
                throw "PullServerUrl and RegistrationKey are required for Pull mode"
            }

            [DSCLocalConfigurationManager()]
            Configuration LCMPullMode {
                Node localhost {
                    Settings {
                        RefreshMode = 'Pull'
                        RefreshFrequencyMins = $RefreshFrequencyMins
                        ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
                        ConfigurationMode = $ConfigurationMode
                        RebootNodeIfNeeded = $RebootNodeIfNeeded
                        ActionAfterReboot = $ActionAfterReboot
                        AllowModuleOverwrite = $AllowModuleOverwrite
                    }

                    ConfigurationRepositoryWeb PullServer {
                        ServerURL = $PullServerUrl
                        RegistrationKey = $RegistrationKey
                        ConfigurationNames = $ConfigurationNames
                    }
                }
            }

            LCMPullMode -ConfigurationData $configData -OutputPath "$env:TEMP\DSCConfig"
            Set-DscLocalConfigurationManager -Path "$env:TEMP\DSCConfig" -Verbose
        }

        'AzureAutomation' {
            [DSCLocalConfigurationManager()]
            Configuration LCMAzureAutomation {
                Node localhost {
                    Settings {
                        RefreshMode = 'Pull'
                        RefreshFrequencyMins = $RefreshFrequencyMins
                        ConfigurationModeFrequencyMins = $ConfigurationModeFrequencyMins
                        ConfigurationMode = $ConfigurationMode
                        RebootNodeIfNeeded = $RebootNodeIfNeeded
                        ActionAfterReboot = $ActionAfterReboot
                        AllowModuleOverwrite = $AllowModuleOverwrite
                    }
                }
            }

            LCMAzureAutomation -ConfigurationData $configData -OutputPath "$env:TEMP\DSCConfig"
            Set-DscLocalConfigurationManager -Path "$env:TEMP\DSCConfig" -Verbose

            Write-Log "Azure Automation DSC mode configured. Additional setup may be required:" -Level Warning
            Write-Log "1. Register node with Azure Automation Account" -Level Warning
            Write-Log "2. Configure node configuration in Azure portal" -Level Warning
        }
    }

    # Clean up temporary files
    Remove-Item -Path "$env:TEMP\DSCConfig" -Recurse -Force -ErrorAction SilentlyContinue
}

function Get-DSCStatus {
    Write-Log "Checking DSC configuration status"

    try {
        $lcm = Get-DscLocalConfigurationManager
        Write-Log "DSC Local Configuration Manager Status:"
        Write-Log "  Refresh Mode: $($lcm.RefreshMode)"
        Write-Log "  Configuration Mode: $($lcm.ConfigurationMode)"
        Write-Log "  Refresh Frequency: $($lcm.RefreshFrequencyMins) minutes"
        Write-Log "  Configuration Mode Frequency: $($lcm.ConfigurationModeFrequencyMins) minutes"
        Write-Log "  Reboot Node If Needed: $($lcm.RebootNodeIfNeeded)"
        Write-Log "  Action After Reboot: $($lcm.ActionAfterReboot)"
        Write-Log "  Allow Module Overwrite: $($lcm.AllowModuleOverwrite)"

        if ($lcm.ConfigurationDownloadManagers) {
            Write-Log "  Pull Server URL: $($lcm.ConfigurationDownloadManagers[0].ServerURL)"
        }

        # Check DSC configuration status
        $dscStatus = Get-DscConfigurationStatus -ErrorAction SilentlyContinue
        if ($dscStatus) {
            Write-Log "Last Configuration Status: $($dscStatus.Status)"
            Write-Log "Last Configuration Run: $($dscStatus.StartDate)"
        }
    }
    catch {
        Write-Log "Could not retrieve DSC status: $($_.Exception.Message)" -Level Warning
    }
}

function Test-DSCConfiguration {
    Write-Log "Testing DSC configuration"

    try {
        $testResult = Test-DscConfiguration -Verbose
        if ($testResult) {
            Write-Log "DSC configuration test passed - system is in desired state"
        }
        else {
            Write-Log "DSC configuration test failed - system is not in desired state" -Level Warning
        }
    }
    catch {
        Write-Log "Could not test DSC configuration: $($_.Exception.Message)" -Level Warning
    }
}

try {
    Write-Log "Starting DSC configuration process"

    # Validate parameters for Pull mode
    if ($Mode -eq 'Pull' -and (-not $PullServerUrl -or -not $RegistrationKey)) {
        throw "PullServerUrl and RegistrationKey parameters are required when Mode is 'Pull'"
    }

    # Check prerequisites
    Test-DSCPrerequisites

    # Install required modules
    Install-RequiredModules

    # Configure LCM based on mode
    Set-DSCLocalConfigurationManager -DscMode $Mode

    # Display current status
    Get-DSCStatus

    # Test configuration if possible
    Test-DSCConfiguration

    Write-Log "DSC configuration completed successfully"

    # Provide next steps guidance
    Write-Log "Next Steps:"
    switch ($Mode) {
        'Push' {
            Write-Log "1. Create DSC configuration scripts"
            Write-Log "2. Compile configurations to MOF files"
            Write-Log "3. Apply configurations using Start-DscConfiguration"
        }
        'Pull' {
            Write-Log "1. Ensure configurations are available on pull server"
            Write-Log "2. Monitor DSC event logs for pull operations"
            Write-Log "3. Configurations will be automatically applied based on schedule"
        }
        'AzureAutomation' {
            Write-Log "1. Complete Azure Automation DSC node registration"
            Write-Log "2. Assign node configurations in Azure portal"
            Write-Log "3. Monitor compliance in Azure Automation"
        }
    }
}
catch {
    $errorMessage = "DSC configuration failed: $($_.Exception.Message)"
    Write-Log $errorMessage -Level Error
    throw
}
finally {
    Write-Log "Configuration log saved to: $LogPath"
}