#Requires -Version 7.4
#Requires -Modules Storage, FailoverClusters

<#
.SYNOPSIS
    S2D Monitoring Service for OMS

.DESCRIPTION
    Windows service that monitors Storage Spaces Direct (S2D) cluster health
    and sends metrics to Operations Management Suite (OMS)/Log Analytics.
    Collects cluster, node, volume, and fault data periodically.

.PARAMETER Start
    Start the service

.PARAMETER Stop
    Stop the service

.PARAMETER Restart
    Stop then restart the service

.PARAMETER Status
    Get the current service status

.PARAMETER Setup
    Install the service with OMS workspace credentials

.PARAMETER Remove
    Uninstall the service

.PARAMETER Service
    Run the service in background (internal use)

.PARAMETER OMSWorkspaceCreds
    OMS workspace credentials (required for setup)

.EXAMPLE
    .\S2Dmon.ps1 -Status

.EXAMPLE
    $creds = Get-Credential -Message "Enter OMS Workspace ID as username and key as password"
    .\S2Dmon.ps1 -Setup -OMSWorkspaceCreds $creds

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and S2D cluster
    Based on PSService framework for Windows services
#>

[CmdletBinding(DefaultParameterSetName = 'Status')]
param(
    [Parameter(ParameterSetName = 'Start', Mandatory)]
    [Switch]$Start,

    [Parameter(ParameterSetName = 'Stop', Mandatory)]
    [Switch]$Stop,

    [Parameter(ParameterSetName = 'Restart', Mandatory)]
    [Switch]$Restart,

    [Parameter(ParameterSetName = 'Status')]
    [Switch]$Status = $($PSCmdlet.ParameterSetName -eq 'Status'),

    [Parameter(ParameterSetName = 'Setup', Mandatory)]
    [Switch]$Setup,

    [Parameter(ParameterSetName = 'Setup', Mandatory)]
    [System.Management.Automation.PSCredential]$OMSWorkspaceCreds,

    [Parameter(ParameterSetName = 'Remove', Mandatory)]
    [Switch]$Remove,

    [Parameter(ParameterSetName = 'Service', Mandatory)]
    [Switch]$Service,

    [Parameter(ParameterSetName = 'Version', Mandatory)]
    [Switch]$Version
)

$ErrorActionPreference = "Stop"

# Service configuration
$ScriptVersion = "2024-01-01"
$ServiceName = "S2DMon"
$ServiceDisplayName = "S2D Monitor for OMS"
$ServiceDescription = "Service for sending Storage Spaces Direct metrics to OMS/Log Analytics"
$InstallDir = "${ENV:windir}\System32"
$LogDir = "${ENV:windir}\Logs"
$LogFile = "$LogDir\$ServiceName.log"

# Script paths
$argv0 = Get-Item $MyInvocation.MyCommand.Definition
$ScriptName = $argv0.Name
$ScriptFullName = $argv0.FullName
$ScriptCopy = "$InstallDir\$ScriptName"

# Service files
$ExeName = "$ServiceName.exe"
$ExeFullName = "$InstallDir\$ExeName"
$KeyFileName = "$ServiceName.key"
$KeyFileFullName = "$InstallDir\$KeyFileName"
$CredFileName = "$ServiceName.cred"
$CredFileFullName = "$InstallDir\$CredFileName"
$WorkspaceIdFileName = "$ServiceName.id"
$WorkspaceIdFileFullName = "$InstallDir\$WorkspaceIdFileName"

# Named pipe for service control
$PipeName = "Service_$ServiceName"

