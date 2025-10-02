#Requires -Version 7.4
#Requires -Modules PSDesiredStateConfiguration

<#
.SYNOPSIS
    DSC Configuration for IIS Web Server setup

.DESCRIPTION
    This DSC configuration installs and configures IIS Web Server with common features
    including management tools, authentication methods, logging, and monitoring capabilities.

.PARAMETER MachineName
    The target machine name for the DSC configuration. Defaults to localhost.

.EXAMPLE
    Main -MachineName "WebServer01"
    Configures IIS features on WebServer01

.EXAMPLE
    Main
    Configures IIS features on the local machine

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
    This configuration installs IIS with essential features for web hosting
#>

Configuration Main {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$MachineName = "localhost"
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $MachineName {
        WindowsFeature WebServerRole {
            Name = "Web-Server"
            Ensure = "Present"
        }

        WindowsFeature WebManagementConsole {
            Name = "Web-Mgmt-Console"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature WebManagementService {
            Name = "Web-Mgmt-Service"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature HTTPRedirection {
            Name = "Web-Http-Redirect"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature CustomLogging {
            Name = "Web-Custom-Logging"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature LoggingTools {
            Name = "Web-Log-Libraries"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature RequestMonitor {
            Name = "Web-Request-Monitor"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature Tracing {
            Name = "Web-Http-Tracing"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature BasicAuthentication {
            Name = "Web-Basic-Auth"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature WindowsAuthentication {
            Name = "Web-Windows-Auth"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        WindowsFeature ApplicationInitialization {
            Name = "Web-AppInit"
            Ensure = "Present"
            DependsOn = "[WindowsFeature]WebServerRole"
        }
    }
}
