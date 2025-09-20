<#
.SYNOPSIS
    Checks and reports Azure VM power states with  status information

.DESCRIPTION
    Retrieves  power state and status information for Azure VMs.
    Supports single VM or multiple VM checking with formatted output and monitoring options.
.PARAMETER ResourceGroupName
    Resource group
.PARAMETER VmName
    VM name
.PARAMETER VmNames
    VM names array
.PARAMETER OutputFormat
    Output format: Table, JSON, CSV
.PARAMETER IncludeDetails
    Include additional VM details like size, location, etc.
.PARAMETER Watch
    Continuously monitor VM power state changes
.PARAMETER WatchInterval
    Interval in seconds for watch mode (default: 30)
    .\Azure-VM-PowerState-Checker.ps1 -ResourceGroupName "RG-Production" -VmName "VM-WebServer01"
    .\Azure-VM-PowerState-Checker.ps1 -ResourceGroupName "RG-Production" -VmNames @("VM-Web01", "VM-Web02") -OutputFormat Table
    .\Azure-VM-PowerState-Checker.ps1 -ResourceGroupName "RG-Production" -VmName "VM-WebServer01" -Watch -WatchInterval 60
#>
[CmdletBinding(DefaultParameterSetName = 'Single')]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [Parameter(Mandatory = $true, ParameterSetName = 'Multiple')]
    [ValidateCount(1, 100)]
    [string[]]$VmNames,
    [Parameter()]
    [ValidateSet('Table', 'JSON', 'CSV')]
    [string]$OutputFormat = 'Table',
    [Parameter()]
    [switch]$IncludeDetails,
    [Parameter(ParameterSetName = 'Single')]
    [switch]$Watch,
    [Parameter(ParameterSetName = 'Single')]
    [int]$WatchInterval = 30
)
$ErrorActionPreference = 'Stop'
function Test-AzureConnection {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Yellow
            Connect-AzAccount
        }
        return $true
    }
    catch {
        Write-Error "Failed to establish Azure connection: $_"
        return $false
    }
}
function Get-VMPowerState {
    param(
        [string]$ResourceGroup,
        [string]$Name,
        [bool]$IncludeDetails
    )
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $powerState = ($vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
        $provisioningState = ($vm.Statuses | Where-Object { $_.Code -like 'ProvisioningState/*' }).DisplayStatus
        $result = [PSCustomObject]@{
            VMName = $vm.Name
            PowerState = $powerState
            ProvisioningState = $provisioningState
            Location = $vm.Location
            ResourceGroup = $ResourceGroup
            LastUpdated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        if ($IncludeDetails) {
            $result | Add-Member -NotePropertyName 'VMSize' -NotePropertyValue $vm.HardwareProfile.VmSize
            $result | Add-Member -NotePropertyName 'OSType' -NotePropertyValue $vm.StorageProfile.OsDisk.OsType
            # Get VM agent status if available
            $vmAgentStatus = ($vm.Statuses | Where-Object { $_.Code -like 'VMAgent/*' }).DisplayStatus
            if ($vmAgentStatus) {
                $result | Add-Member -NotePropertyName 'VMAgent' -NotePropertyValue $vmAgentStatus
            }
            # Get boot diagnostics status
            if ($vm.DiagnosticsProfile -and $vm.DiagnosticsProfile.BootDiagnostics) {
                $result | Add-Member -NotePropertyName 'BootDiagnostics' -NotePropertyValue $vm.DiagnosticsProfile.BootDiagnostics.Enabled
            }
        }
        return $result
    }
    catch {
        return [PSCustomObject]@{
            VMName = $Name
            PowerState = "Error: $($_.Exception.Message)"
            ProvisioningState = "Unknown"
            Location = "Unknown"
            ResourceGroup = $ResourceGroup
            LastUpdated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
}
function Format-Output {
    param(
        [object[]]$VMStates,
        [string]$Format
    )
    switch ($Format) {
        'JSON' {
            return ($VMStates | ConvertTo-Json -Depth 3)
        }
        'CSV' {
            return ($VMStates | ConvertTo-Csv -NoTypeInformation)
        }
        default {
            # Table format
            return ($VMStates | Format-Table -AutoSize)
        }
    }
}
function Show-PowerStateColor {
    param([string]$PowerState)
    switch -Wildcard ($PowerState) {
        "*running*" { return 'Green' }
        "*stopped*" { return 'Red' }
        "*deallocated*" { return 'Yellow' }
        "*starting*" { return 'Cyan' }
        "*stopping*" { return 'Magenta' }
        default { return 'White' }
    }
}
function Start-VMWatcher {
    param(
        [string]$ResourceGroup,
        [string]$Name,
        [int]$Interval
    )
    Write-Host "Starting power state monitor for VM: $Name" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    Write-Host ("=" * 60) -ForegroundColor Gray
    $lastState = ""
    try {
        while ($true) {
            $vmState = Get-VMPowerState -ResourceGroup $ResourceGroup -Name $Name -IncludeDetails $IncludeDetails
            $currentState = $vmState.PowerState
            # Only display if state changed or first run
            if ($currentState -ne $lastState) {
                $timestamp = Get-Date -Format 'HH:mm:ss'
                $color = Show-PowerStateColor -PowerState $currentState
                Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
                Write-Host "$Name`: " -NoNewline -ForegroundColor White
                Write-Host "$currentState" -ForegroundColor $color
                $lastState = $currentState
            }
            Start-Sleep -Seconds $Interval
        
} catch [System.Management.Automation.PipelineStoppedException] {
        Write-Host "`nMonitoring stopped by user." -ForegroundColor Yellow
    }
    catch {
        Write-Error "Error during monitoring: $_"
    }
}
# Main execution
Write-Host "`nAzure VM Power State Checker" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
# Test Azure connection
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
try {
    # Handle watch mode for single VM
    if ($Watch -and $PSCmdlet.ParameterSetName -eq 'Single') {
        Start-VMWatcher -ResourceGroup $ResourceGroupName -Name $VmName -Interval $WatchInterval
        return
    }
    # Prepare VM list
    $vmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
    Write-Host "`nChecking power state for $($vmList.Count) VM(s)..." -ForegroundColor Yellow
    # Get power states
    $vmStates = @()
    foreach ($vm in $vmList) {
        Write-Host "Checking: $vm" -ForegroundColor Gray
        $vmState = Get-VMPowerState -ResourceGroup $ResourceGroupName -Name $vm -IncludeDetails $IncludeDetails
        $vmStates += $vmState
    }
    # Display results
    Write-Host "`nPower State Results:" -ForegroundColor Cyan
    if ($OutputFormat -eq 'Table') {
        # Custom table display with colors
        foreach ($vmState in $vmStates) {
            $color = Show-PowerStateColor -PowerState $vmState.PowerState
            Write-Host "VM: " -NoNewline
            Write-Host "$($vmState.VMName)" -NoNewline -ForegroundColor White
            Write-Host " | Power State: " -NoNewline
            Write-Host "$($vmState.PowerState)" -NoNewline -ForegroundColor $color
            Write-Host " | Location: " -NoNewline
            Write-Host "$($vmState.Location)" -ForegroundColor Gray
            if ($IncludeDetails) {
                Write-Host "Size: $($vmState.VMSize) | OS: $($vmState.OSType)" -ForegroundColor Gray
                if ($vmState.VMAgent) {
                    Write-Host "VM Agent: $($vmState.VMAgent)" -ForegroundColor Gray
                }
            }
        }
    } else {
        # JSON or CSV output
        $output = Format-Output -VMStates $vmStates -Format $OutputFormat
        Write-Output $output
    }
    # Summary
    Write-Host "`nSummary:" -ForegroundColor Cyan
    $runningCount = ($vmStates | Where-Object { $_.PowerState -like "*running*" }).Count
    $stoppedCount = ($vmStates | Where-Object { $_.PowerState -like "*stopped*" -or $_.PowerState -like "*deallocated*" }).Count
    $otherCount = $vmStates.Count - $runningCount - $stoppedCount
    Write-Host "Running: $runningCount" -ForegroundColor Green
    Write-Host "Stopped/Deallocated: $stoppedCount" -ForegroundColor Red
    if ($otherCount -gt 0) {
        Write-Host "Other States: $otherCount" -ForegroundColor Yellow
    }
    Write-Host "`nLast checked: $(Get-Date)" -ForegroundColor Gray
}
catch {
    Write-Error "Failed to check VM power state: $_"
    throw
}

