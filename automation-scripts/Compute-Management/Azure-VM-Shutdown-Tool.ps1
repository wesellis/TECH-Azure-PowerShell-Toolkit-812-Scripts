#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Safely shuts down Azure Virtual Machines

.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Single')]
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory = $true)]
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
[OutputType([PSCustomObject])]
 {
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
function Get-VMShutdownState {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$Name
    )
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $powerState = ($vm.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
        return @{
            VM = $vm
            PowerState = $powerState
            IsRunning = $powerState -eq 'VM running'
        
} catch {
        throw "Failed to get VM state for $Name : $_"
    }
}
function Stop-AzureVM {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$Name,
        [bool]$UseGraceful
    )
    try {
        Write-Host "Checking VM state..." -ForegroundColor Yellow
        $vmState = Get-VMShutdownState -ResourceGroup $ResourceGroup -Name $Name
        Write-Host "VM Details:" -ForegroundColor Cyan
        Write-Host "Name: $($vmState.VM.Name)"
        Write-Host "Current State: $($vmState.PowerState)"
        Write-Host "Location: $($vmState.VM.Location)"
        if (-not $vmState.IsRunning) {
            Write-Host "VM is already stopped: $($vmState.PowerState)" -ForegroundColor Yellow
            return @{
                VMName = $Name
                Success = $true
                Message = "VM was already stopped"
                PowerState = $vmState.PowerState
            }
        }
        $shutdownType = if ($UseGraceful) { "graceful shutdown (preserves allocation)" } else { "standard shutdown (deallocates resources)" }
        Write-Host "Performing $shutdownType..." -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($Name, "Shutdown VM")) {
            if ($UseGraceful) {
                # Graceful shutdown - preserves allocation
                Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -StayProvisioned -Force
            } else {
                # Standard shutdown - deallocates resources
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
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$Name,
        [int]$TimeoutMinutes
    )
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $lastState = ""
    Write-Host "Waiting for VM to shutdown (timeout: $TimeoutMinutes minutes)..." -ForegroundColor Yellow
    do {
        try {
            $vmState = Get-VMShutdownState -ResourceGroup $ResourceGroup -Name $Name
            $currentState = $vmState.PowerState
            if ($currentState -ne $lastState) {
                Write-Host "Current state: $currentState" -ForegroundColor Cyan
                $lastState = $currentState
            }
            if ($currentState -like "*stopped*" -or $currentState -like "*deallocated*") {
                Write-Host "VM shutdown completed: $currentState" -ForegroundColor Green
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
# Main execution
Write-Host "`nAzure VM Shutdown Tool" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
# Test Azure connection
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
# Prepare VM list
$vmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
# Confirmation
if (-not $Force) {
    $shutdownType = if ($Graceful) { "graceful shutdown (preserves allocation)" } else { "standard shutdown (deallocates resources)" }
    $vmCount = $vmList.Count
    $vmText = if ($vmCount -eq 1) { "VM" } else { "$vmCount VMs" }
    Write-Host "`nAbout to perform $shutdownType on $vmText in resource group '$ResourceGroupName':" -ForegroundColor Yellow
    foreach ($vm in $vmList) {
        Write-Host "  - $vm" -ForegroundColor White
    }
    if ($Graceful) {
        Write-Host "`nNote: Graceful shutdown preserves resource allocation (you continue to pay for compute)" -ForegroundColor Yellow
    } else {
        Write-Host "`nNote: Standard shutdown deallocates resources (stops billing for compute)" -ForegroundColor Cyan
    }
    $confirmation = Read-Host "`nContinue? (y/N)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}
# Process VMs
Write-Host "`nStarting VM shutdown operations..." -ForegroundColor Yellow
$results = @()
foreach ($vm in $vmList) {
    try {
        Write-Host "`nProcessing VM: $vm" -ForegroundColor Cyan
        $result = Stop-AzureVM -ResourceGroup $ResourceGroupName -Name $vm -UseGraceful $Graceful
        $results += $result
        # Wait for completion if requested
        if ($result.Success -and $Wait) {
            $waitResult = Wait-ForVMShutdown -ResourceGroup $ResourceGroupName -Name $vm -TimeoutMinutes $TimeoutMinutes
            $result.WaitCompleted = $waitResult
        
} catch {
        $errorResult = @{
            VMName = $vm
            Success = $false
            Message = $_.Exception.Message
        }
        $results += $errorResult
    }
}
# Generate summary
Write-Host "`nShutdown Operation Summary" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
$successful = ($results | Where-Object { $_.Success }).Count
$failed = ($results | Where-Object { -not $_.Success }).Count
Write-Host "Total VMs: $($results.Count)"
Write-Host "Successful: $successful" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })
if ($failed -gt 0) {
    Write-Host "`nFailed VMs:" -ForegroundColor Red
    $results | Where-Object { -not $_.Success } | ForEach-Object {
        Write-Host "  - $($_.VMName): $($_.Message)" -ForegroundColor Red
    }
}
Write-Host "`nOperation completed!" -ForegroundColor Green
# Exit with appropriate code
$exitCode = if ($failed -gt 0) { 1 } else { 0 }
exit $exitCode\n

