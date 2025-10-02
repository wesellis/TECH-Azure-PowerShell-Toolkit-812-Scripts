#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Safely shuts down Azure Virtual Machines

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
    Shuts down Azure VMs with proper validation, confirmation prompts, and
    optional monitoring of the shutdown process. Supports both graceful
    and forced shutdown options.
.PARAMETER ResourceGroupName
    Resource group
.PARAMETER VmName
    VM name
.PARAMETER VmNames
    VM names array
.PARAMETER Graceful
    Attempt graceful shutdown (preserves allocated resources)
.PARAMETER Force
    Skip confirmation
.PARAMETER Wait
    Wait for completion
.PARAMETER TimeoutMinutes
    Timeout (minutes)
    .\Azure-VM-Shutdown-Tool.ps1 -ResourceGroupName "RG-Production" -VmName "VM-WebServer01"
    .\Azure-VM-Shutdown-Tool.ps1 -ResourceGroupName "RG-Production" -VmNames @("VM-Web01", "VM-Web02") -Force
    .\Azure-VM-Shutdown-Tool.ps1 -ResourceGroupName "RG-Production" -VmName "VM-WebServer01" -Graceful -Wait
    Graceful shutdown preserves allocated resources while standard shutdown deallocates them.
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
    [switch]$Graceful,
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$Wait,
    [Parameter()]
    [int]$TimeoutMinutes = 10
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
function Get-VMShutdownState {
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

} catch {
        throw "Failed to get VM state for $Name : $_"
    }
}
function Stop-AzureVM {
    [string]$ResourceGroup,
        [string]$Name,
        [bool]$UseGraceful
    )
    try {
        Write-Host "Checking VM state..." -ForegroundColor Green
        $VmState = Get-VMShutdownState -ResourceGroup $ResourceGroup -Name $Name
        Write-Host "VM Details:" -ForegroundColor Green
        Write-Output "Name: $($VmState.VM.Name)"
        Write-Output "Current State: $($VmState.PowerState)"
        Write-Output "Location: $($VmState.VM.Location)"
        if (-not $VmState.IsRunning) {
            Write-Host "VM is already stopped: $($VmState.PowerState)" -ForegroundColor Green
            return @{
                VMName = $Name
                Success = $true
                Message = "VM was already stopped"
                PowerState = $VmState.PowerState
            }
        }
        $ShutdownType = if ($UseGraceful) { "graceful shutdown (preserves allocation)" } else { "standard shutdown (deallocates resources)" }
        Write-Host "Performing $ShutdownType..." -ForegroundColor Green
        if ($PSCmdlet.ShouldProcess($Name, "Shutdown VM")) {
            if ($UseGraceful) {
                Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -StayProvisioned -Force
            } else {
                Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Force
            }
            Write-Host "Shutdown command initiated for $Name" -ForegroundColor Green
            return @{
                VMName = $Name
                Success = $true
                Message = "Shutdown initiated successfully"
                ShutdownType = if ($UseGraceful) { "Graceful" } else { "Standard" }
            }

} catch {
        return @{
            VMName = $Name
            Success = $false
            Message = $_.Exception.Message
        }
    }
}
function Wait-ForVMShutdown {
    [string]$ResourceGroup,
        [string]$Name,
        [int]$TimeoutMinutes
    )
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $LastState = ""
    Write-Host "Waiting for VM to shutdown (timeout: $TimeoutMinutes minutes)..." -ForegroundColor Green
    do {
        try {
            $VmState = Get-VMShutdownState -ResourceGroup $ResourceGroup -Name $Name
            $CurrentState = $VmState.PowerState
            if ($CurrentState -ne $LastState) {
                Write-Host "Current state: $CurrentState" -ForegroundColor Green
                $LastState = $CurrentState
            }
            if ($CurrentState -like "*stopped*" -or $CurrentState -like "*deallocated*") {
                Write-Host "VM shutdown completed: $CurrentState" -ForegroundColor Green
                return $true
            }
            Start-Sleep -Seconds 10
        }
        catch {
            Write-Warning "Error checking VM state: $_"
            Start-Sleep -Seconds 10
        }
    } while ((Get-Date) -lt $timeout)
    Write-Warning "Timeout reached. VM may still be shutting down."
    return $false
}
Write-Host "`nAzure VM Shutdown Tool" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
$VmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
if (-not $Force) {
    $ShutdownType = if ($Graceful) { "graceful shutdown (preserves allocation)" } else { "standard shutdown (deallocates resources)" }
    $VmCount = $VmList.Count
    $VmText = if ($VmCount -eq 1) { "VM" } else { "$VmCount VMs" }
    Write-Host "`nAbout to perform $ShutdownType on $VmText in resource group '$ResourceGroupName':" -ForegroundColor Green
    foreach ($vm in $VmList) {
        Write-Host "  - $vm" -ForegroundColor Green
    }
    if ($Graceful) {
        Write-Host "`nNote: Graceful shutdown preserves resource allocation (you continue to pay for compute)" -ForegroundColor Green
    } else {
        Write-Host "`nNote: Standard shutdown deallocates resources (stops billing for compute)" -ForegroundColor Green
    }
    $confirmation = Read-Host "`nContinue? (y/N)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Green
        exit 0
    }
}
Write-Host "`nStarting VM shutdown operations..." -ForegroundColor Green
$results = @()
foreach ($vm in $VmList) {
    try {
        Write-Host "`nProcessing VM: $vm" -ForegroundColor Green
        $result = Stop-AzureVM -ResourceGroup $ResourceGroupName -Name $vm -UseGraceful $Graceful
        $results += $result
        if ($result.Success -and $Wait) {
            $WaitResult = Wait-ForVMShutdown -ResourceGroup $ResourceGroupName -Name $vm -TimeoutMinutes $TimeoutMinutes
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
Write-Host "`nShutdown Operation Summary" -ForegroundColor Green
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



