#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Check Azure VM health and status

.DESCRIPTION
    Retrieves comprehensive health information for an Azure Virtual Machine
    including power state, provisioning state, and detailed status information
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0

.PARAMETER ResourceGroupName
    Name of the resource group containing the VM

.PARAMETER VMName
    Name of the virtual machine to check

.PARAMETER Detailed
    Show detailed status information including all status codes

.PARAMETER OutputFormat
    Output format: Console (default), JSON, or Table

.EXAMPLE
    .\Azure-VM-Health-Monitor.ps1 -ResourceGroupName "rg-prod" -VMName "vm-web01"
    Gets basic health status for the specified VM

.EXAMPLE
    .\Azure-VM-Health-Monitor.ps1 -ResourceGroupName "rg-prod" -VMName "vm-web01" -Detailed
    Gets detailed health status including all status codes

.EXAMPLE
    .\Azure-VM-Health-Monitor.ps1 -ResourceGroupName "rg-prod" -VMName "vm-web01" -OutputFormat JSON
    Outputs health status in JSON format

.NOTES
    Requires Az.Compute module and appropriate permissions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,

    [Parameter()]
    [switch]$Detailed,

    [Parameter()]
    [ValidateSet("Console", "JSON", "Table")]
    [string]$OutputFormat = "Console"
)

$ErrorActionPreference = 'Stop'

function Write-LogMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO"    = "Cyan"
        "WARN"    = "Yellow"
        "ERROR"   = "Red"
        "SUCCESS" = "Green"
    }

    if ($OutputFormat -eq "Console") {
        Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colorMap[$Level]
    }
}

try {
    Write-LogMessage "Retrieving VM health status..." -Level "INFO"
    Write-LogMessage "Resource Group: $ResourceGroupName" -Level "INFO"
    Write-LogMessage "VM Name: $VMName" -Level "INFO"

    # Get VM with status
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status -ErrorAction Stop

    if (-not $vm) {
        throw "VM '$VMName' not found in resource group '$ResourceGroupName'"
    }

    # Build health status object
    $healthStatus = [PSCustomObject]@{
        VMName             = $vm.Name
        ResourceGroup      = $vm.ResourceGroupName
        Location           = $vm.Location
        PowerState         = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" } | Select-Object -First 1).DisplayStatus
        ProvisioningState  = $vm.ProvisioningState
        VMSize             = $vm.HardwareProfile.VmSize
        OSType             = $vm.StorageProfile.OsDisk.OsType
        CheckTime          = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Statuses           = @()
    }

    # Add detailed statuses if requested
    if ($Detailed) {
        $healthStatus.Statuses = $vm.Statuses | ForEach-Object {
            [PSCustomObject]@{
                Code          = $_.Code
                Level         = $_.Level
                DisplayStatus = $_.DisplayStatus
                Message       = $_.Message
                Time          = $_.Time
            }
        }
    }

    # Output in requested format
    switch ($OutputFormat) {
        "JSON" {
            $healthStatus | ConvertTo-Json -Depth 5
        }
        "Table" {
            Write-Host "`n=== VM Health Status ===" -ForegroundColor Cyan
            $healthStatus | Format-List VMName, ResourceGroup, Location, PowerState, ProvisioningState, VMSize, OSType, CheckTime

            if ($Detailed) {
                Write-Host "`n=== Detailed Statuses ===" -ForegroundColor Cyan
                $healthStatus.Statuses | Format-Table Code, DisplayStatus, Level -AutoSize
            }
        }
        "Console" {
            Write-Host "`n=== VM Health Status ===" -ForegroundColor Cyan
            Write-Host "VM Name:            $($healthStatus.VMName)" -ForegroundColor White
            Write-Host "Resource Group:     $($healthStatus.ResourceGroup)" -ForegroundColor White
            Write-Host "Location:           $($healthStatus.Location)" -ForegroundColor White
            Write-Host "VM Size:            $($healthStatus.VMSize)" -ForegroundColor White
            Write-Host "OS Type:            $($healthStatus.OSType)" -ForegroundColor White

            # Color-code power state
            $powerStateColor = switch -Wildcard ($healthStatus.PowerState) {
                "*running*" { "Green" }
                "*deallocated*" { "Yellow" }
                "*stopped*" { "Red" }
                default { "White" }
            }
            Write-Host "Power State:        $($healthStatus.PowerState)" -ForegroundColor $powerStateColor
            Write-Host "Provisioning State: $($healthStatus.ProvisioningState)" -ForegroundColor White
            Write-Host "Check Time:         $($healthStatus.CheckTime)" -ForegroundColor Gray

            if ($Detailed) {
                Write-Host "`n=== Detailed Statuses ===" -ForegroundColor Cyan
                foreach ($status in $vm.Statuses) {
                    $statusColor = switch ($status.Level) {
                        "Info" { "Cyan" }
                        "Warning" { "Yellow" }
                        "Error" { "Red" }
                        default { "White" }
                    }
                    Write-Host "  [$($status.Level)] $($status.Code): $($status.DisplayStatus)" -ForegroundColor $statusColor
                    if ($status.Message) {
                        Write-Host "    Message: $($status.Message)" -ForegroundColor Gray
                    }
                }
            }
            Write-Host ""
        }
    }

    # Return the health status object
    return $healthStatus

} catch {
    Write-LogMessage "Failed to retrieve VM health: $($_.Exception.Message)" -Level "ERROR"
    throw
}
