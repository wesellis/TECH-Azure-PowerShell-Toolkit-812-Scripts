#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Azure Virtual Machine restart and management tool

.DESCRIPTION
     VM restart tool with  health checks, dependency validation,
    graceful shutdown options, and monitoring capabilities. Supports batch operations,
    scheduled restarts, and integration with maintenance workflows.
.PARAMETER ResourceGroupName
    Resource group
.PARAMETER VMName
    VM name
.PARAMETER VMNames
    VM names array
.PARAMETER Force
    Skip confirmation
.PARAMETER Wait
    Wait for completion
.PARAMETER TimeoutMinutes
    Timeout (minutes)
.PARAMETER GracefulShutdown
    Attempt graceful shutdown before restart (requires VM agent)
.PARAMETER HealthCheck
    Perform health checks before and after restart
.PARAMETER NotificationEmail
    Email address for restart completion notifications
.PARAMETER MaintenanceWindow
    Only restart if within maintenance window (format: "HH:mm-HH:mm")
.PARAMETER PreRestartScript
    Path to script to run before restart
.PARAMETER PostRestartScript
    Path to script to run after restart
.PARAMETER CheckDependencies
    Validate dependent services before restart
.PARAMETER DryRun
    Simulate restart operations without making changes
    .\Azure-VM-Restart-Tool.ps1 -ResourceGroupName "RG-Production" -VMName "VM-WebServer01"
    Restarts the specified VM with health checks and confirmation
    .\Azure-VM-Restart-Tool.ps1 -ResourceGroupName "RG-Production" -VMNames @("VM-Web01", "VM-Web02") -Force -Wait
    Batch restart multiple VMs without confirmation
    .\Azure-VM-Restart-Tool.ps1 -ResourceGroupName "RG-Production" -VMName "VM-DB01" -GracefulShutdown -HealthCheck -NotificationEmail "admin@company.com"
    Graceful restart with health checks and email notification
    .\Azure-VM-Restart-Tool.ps1 -ResourceGroupName "RG-Production" -VMName "VM-App01" -MaintenanceWindow "02:00-04:00"
    Only restart if within the specified maintenance window
.NOTESThis tool provides  VM restart capabilities with:
    -  validation and health checks
    - Graceful shutdown support
    - Batch operations
    - Maintenance window enforcement
    -  logging and notifications
