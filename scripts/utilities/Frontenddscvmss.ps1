#Requires -Version 7.4

<#
.SYNOPSIS
    Frontend DSC configuration for Virtual Machine Scale Sets.

.DESCRIPTION
    This PowerShell DSC configuration script sets up web server frontend infrastructure
    for Virtual Machine Scale Sets (VMSS). It installs and configures IIS, Web Deploy,
    SSL certificates, and deploys web applications with HTTPS redirection.

.PARAMETER NodeName
    The target node name for the DSC configuration.

.PARAMETER WebDeployPackage
    URL or path to the web deployment package.

.PARAMETER CertStoreName
    Certificate store name where SSL certificates are stored.

.PARAMETER CertDomain
    Domain name for SSL certificate lookup.

.EXAMPLE
    Main -NodeName "WebServer01" -WebDeployPackage "https://example.com/package.zip" -CertStoreName "My" -CertDomain "example.com"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
    Requires PSDesiredStateConfiguration and WebAdministration modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$NodeName = "localhost",

    [Parameter(Mandatory = $false)]
    [string]$WebDeployPackage,

    [Parameter(Mandatory = $false)]
    [string]$CertStoreName = "My",

    [Parameter(Mandatory = $false)]
    [string]$CertDomain
)

$ErrorActionPreference = 'Stop'

Configuration Main {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$NodeName,
        [string]$WebDeployPackage,
        [string]$CertStoreName,
        [string]$CertDomain
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName WebAdministration

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

                # Ensure directory exists
                $destDir = Split-Path $dest -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force
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
            ProductId = "{ED4CC1E5-043E-4157-8452-B5E533FE2BA1}"
            Arguments = "ADDLOCAL=ALL"
            DependsOn = "[Script]DownloadWebDeploy"
        }

        Service StartWebDeploy {
            Name = "WMSVC"
            StartupType = "Automatic"
            State = "Running"
            DependsOn = "[Package]InstallWebDeploy"
        }

        Package UrlRewrite {
            DependsOn = "[WindowsFeature]WebServerRole"
            Ensure = "Present"
            Name = "IIS URL Rewrite Module 2"
            Path = "http://download.microsoft.com/download/6/7/D/67D80164-7DD0-48AF-86E3-DE7A182D6815/rewrite_2.0_rtw_x64.msi"
            Arguments = "/quiet"
            ProductId = "EB675D0A-2C95-405B-BEE8-B42A65D23E11"
        }

        if ($WebDeployPackage) {
            Script DeployWebPackage {
                GetScript = { @{Result = "DeployWebPackage" } }
                TestScript = { $false }
                SetScript = {
                    [System.IO.Directory]::CreateDirectory("C:\WebApp")
                    $dest = "C:\WebApp\Site.zip"
                    Remove-Item -Path "C:\inetpub\wwwroot" -Force -Recurse -ErrorAction SilentlyContinue
                    Invoke-WebRequest $using:WebDeployPackage -OutFile $dest
                    Add-Type -Assembly "system.io.compression.filesystem"
                    [IO.Compression.ZipFile]::ExtractToDirectory($dest, "C:\inetpub\wwwroot")

                    if ($using:CertStoreName -and $using:CertDomain) {
                        $CertPath = 'cert:\LocalMachine\' + $using:CertStoreName
                        $CertObj = Get-ChildItem -Path $CertPath -DNSName $using:CertDomain

                        if ($CertObj) {
                            New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https
                            $CertWThumb = $CertPath + '\' + $CertObj.Thumbprint
                            Set-Location IIS:\SSLBindings
                            Get-Item -ErrorAction Stop $CertWThumb | New-Item -ErrorAction Stop 0.0.0.0!443
                            Set-Location C:

                            # Configure HTTP to HTTPS redirect
                            Add-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webserver/rewrite/GlobalRules" -Name "." -Value @{name='HTTP to HTTPS Redirect'; patternSyntax='ECMAScript'; stopProcessing='True'}
                            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webserver/rewrite/GlobalRules/rule[@name='HTTP to HTTPS Redirect']/match" -Name url -Value "(.*)"
                            Add-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webserver/rewrite/GlobalRules/rule[@name='HTTP to HTTPS Redirect']/conditions" -Name "." -Value @{input="{HTTPS}"; pattern='^OFF$'}
                            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/rewrite/globalRules/rule[@name='HTTP to HTTPS Redirect']/action" -Name "type" -Value "Redirect"
                            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/rewrite/globalRules/rule[@name='HTTP to HTTPS Redirect']/action" -Name "url" -Value "https://{HTTP_HOST}/{R:1}"
                            Set-WebConfigurationProperty -PSPath 'MACHINE/WEBROOT/APPHOST' -Filter "system.webServer/rewrite/globalRules/rule[@name='HTTP to HTTPS Redirect']/action" -Name "redirectType" -Value "SeeOther"
                        }
                    }
                }
                DependsOn = "[WindowsFeature]WebServerRole"
            }

            File WebContent {
                Ensure = "Present"
                SourcePath = "C:\WebApp"
                DestinationPath = "C:\Inetpub\wwwroot"
                Recurse = $true
                Type = "Directory"
                DependsOn = "[Script]DeployWebPackage"
            }
        }
    }
}

try {
    # Generate the configuration
    Main -NodeName $NodeName -WebDeployPackage $WebDeployPackage -CertStoreName $CertStoreName -CertDomain $CertDomain
    Write-Output "Frontend DSC configuration generated successfully for node: $NodeName"
}
catch {
    Write-Error "Failed to generate frontend DSC configuration: $($_.Exception.Message)"
    throw
}