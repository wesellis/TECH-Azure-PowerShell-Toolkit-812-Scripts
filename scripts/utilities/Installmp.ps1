#Requires -Version 7.4

<#
.SYNOPSIS
    Installs and configures a Configuration Manager Management Point.

.DESCRIPTION
    This script installs and configures a Microsoft System Center Configuration Manager (SCCM)
    Management Point on a designated server. It handles site system creation, management point
    configuration, and database updates.

.PARAMETER DomainFullName
    The fully qualified domain name (FQDN) of the domain.

.PARAMETER DPMPName
    The name of the server to configure as a Management Point.

.PARAMETER Role
    The role identifier for configuration tracking.

.PARAMETER ProvisionToolPath
    The path to the provisioning tools and configuration files.

.EXAMPLE
    .\Installmp.ps1 -DomainFullName "contoso.com" -DPMPName "SCCM-MP01" -Role "ManagementPoint" -ProvisionToolPath "C:\ProvisionTools"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires: SCCM Console and PowerShell module
    Requires: Administrative privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainFullName,

    [Parameter(Mandatory = $true)]
    [string]$DPMPName,

    [Parameter(Mandatory = $true)]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [string]$ProvisionToolPath
)

$ErrorActionPreference = 'Stop'

try {
    $logpath = Join-Path $ProvisionToolPath "InstallMPlog.txt"
    $ConfigurationFile = Join-Path -Path $ProvisionToolPath -ChildPath "$Role.json"

    # Update configuration status
    $Configuration = Get-Content -Path $ConfigurationFile | ConvertFrom-Json
    $Configuration.InstallMP.Status = 'Running'
    $Configuration.InstallMP.StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force

    "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Start running add management point script." | Out-File -Append $logpath

    # Get SCCM installation paths from registry
    $key = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry32)
    $SubKey = $key.OpenSubKey("SOFTWARE\Microsoft\ConfigMgr10\Setup")
    $UiInstallPath = $SubKey.GetValue("UI Installation Directory")
    $ModulePath = Join-Path $UiInstallPath "bin\ConfigurationManager.psd1"

    # Import Configuration Manager module
    if ((Get-Module ConfigurationManager -ErrorAction SilentlyContinue) -eq $null) {
        Import-Module $ModulePath -Force
    }

    # Get site code from registry
    $key64 = [Microsoft.Win32.RegistryKey]::OpenBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, [Microsoft.Win32.RegistryView]::Registry64)
    $SubKey64 = $key64.OpenSubKey("SOFTWARE\Microsoft\SMS\Identification")
    $SiteCode = $SubKey64.GetValue("Site Code")

    $MachineName = "$DPMPName.$DomainFullName"
    $InitParams = @{}
    $ProviderMachineName = "$env:COMPUTERNAME.$DomainFullName"

    "[$(Get-Date -Format "HH:mm:ss")] Setting PS Drive..." | Out-File -Append $logpath

    # Create and set PSDrive for Configuration Manager
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @InitParams -ErrorAction SilentlyContinue

    while ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        "[$(Get-Date -Format "HH:mm:ss")] Retry in 10s to set PS Drive. Please wait." | Out-File -Append $logpath
        Start-Sleep -Seconds 10
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @InitParams -ErrorAction SilentlyContinue
    }

    Set-Location "$($SiteCode):\" @InitParams

    # Get SQL Server information
    $DatabaseValue = 'Database Name'
    $DatabaseName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\SQL Server' -Name 'Database Name').$DatabaseValue
    $InstanceValue = 'Service Name'
    $InstanceName = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\SQL Server' -Name 'Service Name').$InstanceValue

    # Check if site system server exists
    $SystemServer = Get-CMSiteSystemServer -SiteSystemServerName $MachineName -ErrorAction SilentlyContinue

    if (!$SystemServer) {
        "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Creating cm site system server..." | Out-File -Append $logpath
        New-CMSiteSystemServer -SiteSystemServerName $MachineName | Out-File -Append $logpath
        "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Finished creating cm site system server." | Out-File -Append $logpath
        $SystemServer = Get-CMSiteSystemServer -SiteSystemServerName $MachineName
    }

    # Check if management point already exists
    $ExistingMP = Get-CMManagementPoint -SiteSystemServerName $MachineName -ErrorAction SilentlyContinue

    if (($ExistingMP | Measure-Object).Count -ne 1) {
        "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Adding management point on $MachineName..." | Out-File -Append $logpath
        Add-CMManagementPoint -InputObject $SystemServer -CommunicationType Http | Out-File -Append $logpath
        "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Finished adding management point on $MachineName..." | Out-File -Append $logpath

        # Configure SQL connection
        $ConnectionString = "Data Source=.; Integrated Security=SSPI; Initial Catalog=$DatabaseName"
        if ($InstanceName.ToUpper() -ne 'MSSQLSERVER') {
            $ConnectionString = "Data Source=.\$InstanceName; Integrated Security=SSPI; Initial Catalog=$DatabaseName"
        }

        # Update database feature configuration
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $SqlCommand = "INSERT INTO [Feature_EC] (FeatureID,Exposed) VALUES (N'49E3EF35-718B-4D93-A427-E743228F4855',0)"

        $connection.Open()
        $command = New-Object System.Data.SqlClient.SqlCommand($SqlCommand, $connection)
        $command.ExecuteNonQuery() | Out-Null
        $connection.Close()

        # Verify installation
        $NewMP = Get-CMManagementPoint -SiteSystemServerName $MachineName -ErrorAction SilentlyContinue
        if (($NewMP | Measure-Object).Count -eq 1) {
            "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Management Point installation completed successfully." | Out-File -Append $logpath
            $Configuration.InstallMP.Status = 'Completed'
            $Configuration.InstallMP.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        else {
            "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] Failed to install Management Point." | Out-File -Append $logpath
            $Configuration.InstallMP.Status = 'Failed'
            $Configuration.InstallMP.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
    else {
        "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] $MachineName is already a management point, skipping installation." | Out-File -Append $logpath
        $Configuration.InstallMP.Status = 'Already Exists'
        $Configuration.InstallMP.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    # Save final configuration
    $Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force
}
catch {
    $ErrorMessage = "Script execution failed: $($_.Exception.Message)"
    Write-Error $ErrorMessage

    if ($Configuration) {
        $Configuration.InstallMP.Status = 'Failed'
        $Configuration.InstallMP.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $Configuration.InstallMP.Error = $ErrorMessage
        $Configuration | ConvertTo-Json | Out-File -FilePath $ConfigurationFile -Force
    }

    "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] ERROR: $ErrorMessage" | Out-File -Append $logpath
    throw
}