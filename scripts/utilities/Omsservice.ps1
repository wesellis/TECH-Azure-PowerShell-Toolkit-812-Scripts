#Requires -Version 7.4
#Requires -Modules PSDesiredStateConfiguration

<#
.SYNOPSIS
    OMS Service Configuration

.DESCRIPTION
    Azure DSC configuration to ensure the Microsoft Monitoring Agent Health Service
    is running. This is a simplified configuration that only manages the service state
    after OMS has been installed.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and DSC modules
    Assumes Microsoft Monitoring Agent is already installed
#>

Configuration OMSSERVICE {
    param()

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node localhost {
        # Ensure OMS Health Service is running
        Service OMSService {
            Name = "HealthService"
            State = "Running"
            StartupType = "Automatic"
        }

        # Optional: Monitor agent update service
        Service AgentUpdateService {
            Name = "MicrosoftMonitoringAgent"
            State = "Running"
            StartupType = "Automatic"
        }
    }
}

# Example usage:
# OMSSERVICE
# Start-DscConfiguration -Path .\OMSSERVICE -Wait -Verbose -Force