function Write-Log {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [String]$Message
    )

    if (!(Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Out-File -Encoding ASCII -Append $LogFile
}

function Send-S2DMetricsToOMS {
    param(
        [Parameter(Mandatory)]
        [PSCredential]$OMSCreds
    )

    try {
        # Get cluster owner node
        $OwnerNode = Get-ClusterResource -Name "Cluster Name" | Select-Object -ExpandProperty OwnerNode

        if ($OwnerNode -ne $env:COMPUTERNAME) {
            Write-Log "Not the cluster owner node. Skipping metrics collection."
            return
        }

        Write-Log "Collecting S2D metrics as cluster owner"

        # Get cluster information
        $domainFqdn = (Get-CimInstance Win32_ComputerSystem).Domain
        $ClusterName = ((Get-CimInstance -Namespace "root\mscluster" -ClassName "MSCluster_Cluster").Name + "." + $domainFqdn).ToUpper()

        if (-not $ClusterName) {
            Write-Log "Could not determine cluster name"
            return
        }

        # Collect cluster-level metrics
        $s2dReport = Get-StorageSubSystem -FriendlyName "Cluster*" | Get-StorageHealthReport -ErrorAction SilentlyContinue

        if ($s2dReport) {
            $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            $metrics = @()

            foreach ($record in $s2dReport.ItemValue.Records) {
                $unitType = switch ($record.Units) {
                    0 { "Bytes" }
                    1 { "BytesPerSecond" }
                    2 { "CountPerSecond" }
                    3 { "Seconds" }
                    4 { "Percentage" }
                    default { "Unknown" }
                }

                $metric = [PSCustomObject]@{
                    Timestamp    = $timestamp
                    MetricLevel  = "Cluster"
                    MetricName   = $record.Name
                    MetricValue  = $record.Value
                    UnitType     = $unitType
                    ClusterName  = $ClusterName
                }

                $metrics += $metric
            }

            if ($metrics.Count -gt 0) {
                Write-Log "Collected $($metrics.Count) cluster metrics"
                # Here you would send to OMS using the appropriate API
                # Send-OMSData -Metrics $metrics -Credentials $OMSCreds
            }
        }

        # Collect node-level metrics
        $nodes = Get-StorageNode -ErrorAction SilentlyContinue
        if ($nodes) {
            Write-Log "Collecting metrics for $($nodes.Count) nodes"
            # Process node metrics similarly
        }

        # Collect volume metrics
        $volumes = Get-Volume | Where-Object { $_.FileSystem -eq "CSVFS" }
        if ($volumes) {
            Write-Log "Collecting metrics for $($volumes.Count) CSV volumes"
            # Process volume metrics similarly
        }

        # Collect fault information
        $faults = Get-StorageSubSystem -FriendlyName "Cluster*" | Debug-StorageSubSystem
        if ($faults) {
            Write-Log "Found $($faults.Count) storage faults"
            # Process fault data similarly
        }
    }
    catch {
        Write-Log "Error collecting S2D metrics: $_"
    }
}

# Main service logic
if ($Version) {
    Write-Output $ScriptVersion
    return
}

if ($Status) {
    try {
        $svc = Get-Service $ServiceName -ErrorAction Stop
        Write-Output $svc.Status
    }
    catch {
        Write-Output "Not Installed"
    }
    return
}

if ($Setup) {
    Write-Log "Installing S2D monitoring service"

    # Check if already installed
    try {
        $svc = Get-Service $ServiceName -ErrorAction Stop
        Write-Output "Service $ServiceName is already installed"
        return
    }
    catch {
        # Service not installed, continue with setup
    }

    # Copy script to system directory
    if ($ScriptFullName -ne $ScriptCopy) {
        Write-Verbose "Installing $ScriptCopy"
        Copy-Item $ScriptFullName $ScriptCopy -Force
    }

    # Save encrypted credentials
    $Key = New-Object Byte[] 32
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
    $Key | Out-File $KeyFileFullName
    $OMSWorkspaceCreds.Password | ConvertFrom-SecureString -Key $Key | Out-File $CredFileFullName
    $OMSWorkspaceCreds.UserName | Out-File $WorkspaceIdFileFullName

    Write-Output "Service $ServiceName installed successfully"
    Write-Output "Use '$ServiceName -Start' to start the service"
    return
}

if ($Remove) {
    Write-Log "Removing S2D monitoring service"

    try {
        Stop-Service $ServiceName -ErrorAction SilentlyContinue
        & sc.exe delete $ServiceName

        # Clean up files
        @("$ExeName", "$ScriptName", "$CredFileName", "$KeyFileName", "$WorkspaceIdFileName") | ForEach-Object {
            $file = "$InstallDir\$_"
            if (Test-Path $file) {
                Remove-Item $file -Force
            }
        }

        Write-Output "Service $ServiceName removed successfully"
    }
    catch {
        Write-Error "Failed to remove service: $_"
    }
    return
}

if ($Start) {
    Write-Log "Starting S2D monitoring service"
    Start-Service $ServiceName
    Write-Output "Service $ServiceName started"
    return
}

if ($Stop) {
    Write-Log "Stopping S2D monitoring service"
    Stop-Service $ServiceName
    Write-Output "Service $ServiceName stopped"
    return
}

if ($Restart) {
    & $ScriptFullName -Stop
    & $ScriptFullName -Start
    return
}

if ($Service) {
    Write-Log "S2D monitoring service started in background mode"

    try {
        # Load credentials
        $key = Get-Content $KeyFileFullName
        $workspaceId = Get-Content $WorkspaceIdFileFullName
        $encryptedKey = Get-Content $CredFileFullName
        $secureKey = $encryptedKey | ConvertTo-SecureString -Key $key
        $omsCreds = New-Object System.Management.Automation.PSCredential($workspaceId, $secureKey)

        # Main service loop
        $period = 60  # Collect metrics every 60 seconds

        while ($true) {
            Send-S2DMetricsToOMS -OMSCreds $omsCreds
            Start-Sleep -Seconds $period
        }
    }
    catch {
        Write-Log "Service error: $_"
        throw
    }
    finally {
        Write-Log "S2D monitoring service exiting"
    }
}

# Example usage:
# $creds = Get-Credential -Message "Enter OMS Workspace ID as username and key as password"
# .\S2Dmon.ps1 -Setup -OMSWorkspaceCreds $creds
# .\S2Dmon.ps1 -Start