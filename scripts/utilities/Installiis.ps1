#Requires -Version 7.4

<#
.SYNOPSIS
    Install IIS

.DESCRIPTION
    Azure automation script for installing and configuring Internet Information Services (IIS)
    with Web Deploy and various IIS features for web application hosting.

.PARAMETER NodeName
    The name of the node to configure IIS on

.PARAMETER WebDeployPackagePath
    URL path to the Web Deploy package to install

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    This is a DSC configuration for IIS installation and configuration
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$NodeName,

    [Parameter(Mandatory = $false)]
    [string]$WebDeployPackagePath
)

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Defining InstallIIS DSC Configuration..."

    Configuration InstallIIS {
        param(
            [Parameter(Mandatory = $true)]
            [string]$NodeName,

            [Parameter(Mandatory = $false)]
            [string]$WebDeployPackagePath
        )

        Import-DscResource -ModuleName PSDesiredStateConfiguration

        Node $NodeName {
            WindowsFeature WebServerRole {
                Name = "Web-Server"
                Ensure = "Present"
            }

            WindowsFeature WebManagementConsole {
                Name = "Web-Mgmt-Console"
                Ensure = "Present"
            }

            WindowsFeature WebManagementService {
                Name = "Web-Mgmt-Service"
                Ensure = "Present"
            }

            WindowsFeature ASPNet45 {
                Name = "Web-Asp-Net45"
                Ensure = "Present"
            }

            WindowsFeature HTTPRedirection {
                Name = "Web-Http-Redirect"
                Ensure = "Present"
            }

            WindowsFeature CustomLogging {
                Name = "Web-Custom-Logging"
                Ensure = "Present"
            }

            WindowsFeature LoggingTools {
                Name = "Web-Log-Libraries"
                Ensure = "Present"
            }

            WindowsFeature RequestMonitor {
                Name = "Web-Request-Monitor"
                Ensure = "Present"
            }

            WindowsFeature Tracing {
                Name = "Web-Http-Tracing"
                Ensure = "Present"
            }

            WindowsFeature BasicAuthentication {
                Name = "Web-Basic-Auth"
                Ensure = "Present"
            }

            WindowsFeature WindowsAuthentication {
                Name = "Web-Windows-Auth"
                Ensure = "Present"
            }

            WindowsFeature ApplicationInitialization {
                Name = "Web-AppInit"
                Ensure = "Present"
            }

            Script DownloadWebDeploy {
                TestScript = {
                    Test-Path "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
                }
                SetScript = {
                    $source = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
                    $dest = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"

                    if (-not (Test-Path "C:\WindowsAzure")) {
                        New-Item -Path "C:\WindowsAzure" -ItemType Directory -Force
                    }

                    Invoke-WebRequest $source -OutFile $dest
                }
                GetScript = { @{Result = "DownloadWebDeploy" } }
                DependsOn = "[WindowsFeature]WebServerRole"
            }

            Package InstallWebDeploy {
                Ensure = "Present"
                Path = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
                Name = "Microsoft Web Deploy 3.6"
                ProductId = "{6773A61D-755B-4F74-95CC-97920E45E696}"
                Arguments = "ADDLOCAL=ALL"
                DependsOn = "[Script]DownloadWebDeploy"
            }

            Service StartWebDeploy {
                Name = "WMSVC"
                StartupType = "Automatic"
                State = "Running"
                DependsOn = "[Package]InstallWebDeploy"
            }

            if ($WebDeployPackagePath) {
                Script DeployWebPackage {
                    GetScript = {
                        @{
                            Result = "DeployWebPackage"
                        }
                    }
                    TestScript = {
                        $false
                    }
                    SetScript = {
                        $Destination = "C:\WindowsAzure\WebApplication.zip"

                        if (-not (Test-Path "C:\WindowsAzure")) {
                            New-Item -Path "C:\WindowsAzure" -ItemType Directory -Force
                        }

                        Invoke-WebRequest -Uri $using:WebDeployPackagePath -OutFile $Destination

                        $Argument = '-source:package="C:\WindowsAzure\WebApplication.zip" -dest:auto,ComputerName="localhost" -verb:sync -allowUntrusted'
                        $MSDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select-Object -Last 1).GetValue("InstallPath")

                        Start-Process "$MSDeployPath\msdeploy.exe" $Argument -Wait -Verb runas
                    }
                    DependsOn = "[Service]StartWebDeploy"
                }
            }
        }
    }

    Write-Output "InstallIIS DSC Configuration defined successfully"
    Write-Output "To use this configuration, call: InstallIIS -NodeName 'YourNodeName'"
    Write-Output "Node Name: $NodeName"
    if ($WebDeployPackagePath) {
        Write-Output "Web Deploy Package Path: $WebDeployPackagePath"
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}