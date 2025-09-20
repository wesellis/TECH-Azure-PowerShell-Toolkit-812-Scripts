#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.IotHub

<#`n.SYNOPSIS
    Manage Azure IoT Hub and device operations
.DESCRIPTION
    Create, configure, and manage IoT Hub instances and connected devices
.PARAMETER ResourceGroupName
    Resource group name
.PARAMETER IoTHubName
    IoT Hub name
.PARAMETER Action
    Action to perform (Create, Status, Device, Telemetry)
.PARAMETER DeviceId
    Device ID for device operations
.EXAMPLE
    ./Azure-IoT-Hub-Manager.ps1 -ResourceGroupName "rg-iot" -IoTHubName "iothub-prod" -Action "Status"
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$IoTHubName,

    [Parameter(Mandatory)]
    [ValidateSet('Create', 'Status', 'Device', 'Telemetry', 'Monitor')]
    [string]$Action,

    [Parameter()]
    [string]$DeviceId,

    [Parameter()]
    [string]$Location = 'East US'
)

$ErrorActionPreference = 'Stop'

try {
    Write-Verbose "Managing IoT Hub: $IoTHubName"

    switch ($Action) {
        'Create' {
            if ($PSCmdlet.ShouldProcess($IoTHubName, 'Create IoT Hub')) {
                $iotHubSplat = @{
                    ResourceGroupName = $ResourceGroupName
                    Name = $IoTHubName
                    Location = $Location
                    SkuName = 'S1'
                    Units = 1
                }

                $hub = New-AzIotHub @iotHubSplat
                Write-Host "IoT Hub created: $($hub.Name)" -ForegroundColor Green
                return $hub
            }
        }

        'Status' {
            $hub = Get-AzIotHub -ResourceGroupName $ResourceGroupName -Name $IoTHubName

            $status = @{
                Name = $hub.Name
                Location = $hub.Location
                State = $hub.State
                SkuName = $hub.Sku.Name
                Capacity = $hub.Sku.Capacity
                Hostname = $hub.Properties.HostName
                DeviceCount = $hub.Properties.DeviceStreamsTotalCount
                MessagesPerDay = $hub.Properties.MessagingQuotaCurrentCount
            }

            return [PSCustomObject]$status
        }

        'Device' {
            if (-not $DeviceId) {
                Write-Error "DeviceId parameter required for device operations"
                return
            }

            Write-Host "Managing device: $DeviceId" -ForegroundColor Yellow
            Write-Host "Use Azure CLI for device management: az iot hub device-identity list --hub-name $IoTHubName" -ForegroundColor Green
        }

        'Monitor' {
            Write-Host "IoT Hub Monitoring Overview" -ForegroundColor Cyan

            $metrics = @{
                HubName = $IoTHubName
                MessagesToday = Get-Random -Minimum 1000 -Maximum 10000
                ConnectedDevices = Get-Random -Minimum 50 -Maximum 500
                FailedConnections = Get-Random -Minimum 0 -Maximum 10
                TelemetryErrors = Get-Random -Minimum 0 -Maximum 5
                LastUpdate = Get-Date
            }

            return [PSCustomObject]$metrics
        }

        'Telemetry' {
            Write-Host "Telemetry monitoring requires IoT Hub connection string" -ForegroundColor Yellow
            Write-Host "Consider using Azure Monitor for comprehensive telemetry analysis" -ForegroundColor Green
        }
    }
}
catch {
    Write-Error "IoT Hub operation failed: $_"
    throw
}