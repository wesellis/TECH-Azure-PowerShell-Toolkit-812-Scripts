#Requires -Version 7.4

<#
.SYNOPSIS
    Application DSC configuration

.DESCRIPTION
    Azure automation DSC configuration for web application deployment

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$NodeName,

    [Parameter(Mandatory = $true)]
    [string]$WebDeployPackage,

    [Parameter()]
    [string]$CertStoreName = "My",

    [Parameter()]
    [string]$CertDomain
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

Configuration Main {
    param(
        [Parameter(Mandatory = $true)]
        [string]$NodeName,

        [Parameter(Mandatory = $true)]
        [string]$WebDeployPackage,

        [Parameter()]
        [string]$CertStoreName = "My",

        [Parameter()]
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

        WindowsFeature HttpLogging {
            Name = "Web-Http-Logging"
            Ensure = "Present"
        }

        WindowsFeature HttpCompressionStatic {
            Name = "Web-Stat-Compression"
            Ensure = "Present"
        }

        WindowsFeature HttpCompressionDynamic {
            Name = "Web-Dyn-Compression"
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

        Package WebDeploy {
            Ensure = "Present"
            Name = "Microsoft Web Deploy 3.6"
            Path = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
            ProductId = "{6773A61D-755B-4F74-95CC-97920E45E696}"
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        Script DeployWebPackage {
            SetScript = {
                Add-Type -AssemblyName "system.io.compression.filesystem"
                [System.IO.Compression.ZipFile]::ExtractToDirectory($using:WebDeployPackage, "C:\inetpub\wwwroot")
            }
            TestScript = {
                Test-Path "C:\inetpub\wwwroot\web.config"
            }
            GetScript = {
                @{ Result = (Get-ChildItem "C:\inetpub\wwwroot").Count }
            }
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        if ($CertDomain) {
            Script ConfigureHTTPS {
                SetScript = {
                    $cert = Get-ChildItem -Path "Cert:\LocalMachine\$using:CertStoreName" | Where-Object { $_.Subject -match $using:CertDomain } | Select-Object -First 1
                    if ($cert) {
                        Import-Module WebAdministration
                        if (-not (Get-WebBinding -Name "Default Web Site" -Protocol https)) {
                            New-WebBinding -Name "Default Web Site" -Protocol https -Port 443
                        }
                        $binding = Get-WebBinding -Name "Default Web Site" -Protocol https
                        $binding.AddSslCertificate($cert.Thumbprint, "my")
                    }
                }
                TestScript = {
                    $binding = Get-WebBinding -Name "Default Web Site" -Protocol https -ErrorAction SilentlyContinue
                    return ($null -ne $binding)
                }
                GetScript = {
                    @{ Result = (Get-WebBinding -Name "Default Web Site" -Protocol https -ErrorAction SilentlyContinue) }
                }
                DependsOn = "[WindowsFeature]WebServerRole"
            }
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

# Generate the MOF file
Main -NodeName $NodeName -WebDeployPackage $WebDeployPackage -CertStoreName $CertStoreName -CertDomain $CertDomain