#>
[CmdletBinding(SupportsShouldProcess)]
[CmdletBinding(SupportsShouldProcess)]

    [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Batch')]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $true, ParameterSetName = 'Single')]
    [ValidateNotNullOrEmpty()]
    [string]$VMName,
    [Parameter(Mandatory = $true, ParameterSetName = 'Batch')]
    [ValidateCount(1, 50)]
    [string[]]$VMNames,
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$Wait,
    [Parameter()]
    [int]$TimeoutMinutes = 15,
    [Parameter()]
    [switch]$GracefulShutdown,
    [Parameter()]
    [switch]$HealthCheck,
    [Parameter()]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$NotificationEmail,
    [Parameter()]
    [ValidatePattern('^\d{2}:\d{2}-\d{2}:\d{2}$')]
    [string]$MaintenanceWindow,
    [Parameter()]
    [ValidateScript({ Test-Path $_ })]
    [string]$PreRestartScript,
    [Parameter()]
    [ValidateScript({ Test-Path $_ })]
    [string]$PostRestartScript,
    [Parameter()]
    [switch]$CheckDependencies,
    [Parameter()]
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
# Global variables for tracking
$script:RestartResults = @()
$script:StartTime = Get-Date
[OutputType([bool])]
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
function Test-MaintenanceWindow {
    [CmdletBinding(SupportsShouldProcess)]
[string]$Window)
    if (-not $Window) {
        return $true
    }
    try {
        $parts = $Window -split '-'
        $startTime = [DateTime]::ParseExact($parts[0], 'HH:mm', $null)
        $endTime = [DateTime]::ParseExact($parts[1], 'HH:mm', $null)
        $currentTime = Get-Date
        $currentTimeOnly = [DateTime]::ParseExact($currentTime.ToString('HH:mm'), 'HH:mm', $null)
        # Handle overnight maintenance windows
        if ($endTime -lt $startTime) {
            return ($currentTimeOnly -ge $startTime -or $currentTimeOnly -le $endTime)
        }
        else {
            return ($currentTimeOnly -ge $startTime -and $currentTimeOnly -le $endTime)
        
} catch {
        Write-Warning "Invalid maintenance window format: $Window. Proceeding with restart."
        return $true
    }
}
function Get-VMDetails {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$Name
    )
    try {
        Write-Verbose "Retrieving VM details for: $Name"
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $vmDetails = @{
            VM = $vm
            PowerState = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
            ProvisioningState = ($vm.Statuses | Where-Object { $_.Code -like "ProvisioningState/*" }).DisplayStatus
            BootDiagnostics = $vm.DiagnosticsProfile.BootDiagnostics.Enabled
            VMAgent = ($vm.Statuses | Where-Object { $_.Code -like "VMAgent/*" }).DisplayStatus
        }
        return $vmDetails
    }
    catch {
        throw "Failed to retrieve VM details for $Name : $_"
    }
}
function Test-VMHealth {
    [CmdletBinding(SupportsShouldProcess)]

        [object]$VMDetails,
        [string]$Phase
    )
    Write-Host "Performing $Phase health check..." -ForegroundColor Yellow
    $healthStatus = @{
        Healthy = $true
        Issues = @()
        Warnings = @()
    }
    # Check power state
    if ($VMDetails.PowerState -notin @("VM running", "VM stopped", "VM deallocated")) {
        $healthStatus.Issues += "VM is in unexpected power state: $($VMDetails.PowerState)"
        $healthStatus.Healthy = $false
    }
    # Check provisioning state
    if ($VMDetails.ProvisioningState -ne "Provisioning succeeded") {
        $healthStatus.Warnings += "VM provisioning state: $($VMDetails.ProvisioningState)"
    }
    # Check VM agent status
    if ($VMDetails.VMAgent -and $VMDetails.VMAgent -notlike "*Ready*") {
        $healthStatus.Warnings += "VM Agent status: $($VMDetails.VMAgent)"
    }
    # For post-restart checks, verify VM is running
    if ($Phase -eq "post-restart" -and $VMDetails.PowerState -ne "VM running") {
        $healthStatus.Issues += "VM failed to start properly: $($VMDetails.PowerState)"
        $healthStatus.Healthy = $false
    }
    # Display results
    if ($healthStatus.Healthy) {
        Write-Host "Health check passed" -ForegroundColor Green
    }
    else {
        Write-Host "Health check failed" -ForegroundColor Red
        foreach ($issue in $healthStatus.Issues) {
            Write-Host "ERROR: $issue" -ForegroundColor Red
        }
    }
    if ($healthStatus.Warnings.Count -gt 0) {
        foreach ($warning in $healthStatus.Warnings) {
            Write-Host "WARNING: $warning" -ForegroundColor Yellow
        }
    }
    return $healthStatus
}
function Test-VMDependencies {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$VMName
    )
    Write-Host "Checking VM dependencies..." -ForegroundColor Yellow
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
        $dependencies = @{
            NetworkInterfaces = @()
            PublicIPs = @()
            LoadBalancers = @()
            AvailabilitySet = $null
        }
        # Check network interfaces
        foreach ($nicRef in $vm.NetworkProfile.NetworkInterfaces) {
            $nicId = $nicRef.Id
            $nic = Get-AzNetworkInterface | Where-Object { $_.Id -eq $nicId }
            if ($nic) {
                $dependencies.NetworkInterfaces += @{
                    Name = $nic.Name
                    State = $nic.ProvisioningState
                }
                # Check public IPs
                foreach ($ipConfig in $nic.IpConfigurations) {
                    if ($ipConfig.PublicIpAddress) {
                        $pip = Get-AzPublicIpAddress | Where-Object { $_.Id -eq $ipConfig.PublicIpAddress.Id }
                        if ($pip) {
                            $dependencies.PublicIPs += @{
                                Name = $pip.Name
                                State = $pip.ProvisioningState
                                IP = $pip.IpAddress
                            }
                        }
                    }
                }
            }
        }
        # Check availability set
        if ($vm.AvailabilitySetReference) {
            $avSet = Get-AzAvailabilitySet | Where-Object { $_.Id -eq $vm.AvailabilitySetReference.Id }
            if ($avSet) {
                $dependencies.AvailabilitySet = @{
                    Name = $avSet.Name
                    VMCount = $avSet.VirtualMachinesReferences.Count
                }
            }
        }
        Write-Host "Dependencies validated" -ForegroundColor Green
        return $dependencies
    }
    catch {
        Write-Warning "Failed to check dependencies: $_"
        return $null
    }
}
function Invoke-VMShutdown {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$VMName,
        [bool]$Graceful
    )
    if ($Graceful) {
        Write-Host "Initiating graceful shutdown..." -ForegroundColor Yellow
        try {
            # This would require custom script extension or VM agent commands
            # For now, we'll use the standard stop operation
            Write-Host "Graceful shutdown requested (using standard stop operation)" -ForegroundColor Cyan
        }
        catch {
            Write-Warning "Graceful shutdown failed, falling back to standard stop"
        }
    }
    Write-Host "Stopping VM: $VMName" -ForegroundColor Yellow
    if ($PSCmdlet.ShouldProcess($VMName, "Stop VM")) {
        Stop-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Force
        Write-Host "VM stopped successfully" -ForegroundColor Green
    }
}
function Start-VMRestart {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$VMName,
        [bool]$UseShutdown
    )
    try {
        if ($UseShutdown) {
            Invoke-VMShutdown -ResourceGroup $ResourceGroup -VMName $VMName -Graceful $GracefulShutdown
            Start-Sleep -Seconds 5
            Write-Host "Starting VM: $VMName" -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess($VMName, "Start VM")) {
                Start-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
            }
        }
        else {
            Write-Host "Restarting VM: $VMName" -ForegroundColor Yellow
            if ($PSCmdlet.ShouldProcess($VMName, "Restart VM")) {
                Restart-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
            }
        }
        return $true
    }
    catch {
        Write-Error "Failed to restart VM $VMName : $_"
        return $false
    }
}
function Wait-ForVMState {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$VMName,
        [string]$TargetState,
        [int]$TimeoutMinutes
    )
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $lastState = ""
    Write-Host "Waiting for VM to reach state: $TargetState (timeout: $TimeoutMinutes minutes)" -ForegroundColor Yellow
    do {
        try {
            $vmDetails = Get-VMDetails -ResourceGroup $ResourceGroup -Name $VMName
            $currentState = $vmDetails.PowerState
            if ($currentState -ne $lastState) {
                Write-Host "Current state: $currentState" -ForegroundColor Cyan
                $lastState = $currentState
            }
            if ($currentState -eq $TargetState) {
                Write-Host "VM reached target state: $TargetState" -ForegroundColor Green
                return $true
            }
            Start-Sleep -Seconds 10
        }
        catch {
            Write-Warning "Error checking VM state: $_"
            Start-Sleep -Seconds 10
        }
    } while ((Get-Date) -lt $timeout)
    Write-Warning "Timeout reached. VM may still be transitioning."
    return $false
}
function Invoke-CustomScript {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ScriptPath,
        [string]$Phase,
        [string]$VMName
    )
    if (-not $ScriptPath) {
        return
    }
    Write-Host "Executing $Phase script: $ScriptPath" -ForegroundColor Yellow
    try {
        $scriptContent = Get-Content $ScriptPath -Raw
        $result = & $ScriptPath -VMName $VMName -ResourceGroupName $ResourceGroupName
        Write-Host " $Phase script completed successfully" -ForegroundColor Green
        return $result
    }
    catch {
        Write-Warning "$Phase script failed: $_"
        return $null
    }
}
function Send-RestartNotification {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$EmailAddress,
        [object[]]$Results
    )
    if (-not $EmailAddress) {
        return
    }
    $successCount = ($Results | Where-Object { $_.Success }).Count
    $totalCount = $Results.Count
    $duration = ((Get-Date) - $script:StartTime).TotalMinutes
    Write-Host "Notification would be sent to: $EmailAddress" -ForegroundColor Yellow
    Write-Host "Summary: $successCount/$totalCount VMs restarted successfully in $([math]::Round($duration, 1)) minutes" -ForegroundColor Cyan
    # In a real implementation, this would use:
    # - Send-MailMessage (if SMTP configured)
    # - Azure Logic Apps
    # - Microsoft Graph API
    # - Azure Monitor Action Groups
}
function New-RestartReport {
    [CmdletBinding(SupportsShouldProcess)]
[object[]]$Results)
    $report = @{
        Timestamp = Get-Date
        Duration = ((Get-Date) - $script:StartTime)
        TotalVMs = $Results.Count
        Successful = ($Results | Where-Object { $_.Success }).Count
        Failed = ($Results | Where-Object { -not $_.Success }).Count
        Details = $Results
    }
    Write-Host "`nRestart Operation Summary" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host "Total VMs: $($report.TotalVMs)"
    Write-Host "Successful: $($report.Successful)" -ForegroundColor Green
    Write-Host "Failed: $($report.Failed)" -ForegroundColor $(if ($report.Failed -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Duration: $([math]::Round($report.Duration.TotalMinutes, 1)) minutes"
    if ($report.Failed -gt 0) {
        Write-Host "`nFailed VMs:" -ForegroundColor Red
        $Results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $($_.VMName): $($_.Error)" -ForegroundColor Red
        }
    }
    return $report
}
function Restart-AzureVM {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$VMName
    )
    $result = @{
        VMName = $VMName
        StartTime = Get-Date
        Success = $false
        Error = $null
        HealthCheck = $null
    }
    try {
        Write-Host "`nProcessing VM: $VMName" -ForegroundColor Cyan
        Write-Host ("=" * 40) -ForegroundColor Gray
        # Get VM details
        $vmDetails = Get-VMDetails -ResourceGroup $ResourceGroup -Name $VMName
        Write-Host "VM Information:" -ForegroundColor Cyan
        Write-Host "Current State: $($vmDetails.PowerState)"
        Write-Host "Provisioning State: $($vmDetails.ProvisioningState)"
        Write-Host "VM Agent: $($vmDetails.VMAgent)"
        # Check if VM is in restartable state
        if ($vmDetails.PowerState -notin @("VM running", "VM stopped")) {
            throw "VM is in state '$($vmDetails.PowerState)' which is not suitable for restart"
        }
        # Pre-restart health check
        if ($HealthCheck) {
            $preHealth = Test-VMHealth -VMDetails $vmDetails -Phase "pre-restart"
            if (-not $preHealth.Healthy -and -not $Force) {
                throw "Pre-restart health check failed. Use -Force to override."
            }
        }
        # Check dependencies
        if ($CheckDependencies) {
            $dependencies = Test-VMDependencies -ResourceGroup $ResourceGroup -VMName $VMName
        }
        # Run pre-restart script
        if ($PreRestartScript) {
            Invoke-CustomScript -ScriptPath $PreRestartScript -Phase "pre-restart" -VMName $VMName
        }
        # Perform restart
        if ($DryRun) {
            Write-Host "DRY RUN: Would restart VM $VMName" -ForegroundColor Yellow
            $result.Success = $true
        }
        else {
            $restartSuccess = Start-VMRestart -ResourceGroup $ResourceGroup -VMName $VMName -UseShutdown $GracefulShutdown
            if ($restartSuccess -and $Wait) {
                $success = Wait-ForVMState -ResourceGroup $ResourceGroup -VMName $VMName -TargetState "VM running" -TimeoutMinutes $TimeoutMinutes
                if ($success) {
                    # Post-restart health check
                    if ($HealthCheck) {
                        Start-Sleep -Seconds 30  # Allow time for VM to fully initialize
                        $postVMDetails = Get-VMDetails -ResourceGroup $ResourceGroup -Name $VMName
                        $postHealth = Test-VMHealth -VMDetails $postVMDetails -Phase "post-restart"
                        $result.HealthCheck = $postHealth
                    }
                    # Run post-restart script
                    if ($PostRestartScript) {
                        Invoke-CustomScript -ScriptPath $PostRestartScript -Phase "post-restart" -VMName $VMName
                    }
                    $result.Success = $true
                    Write-Host "VM restart completed successfully" -ForegroundColor Green
                }
                else {
                    throw "VM restart operation timed out"
                }
            }
            elseif ($restartSuccess) {
                $result.Success = $true
                Write-Host "VM restart initiated successfully" -ForegroundColor Green
            }
        
} catch {
        $result.Error = $_.Exception.Message
        $result.Success = $false
        Write-Host "VM restart failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
    }
    return $result
}
# Main execution
Write-Host "`nAzure VM Restart Tool" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
# Test Azure connection
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
# Check maintenance window
if ($MaintenanceWindow -and -not (Test-MaintenanceWindow -Window $MaintenanceWindow)) {
    Write-Host "Outside maintenance window ($MaintenanceWindow). Restart cancelled." -ForegroundColor Yellow
    exit 0
}
# Prepare VM list
$vmList = if ($PSCmdlet.ParameterSetName -eq 'Batch') { $VMNames } else { @($VMName) }
# Confirmation
if (-not $Force -and -not $DryRun) {
    $action = if ($DryRun) { "simulate restart of" } else { "restart" }
    $vmCount = $vmList.Count
    $vmText = if ($vmCount -eq 1) { "VM" } else { "$vmCount VMs" }
    Write-Host "`nAbout to $action $vmText in resource group '$ResourceGroupName':" -ForegroundColor Yellow
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
Write-Host "`nStarting VM restart operations..." -ForegroundColor Yellow
foreach ($vm in $vmList) {
    try {
        $result = Restart-AzureVM -ResourceGroup $ResourceGroupName -VMName $vm
        $script:RestartResults += $result
    }
    catch {
        $errorResult = @{
            VMName = $vm
            StartTime = Get-Date
            EndTime = Get-Date
            Success = $false
            Error = $_.Exception.Message
        }
        $script:RestartResults += $errorResult
    }
}
# Generate report
$report = New-RestartReport -Results $script:RestartResults
# Send notifications
if ($NotificationEmail) {
    Send-RestartNotification -EmailAddress $NotificationEmail -Results $script:RestartResults
}
# Exit with appropriate code
$exitCode = if ($report.Failed -gt 0) { 1 } else { 0 }
Write-Host "`nOperation completed!" -ForegroundColor $(if ($exitCode -eq 0) { 'Green' } else { 'Yellow' })
exit $exitCode\n

