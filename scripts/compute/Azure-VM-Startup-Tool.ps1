#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Starts Azure Virtual Machines

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Starts Azure VMs with proper validation, confirmation prompts, and
    optional monitoring of the startup process. Supports both single VM
    and batch startup operations.
.PARAMETER ResourceGroupName
    Resource group
.PARAMETER VmName
    VM name
.PARAMETER VmNames
    VM names array
.PARAMETER Wait
    Wait for completion
.PARAMETER TimeoutMinutes
    Timeout (minutes)
.PARAMETER Force
    Skip confirmation
    .\Azure-VM-Startup-Tool.ps1 -ResourceGroupName "RG-Production" -VmName "VM-WebServer01"
    .\Azure-VM-Startup-Tool.ps1 -ResourceGroupName "RG-Production" -VmNames @("VM-Web01", "VM-Web02") -Force
    .\Azure-VM-Startup-Tool.ps1 -ResourceGroupName "RG-Production" -VmName "VM-WebServer01" -Wait
param(
[Parameter(Mandatory = $true)]
)
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [Parameter(Mandatory = $true, ParameterSetName = 'Multiple')]
    [ValidateCount(1, 50)]
    [string[]]$VmNames,
    [Parameter()]
    [switch]$Wait,
    [Parameter()]
    [ValidateRange(1, 60)]
    [int]$TimeoutMinutes = 10,
    [Parameter()]
    [switch]$Force
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
function Get-VMStartupState {
    [string]$ResourceGroup,
        [string]$Name
    )
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $PowerState = ($vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
        return @{
            VM = $vm
            PowerState = $PowerState
            IsRunning = $PowerState -eq 'VM running'
            IsStopped = $PowerState -like '*stopped*' -or $PowerState -like '*deallocated*'

} catch {
        throw "Failed to get VM state for $Name : $_"
    }
}
function Start-AzureVM {
    [string]$ResourceGroup,
        [string]$Name
    )
    try {
        Write-Host "Checking VM state..." -ForegroundColor Green
        $VmState = Get-VMStartupState -ResourceGroup $ResourceGroup -Name $Name
        Write-Host "VM Details:" -ForegroundColor Green
        Write-Output "Name: $($VmState.VM.Name)"
        Write-Output "Current State: $($VmState.PowerState)"
        Write-Output "Location: $($VmState.VM.Location)"
        Write-Output "Size: $($VmState.VM.HardwareProfile.VmSize)"
        if ($VmState.IsRunning) {
            Write-Host "VM is already running: $($VmState.PowerState)" -ForegroundColor Green
            return @{
                VMName = $Name
                Success = $true
                Message = "VM was already running"
                PowerState = $VmState.PowerState
            }
        }
        if (-not $VmState.IsStopped) {
            Write-Warning "VM is in transitional state: $($VmState.PowerState)"
        }
        Write-Host "Starting VM..." -ForegroundColor Green
        if ($PSCmdlet.ShouldProcess($Name, "Start VM")) {
            Start-AzVM -ResourceGroupName $ResourceGroup -Name $Name
            Write-Host "Startup command initiated for $Name" -ForegroundColor Green
            return @{
                VMName = $Name
                Success = $true
                Message = "Startup initiated successfully"
            }

} catch {
        return @{
            VMName = $Name
            Success = $false
            Message = $_.Exception.Message
        }
    }
}
function Wait-ForVMStartup {
    [string]$ResourceGroup,
        [string]$Name,
        [int]$TimeoutMinutes
    )
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $LastState = ""
    Write-Host "Waiting for VM to start (timeout: $TimeoutMinutes minutes)..." -ForegroundColor Green
    do {
        try {
            $VmState = Get-VMStartupState -ResourceGroup $ResourceGroup -Name $Name
            $CurrentState = $VmState.PowerState
            if ($CurrentState -ne $LastState) {
                Write-Host "Current state: $CurrentState" -ForegroundColor Green
                $LastState = $CurrentState
            }
            if ($VmState.IsRunning) {
                Write-Host "VM startup completed: $CurrentState" -ForegroundColor Green
                return $true
            }
            Start-Sleep -Seconds 10
        }
        catch {
            Write-Warning "Error checking VM state: $_"
            Start-Sleep -Seconds 10
        }
    } while ((Get-Date) -lt $timeout)
    Write-Warning "Timeout reached. VM may still be starting up."
    return $false
}
Write-Host "`nAzure VM Startup Tool" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
$VmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
if (-not $Force) {
    $VmCount = $VmList.Count
    $VmText = if ($VmCount -eq 1) { "VM" } else { "$VmCount VMs" }
    Write-Host "`nAbout to start $VmText in resource group '$ResourceGroupName':" -ForegroundColor Green
    foreach ($vm in $VmList) {
        Write-Host "  - $vm" -ForegroundColor Green
    }
    $confirmation = Read-Host "`nContinue? (y/N)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Green
        exit 0
    }
}
Write-Host "`nStarting VM startup operations..." -ForegroundColor Green
$results = @()
foreach ($vm in $VmList) {
    try {
        Write-Host "`nProcessing VM: $vm" -ForegroundColor Green
        $result = Start-AzureVM -ResourceGroup $ResourceGroupName -Name $vm
        $results += $result
        if ($result.Success -and $Wait) {
            $WaitResult = Wait-ForVMStartup -ResourceGroup $ResourceGroupName -Name $vm -TimeoutMinutes $TimeoutMinutes
            $result.WaitCompleted = $WaitResult

} catch {
        $ErrorResult = @{
            VMName = $vm
            Success = $false
            Message = $_.Exception.Message
        }
        $results += $ErrorResult
    }
}
Write-Host "`nStartup Operation Summary" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
$successful = ($results | Where-Object { $_.Success }).Count
$failed = ($results | Where-Object { -not $_.Success }).Count
Write-Output "Total VMs: $($results.Count)"
Write-Host "Successful: $successful" -ForegroundColor Green
Write-Output "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })
if ($failed -gt 0) {
    Write-Host "`nFailed VMs:" -ForegroundColor Green
    $results | Where-Object { -not $_.Success } | ForEach-Object {
        Write-Host "  - $($_.VMName): $($_.Message)" -ForegroundColor Green
    }
}
Write-Host "`nOperation completed!" -ForegroundColor Green
$ExitCode = if ($failed -gt 0) { 1 } else { 0 }
exit $ExitCode



