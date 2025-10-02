#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Checks and reports Azure VM power states with  status information

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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
param(
[Parameter(Mandatory = $true)]
)
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
function Write-Log {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "Connecting to Azure..." -ForegroundColor Green
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
    [string]$ResourceGroup,
        [string]$Name,
        [bool]$IncludeDetails
    )
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $PowerState = ($vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
        $ProvisioningState = ($vm.Statuses | Where-Object { $_.Code -like 'ProvisioningState/*' }).DisplayStatus
        $result = [PSCustomObject]@{
            VMName = $vm.Name
            PowerState = $PowerState
            ProvisioningState = $ProvisioningState
            Location = $vm.Location
            ResourceGroup = $ResourceGroup
            LastUpdated = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        if ($IncludeDetails) {
            $result | Add-Member -NotePropertyName 'VMSize' -NotePropertyValue $vm.HardwareProfile.VmSize
            $result | Add-Member -NotePropertyName 'OSType' -NotePropertyValue $vm.StorageProfile.OsDisk.OsType
            $VmAgentStatus = ($vm.Statuses | Where-Object { $_.Code -like 'VMAgent/*' }).DisplayStatus
            if ($VmAgentStatus) {
                $result | Add-Member -NotePropertyName 'VMAgent' -NotePropertyValue $VmAgentStatus
            }
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
            return ($VMStates | Format-Table -AutoSize)
        }
    }
}
function Show-PowerStateColor {
    [string]$PowerState)
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
    [string]$ResourceGroup,
        [string]$Name,
        [int]$Interval
    )
    Write-Host "Starting power state monitor for VM: $Name" -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Green
    Write-Host ("=" * 60) -ForegroundColor Gray
    $LastState = ""
    try {
        while ($true) {
            $VmState = Get-VMPowerState -ResourceGroup $ResourceGroup -Name $Name -IncludeDetails $IncludeDetails
            $CurrentState = $VmState.PowerState
            if ($CurrentState -ne $LastState) {
                $timestamp = Get-Date -Format 'HH:mm:ss'
                $color = Show-PowerStateColor -PowerState $CurrentState
                Write-Output "[$timestamp] " -NoNewline -ForegroundColor Gray
                Write-Output "$Name`: " -NoNewline -ForegroundColor White
                Write-Output "$CurrentState" -ForegroundColor $color
                $LastState = $CurrentState
            }
            Start-Sleep -Seconds $Interval

} catch [System.Management.Automation.PipelineStoppedException] {
        Write-Host "`nMonitoring stopped by user." -ForegroundColor Green
    }
    catch {
        Write-Error "Error during monitoring: $_"
    }
}
Write-Host "`nAzure VM Power State Checker" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
try {
    if ($Watch -and $PSCmdlet.ParameterSetName -eq 'Single') {
        Start-VMWatcher -ResourceGroup $ResourceGroupName -Name $VmName -Interval $WatchInterval
        return
    }
    $VmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
    Write-Host "`nChecking power state for $($VmList.Count) VM(s)..." -ForegroundColor Green
    $VmStates = @()
    foreach ($vm in $VmList) {
        Write-Host "Checking: $vm" -ForegroundColor Green
        $VmState = Get-VMPowerState -ResourceGroup $ResourceGroupName -Name $vm -IncludeDetails $IncludeDetails
        $VmStates += $VmState
    }
    Write-Host "`nPower State Results:" -ForegroundColor Green
    if ($OutputFormat -eq 'Table') {
        foreach ($VmState in $VmStates) {
            $color = Show-PowerStateColor -PowerState $VmState.PowerState
            Write-Output "VM: " -NoNewline
            Write-Output "$($VmState.VMName)" -NoNewline -ForegroundColor White
            Write-Output " | Power State: " -NoNewline
            Write-Output "$($VmState.PowerState)" -NoNewline -ForegroundColor $color
            Write-Output " | Location: " -NoNewline
            Write-Host "$($VmState.Location)" -ForegroundColor Green
            if ($IncludeDetails) {
                Write-Host "Size: $($VmState.VMSize) | OS: $($VmState.OSType)" -ForegroundColor Green
                if ($VmState.VMAgent) {
                    Write-Host "VM Agent: $($VmState.VMAgent)" -ForegroundColor Green
                }
            }
        }
    } else {
        $output = Format-Output -VMStates $VmStates -Format $OutputFormat
        Write-Output $output
    }
    Write-Host "`nSummary:" -ForegroundColor Green
    $RunningCount = ($VmStates | Where-Object { $_.PowerState -like "*running*" }).Count
    $StoppedCount = ($VmStates | Where-Object { $_.PowerState -like "*stopped*" -or $_.PowerState -like "*deallocated*" }).Count
    $OtherCount = $VmStates.Count - $RunningCount - $StoppedCount
    Write-Host "Running: $RunningCount" -ForegroundColor Green
    Write-Host "Stopped/Deallocated: $StoppedCount" -ForegroundColor Green
    if ($OtherCount -gt 0) {
        Write-Host "Other States: $OtherCount" -ForegroundColor Green
    }
    Write-Host "`nLast checked: $(Get-Date)" -ForegroundColor Green
}
catch {
    Write-Error "Failed to check VM power state: $_"
    throw`n}
