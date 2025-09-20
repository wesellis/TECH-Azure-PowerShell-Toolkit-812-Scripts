#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Starts Azure Virtual Machines

.DESCRIPTION
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
#>
[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Single')]
[CmdletBinding()]

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
    [switch]$Wait,
    [Parameter()]
    [ValidateRange(1, 60)]
    [int]$TimeoutMinutes = 10,
    [Parameter()]
    [switch]$Force
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
function Get-VMStartupState {
    [CmdletBinding()]

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
            IsStopped = $powerState -like '*stopped*' -or $powerState -like '*deallocated*'
        
} catch {
        throw "Failed to get VM state for $Name : $_"
    }
}
function Start-AzureVM {
    [CmdletBinding()]

        [string]$ResourceGroup,
        [string]$Name
    )
    try {
        Write-Host "Checking VM state..." -ForegroundColor Yellow
        $vmState = Get-VMStartupState -ResourceGroup $ResourceGroup -Name $Name
        Write-Host "VM Details:" -ForegroundColor Cyan
        Write-Host "Name: $($vmState.VM.Name)"
        Write-Host "Current State: $($vmState.PowerState)"
        Write-Host "Location: $($vmState.VM.Location)"
        Write-Host "Size: $($vmState.VM.HardwareProfile.VmSize)"
        if ($vmState.IsRunning) {
            Write-Host "VM is already running: $($vmState.PowerState)" -ForegroundColor Green
            return @{
                VMName = $Name
                Success = $true
                Message = "VM was already running"
                PowerState = $vmState.PowerState
            }
        }
        if (-not $vmState.IsStopped) {
            Write-Warning "VM is in transitional state: $($vmState.PowerState)"
        }
        Write-Host "Starting VM..." -ForegroundColor Yellow
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
    [CmdletBinding()]

        [string]$ResourceGroup,
        [string]$Name,
        [int]$TimeoutMinutes
    )
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $lastState = ""
    Write-Host "Waiting for VM to start (timeout: $TimeoutMinutes minutes)..." -ForegroundColor Yellow
    do {
        try {
            $vmState = Get-VMStartupState -ResourceGroup $ResourceGroup -Name $Name
            $currentState = $vmState.PowerState
            if ($currentState -ne $lastState) {
                Write-Host "Current state: $currentState" -ForegroundColor Cyan
                $lastState = $currentState
            }
            if ($vmState.IsRunning) {
                Write-Host "VM startup completed: $currentState" -ForegroundColor Green
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
# Main execution
Write-Host "`nAzure VM Startup Tool" -ForegroundColor Cyan
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
    $vmCount = $vmList.Count
    $vmText = if ($vmCount -eq 1) { "VM" } else { "$vmCount VMs" }
    Write-Host "`nAbout to start $vmText in resource group '$ResourceGroupName':" -ForegroundColor Yellow
    foreach ($vm in $vmList) {
        Write-Host "  - $vm" -ForegroundColor White
    }
    $confirmation = Read-Host "`nContinue? (y/N)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}
# Process VMs
Write-Host "`nStarting VM startup operations..." -ForegroundColor Yellow
$results = @()
foreach ($vm in $vmList) {
    try {
        Write-Host "`nProcessing VM: $vm" -ForegroundColor Cyan
        $result = Start-AzureVM -ResourceGroup $ResourceGroupName -Name $vm
        $results += $result
        # Wait for completion if requested
        if ($result.Success -and $Wait) {
            $waitResult = Wait-ForVMStartup -ResourceGroup $ResourceGroupName -Name $vm -TimeoutMinutes $TimeoutMinutes
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
Write-Host "`nStartup Operation Summary" -ForegroundColor Cyan
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

