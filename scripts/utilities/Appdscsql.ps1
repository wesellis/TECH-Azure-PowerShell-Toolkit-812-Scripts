#Requires -Version 7.4
#Requires -Modules PSDesiredStateConfiguration

<#
.SYNOPSIS
    App DSC SQL Configuration

.DESCRIPTION
    DSC configuration for setting up SQL Server with IIS web server role
    and configuring storage, databases, and firewall rules

.PARAMETER NodeName
    The name of the node to configure

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

Configuration Main {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NodeName
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Node $NodeName {
        # Web Server Features
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

        # Download Web Deploy
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
            GetScript = {
                @{Result = "DownloadWebDeploy"}
            }
            DependsOn = "[WindowsFeature]WebServerRole"
        }

        # Install Web Deploy
        Package InstallWebDeploy {
            Ensure = "Present"
            Path = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
            Name = "Microsoft Web Deploy 3.6"
            ProductId = "{ED4CC1E5-043E-4157-8452-B5E533FE2BA1}"
            Arguments = "ADDLOCAL=ALL"
            DependsOn = "[Script]DownloadWebDeploy"
        }

        # Start Web Deploy Service
        Service StartWebDeploy {
            Name = "WMSVC"
            StartupType = "Automatic"
            State = "Running"
            DependsOn = "[Package]InstallWebDeploy"
        }

        # Configure SQL Server and Storage
        Script ConfigureSql {
            TestScript = {
                $false
            }
            SetScript = {
                $ErrorActionPreference = 'Stop'

                # Configure storage pool and disk
                $disks = Get-Disk | Where-Object { $_.PartitionStyle -eq 'raw' }

                if ($null -ne $disks) {
                    # Get physical disks that can pool
                    $physicalDisks = $disks | Get-PhysicalDisk -CanPool $true

                    if ($physicalDisks) {
                        # Create storage pool
                        New-StoragePool -FriendlyName "VMStoragePool" `
                            -StorageSubsystemFriendlyName "Windows Storage*" `
                            -PhysicalDisks $physicalDisks `
                            -ErrorAction Stop

                        # Create virtual disk
                        New-VirtualDisk -FriendlyName "DataDisk" `
                            -StoragePoolFriendlyName "VMStoragePool" `
                            -ResiliencySettingName "Simple" `
                            -NumberOfColumns $disks.Count `
                            -UseMaximumSize `
                            -Interleave 256KB `
                            -ErrorAction Stop

                        # Initialize and format the disk
                        Get-Disk | Where-Object { $_.PartitionStyle -eq 'raw' } |
                            Initialize-Disk -PartitionStyle MBR -PassThru |
                            New-Partition -DriveLetter "F" -UseMaximumSize |
                            Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk" -Confirm:$false

                        Start-Sleep -Seconds 60
                    }
                }

                # Create SQL directories
                $logs = "F:\Logs"
                $data = "F:\Data"
                $backups = "F:\Backup"

                [System.IO.Directory]::CreateDirectory($logs)
                [System.IO.Directory]::CreateDirectory($data)
                [System.IO.Directory]::CreateDirectory($backups)
                [System.IO.Directory]::CreateDirectory("C:\SQDATA")

                # Configure SQL Server settings
                Import-Module "sqlps" -DisableNameChecking
                [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")

                $sqlServer = New-Object -TypeName 'Microsoft.SqlServer.Management.Smo.Server' -ArgumentList 'Localhost'
                $sqlServer.Settings.LoginMode = [Microsoft.SqlServer.Management.Smo.ServerLoginMode]::Mixed
                $sqlServer.Settings.DefaultFile = $data
                $sqlServer.Settings.DefaultLog = $logs
                $sqlServer.Settings.BackupDirectory = $backups
                $sqlServer.Alter()

                # Restart SQL Server
                Restart-Service -Name "MSSQLSERVER" -Force

                # Enable and configure sa account
                if ($env:CREDENTIAL_PASSWORD) {
                    Invoke-Sqlcmd -ServerInstance "Localhost" -Database "master" -Query "ALTER LOGIN sa ENABLE"
                    Invoke-Sqlcmd -ServerInstance "Localhost" -Database "master" -Query "ALTER LOGIN sa WITH PASSWORD = '$env:CREDENTIAL_PASSWORD'"
                }

                # Download and restore AdventureWorks database
                $dbSource = "https://computeteststore.blob.core.windows.net/deploypackage/AdventureWorks2012.bak?sv=2015-04-05&ss=bfqt&srt=sco&sp=r&se=2099-10-16T02:03:39Z&st=2016-10-15T18:03:39Z&spr=https&sig=aSH6yNPEGPWXk6PxTPzS6fyEXMD1ZYIkI0j5E9Hu5%2Fk%3D"
                $dbDestination = "C:\SQDATA\AdventureWorks2012.bak"

                Invoke-WebRequest $dbSource -OutFile $dbDestination

                # Create relocate file objects for restore
                $mdf = New-Object -TypeName Microsoft.SqlServer.Management.Smo.RelocateFile -ArgumentList @("AdventureWorks2012_Data", "F:\Data\AdventureWorks2012.mdf")
                $ldf = New-Object -TypeName Microsoft.SqlServer.Management.Smo.RelocateFile -ArgumentList @("AdventureWorks2012_Log", "F:\Logs\AdventureWorks2012.ldf")

                # Restore database
                Restore-SqlDatabase -ServerInstance "Localhost" `
                    -Database "AdventureWorks" `
                    -BackupFile $dbDestination `
                    -RelocateFile @($mdf, $ldf) `
                    -ErrorAction Stop

                # Create firewall rule for SQL Server
                New-NetFirewallRule -DisplayName "SQL Server" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 1433 `
                    -Action Allow `
                    -ErrorAction Stop
            }
            GetScript = {
                @{Result = "ConfigureSql"}
            }
        }
    }
}

$ErrorActionPreference = 'Stop'