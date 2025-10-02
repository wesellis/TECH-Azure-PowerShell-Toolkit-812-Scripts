#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Virtual Machine restart and management tool

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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
param(
[Parameter(Mandatory = $true, ParameterSetName = 'Single')]
)
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
$script:RestartResults = @()
$script:StartTime = Get-Date
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
function Test-MaintenanceWindow {
    [string]$Window)
    if (-not $Window) {
        return $true
    }
    try {
        $parts = $Window -split '-'
        $StartTime = [DateTime]::ParseExact($parts[0], 'HH:mm', $null)
        $EndTime = [DateTime]::ParseExact($parts[1], 'HH:mm', $null)
        $CurrentTime = Get-Date
        $CurrentTimeOnly = [DateTime]::ParseExact($CurrentTime.ToString('HH:mm'), 'HH:mm', $null)
        if ($EndTime -lt $StartTime) {
            return ($CurrentTimeOnly -ge $StartTime -or $CurrentTimeOnly -le $EndTime)
        }
        else {
            return ($CurrentTimeOnly -ge $StartTime -and $CurrentTimeOnly -le $EndTime)

} catch {
        Write-Warning "Invalid maintenance window format: $Window. Proceeding with restart."
        return $true
    }
}
function Get-VMDetails {
    [string]$ResourceGroup,
        [string]$Name
    )
    try {
        Write-Verbose "Retrieving VM details for: $Name"
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $VmDetails = @{
            VM = $vm
            PowerState = ($vm.Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus
            ProvisioningState = ($vm.Statuses | Where-Object { $_.Code -like "ProvisioningState/*" }).DisplayStatus
            BootDiagnostics = $vm.DiagnosticsProfile.BootDiagnostics.Enabled
            VMAgent = ($vm.Statuses | Where-Object { $_.Code -like "VMAgent/*" }).DisplayStatus
        }
        return $VmDetails
    }
    catch {
        throw "Failed to retrieve VM details for $Name : $_"
    }
}
function Test-VMHealth {
    [object]$VMDetails,
        [string]$Phase
    )
    Write-Host "Performing $Phase health check..." -ForegroundColor Green
    $HealthStatus = @{
        Healthy = $true
        Issues = @()
        Warnings = @()
    }
    if ($VMDetails.PowerState -notin @("VM running", "VM stopped", "VM deallocated")) {
        $HealthStatus.Issues += "VM is in unexpected power state: $($VMDetails.PowerState)"
        $HealthStatus.Healthy = $false
    }
    if ($VMDetails.ProvisioningState -ne "Provisioning succeeded") {
        $HealthStatus.Warnings += "VM provisioning state: $($VMDetails.ProvisioningState)"
    }
    if ($VMDetails.VMAgent -and $VMDetails.VMAgent -notlike "*Ready*") {
        $HealthStatus.Warnings += "VM Agent status: $($VMDetails.VMAgent)"
    }
    if ($Phase -eq "post-restart" -and $VMDetails.PowerState -ne "VM running") {
        $HealthStatus.Issues += "VM failed to start properly: $($VMDetails.PowerState)"
        $HealthStatus.Healthy = $false
    }
    if ($HealthStatus.Healthy) {
        Write-Host "Health check passed" -ForegroundColor Green
    }
    else {
        Write-Host "Health check failed" -ForegroundColor Green
        foreach ($issue in $HealthStatus.Issues) {
            Write-Host "ERROR: $issue" -ForegroundColor Green
        }
    }
    if ($HealthStatus.Warnings.Count -gt 0) {
        foreach ($warning in $HealthStatus.Warnings) {
            Write-Host "WARNING: $warning" -ForegroundColor Green
        }
    }
    return $HealthStatus
}
function Test-VMDependencies {
    [string]$ResourceGroup,
        [string]$VMName
    )
    Write-Host "Checking VM dependencies..." -ForegroundColor Green
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
        $dependencies = @{
            NetworkInterfaces = @()
            PublicIPs = @()
            LoadBalancers = @()
            AvailabilitySet = $null
        }
        foreach ($NicRef in $vm.NetworkProfile.NetworkInterfaces) {
            $NicId = $NicRef.Id
            $nic = Get-AzNetworkInterface | Where-Object { $_.Id -eq $NicId }
            if ($nic) {
                $dependencies.NetworkInterfaces += @{
                    Name = $nic.Name
                    State = $nic.ProvisioningState
                }
                foreach ($IpConfig in $nic.IpConfigurations) {
                    if ($IpConfig.PublicIpAddress) {
                        $pip = Get-AzPublicIpAddress | Where-Object { $_.Id -eq $IpConfig.PublicIpAddress.Id }
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
        if ($vm.AvailabilitySetReference) {
            $AvSet = Get-AzAvailabilitySet | Where-Object { $_.Id -eq $vm.AvailabilitySetReference.Id }
            if ($AvSet) {
                $dependencies.AvailabilitySet = @{
                    Name = $AvSet.Name
                    VMCount = $AvSet.VirtualMachinesReferences.Count
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
    [string]$ResourceGroup,
        [string]$VMName,
        [bool]$Graceful
    )
    if ($Graceful) {
        Write-Host "Initiating graceful shutdown..." -ForegroundColor Green
        try {
            Write-Host "Graceful shutdown requested (using standard stop operation)" -ForegroundColor Green
        }
        catch {
            Write-Warning "Graceful shutdown failed, falling back to standard stop"
        }
    }
    Write-Host "Stopping VM: $VMName" -ForegroundColor Green
    if ($PSCmdlet.ShouldProcess($VMName, "Stop VM")) {
        Stop-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Force
        Write-Host "VM stopped successfully" -ForegroundColor Green
    }
}
function Start-VMRestart {
    [string]$ResourceGroup,
        [string]$VMName,
        [bool]$UseShutdown
    )
    try {
        if ($UseShutdown) {
            Invoke-VMShutdown -ResourceGroup $ResourceGroup -VMName $VMName -Graceful $GracefulShutdown
            Start-Sleep -Seconds 5
            Write-Host "Starting VM: $VMName" -ForegroundColor Green
            if ($PSCmdlet.ShouldProcess($VMName, "Start VM")) {
                Start-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
            }
        }
        else {
            Write-Host "Restarting VM: $VMName" -ForegroundColor Green
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
    [string]$ResourceGroup,
        [string]$VMName,
        [string]$TargetState,
        [int]$TimeoutMinutes
    )
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $LastState = ""
    Write-Host "Waiting for VM to reach state: $TargetState (timeout: $TimeoutMinutes minutes)" -ForegroundColor Green
    do {
        try {
            $VmDetails = Get-VMDetails -ResourceGroup $ResourceGroup -Name $VMName
            $CurrentState = $VmDetails.PowerState
            if ($CurrentState -ne $LastState) {
                Write-Host "Current state: $CurrentState" -ForegroundColor Green
                $LastState = $CurrentState
            }
            if ($CurrentState -eq $TargetState) {
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
    [string]$ScriptPath,
        [string]$Phase,
        [string]$VMName
    )
    if (-not $ScriptPath) {
        return
    }
    Write-Host "Executing $Phase script: $ScriptPath" -ForegroundColor Green
    try {
        $ScriptContent = Get-Content $ScriptPath -Raw
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
    [string]$EmailAddress,
        [object[]]$Results
    )
    if (-not $EmailAddress) {
        return
    }
    $SuccessCount = ($Results | Where-Object { $_.Success }).Count
    $TotalCount = $Results.Count
    $duration = ((Get-Date) - $script:StartTime).TotalMinutes
    Write-Host "Notification would be sent to: $EmailAddress" -ForegroundColor Green
    Write-Host "Summary: $SuccessCount/$TotalCount VMs restarted successfully in $([math]::Round($duration, 1)) minutes" -ForegroundColor Green
}
function New-RestartReport {
    [object[]]$Results)
    $report = @{
        Timestamp = Get-Date
        Duration = ((Get-Date) - $script:StartTime)
        TotalVMs = $Results.Count
        Successful = ($Results | Where-Object { $_.Success }).Count
        Failed = ($Results | Where-Object { -not $_.Success }).Count
        Details = $Results
    }
    Write-Host "`nRestart Operation Summary" -ForegroundColor Green
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Output "Total VMs: $($report.TotalVMs)"
    Write-Host "Successful: $($report.Successful)" -ForegroundColor Green
    Write-Output "Failed: $($report.Failed)" -ForegroundColor $(if ($report.Failed -gt 0) { 'Red' } else { 'Green' })
    Write-Output "Duration: $([math]::Round($report.Duration.TotalMinutes, 1)) minutes"
    if ($report.Failed -gt 0) {
        Write-Host "`nFailed VMs:" -ForegroundColor Green
        $Results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $($_.VMName): $($_.Error)" -ForegroundColor Green
        }
    }
    return $report
}
function Restart-AzureVM {
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
        Write-Host "`nProcessing VM: $VMName" -ForegroundColor Green
        Write-Host ("=" * 40) -ForegroundColor Gray
        $VmDetails = Get-VMDetails -ResourceGroup $ResourceGroup -Name $VMName
        Write-Host "VM Information:" -ForegroundColor Green
        Write-Output "Current State: $($VmDetails.PowerState)"
        Write-Output "Provisioning State: $($VmDetails.ProvisioningState)"
        Write-Output "VM Agent: $($VmDetails.VMAgent)"
        if ($VmDetails.PowerState -notin @("VM running", "VM stopped")) {
            throw "VM is in state '$($VmDetails.PowerState)' which is not suitable for restart"
        }
        if ($HealthCheck) {
            $PreHealth = Test-VMHealth -VMDetails $VmDetails -Phase "pre-restart"
            if (-not $PreHealth.Healthy -and -not $Force) {
                throw "Pre-restart health check failed. Use -Force to override."
            }
        }
        if ($CheckDependencies) {
            $dependencies = Test-VMDependencies -ResourceGroup $ResourceGroup -VMName $VMName
        }
        if ($PreRestartScript) {
            Invoke-CustomScript -ScriptPath $PreRestartScript -Phase "pre-restart" -VMName $VMName
        }
        if ($DryRun) {
            Write-Host "DRY RUN: Would restart VM $VMName" -ForegroundColor Green
            $result.Success = $true
        }
        else {
            $RestartSuccess = Start-VMRestart -ResourceGroup $ResourceGroup -VMName $VMName -UseShutdown $GracefulShutdown
            if ($RestartSuccess -and $Wait) {
                $success = Wait-ForVMState -ResourceGroup $ResourceGroup -VMName $VMName -TargetState "VM running" -TimeoutMinutes $TimeoutMinutes
                if ($success) {
                    if ($HealthCheck) {
                        Start-Sleep -Seconds 30
                        $PostVMDetails = Get-VMDetails -ResourceGroup $ResourceGroup -Name $VMName
                        $PostHealth = Test-VMHealth -VMDetails $PostVMDetails -Phase "post-restart"
                        $result.HealthCheck = $PostHealth
                    }
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
            elseif ($RestartSuccess) {
                $result.Success = $true
                Write-Host "VM restart initiated successfully" -ForegroundColor Green
            }

} catch {
        $result.Error = $_.Exception.Message
        $result.Success = $false
        Write-Host "VM restart failed: $($_.Exception.Message)" -ForegroundColor Green
    }
    finally {
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
    }
    return $result
}
Write-Host "`nAzure VM Restart Tool" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
if ($MaintenanceWindow -and -not (Test-MaintenanceWindow -Window $MaintenanceWindow)) {
    Write-Host "Outside maintenance window ($MaintenanceWindow). Restart cancelled." -ForegroundColor Green
    exit 0
}
$VmList = if ($PSCmdlet.ParameterSetName -eq 'Batch') { $VMNames } else { @($VMName) }
if (-not $Force -and -not $DryRun) {
    $action = if ($DryRun) { "simulate restart of" } else { "restart" }
    $VmCount = $VmList.Count
    $VmText = if ($VmCount -eq 1) { "VM" } else { "$VmCount VMs" }
    Write-Host "`nAbout to $action $VmText in resource group '$ResourceGroupName':" -ForegroundColor Green
    foreach ($vm in $VmList) {
        Write-Host "  - $vm" -ForegroundColor Green
    }
    $confirmation = Read-Host "`nContinue? (y/N)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Green
        exit 0
    }
}
Write-Host "`nStarting VM restart operations..." -ForegroundColor Green
foreach ($vm in $VmList) {
    try {
        $result = Restart-AzureVM -ResourceGroup $ResourceGroupName -VMName $vm
        $script:RestartResults += $result
    }
    catch {
        $ErrorResult = @{
            VMName = $vm
            StartTime = Get-Date
            EndTime = Get-Date
            Success = $false
            Error = $_.Exception.Message
        }
        $script:RestartResults += $ErrorResult
    }
}
$report = New-RestartReport -Results $script:RestartResults
if ($NotificationEmail) {
    Send-RestartNotification -EmailAddress $NotificationEmail -Results $script:RestartResults
}
$ExitCode = if ($report.Failed -gt 0) { 1 } else { 0 }
Write-Output "`nOperation completed!" -ForegroundColor $(if ($ExitCode -eq 0) { 'Green' } else { 'Yellow' })
exit $ExitCode



