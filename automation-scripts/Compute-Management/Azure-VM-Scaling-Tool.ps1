#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Scale VM sizes

.DESCRIPTION
    Scale VMs
.PARAMETER ResourceGroupName
    Resource group
.PARAMETER VmName
    VM name
.PARAMETER VmNames
    VM names array
.PARAMETER NewVmSize
    Target VM size (e.g., Standard_D2s_v3, Standard_B2ms)
.PARAMETER Force
    Skip confirmation
.PARAMETER Wait
    Wait for completion
.PARAMETER TimeoutMinutes
    Timeout (minutes)
.PARAMETER CheckCompatibility
    Validate VM size compatibility before scaling
.PARAMETER ShowCostImpact
    Display estimated cost impact of the scaling operation
.PARAMETER DryRun
    Dry run mode
.PARAMETER StopIfRequired
    Stop VM if required
    .\Azure-VM-Scaling-Tool.ps1 -ResourceGroupName "RG-Production" -VmName "VM-WebServer01" -NewVmSize "Standard_D4s_v3"
    .\Azure-VM-Scaling-Tool.ps1 -ResourceGroupName "RG-Production" -VmNames @("VM-Web01", "VM-Web02") -NewVmSize "Standard_B2ms" -CheckCompatibility
    .\Azure-VM-Scaling-Tool.ps1 -ResourceGroupName "RG-Test" -VmName "VM-TestServer01" -NewVmSize "Standard_D2s_v3" -DryRun -ShowCostImpact
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
    [ValidateCount(1, 20)]
    [string[]]$VmNames,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$NewVmSize,
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$Wait,
    [Parameter()]
    [ValidateRange(5, 120)]
    [int]$TimeoutMinutes = 30,
    [Parameter()]
    [switch]$CheckCompatibility,
    [Parameter()]
    [switch]$ShowCostImpact,
    [Parameter()]
    [switch]$DryRun,
    [Parameter()]
    [switch]$StopIfRequired
)
$ErrorActionPreference = 'Stop'
# Global tracking variables
$script:ScalingResults = @()
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
function Get-AvailableVMSizes {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$Location
    )
    try {
        $availableSizes = Get-AzVMSize -Location $Location
        return $availableSizes
    }
    catch {
        Write-Warning "Could not retrieve available VM sizes for location: $Location"
        return @()
    }
}
function Test-VMSizeCompatibility {
    [CmdletBinding(SupportsShouldProcess)]

        [object]$VM,
        [string]$TargetSize
    )
    $compatibility = @{
        Compatible = $false
        Issues = @()
        Warnings = @()
        RequiresStop = $false
    }
    try {
        # Get available sizes for the VM's location
        $availableSizes = Get-AvailableVMSizes -Location $VM.Location
        if ($availableSizes) {
            $targetSizeInfo = $availableSizes | Where-Object { $_.Name -eq $TargetSize }
            if (-not $targetSizeInfo) {
                $compatibility.Issues += "Target size '$TargetSize' is not available in location '$($VM.Location)'"
                return $compatibility
            }
            # Basic compatibility checks
            $currentSizeInfo = $availableSizes | Where-Object { $_.Name -eq $VM.HardwareProfile.VmSize }
            if ($currentSizeInfo) {
                # Check if it's a meaningful change
                if ($currentSizeInfo.NumberOfCores -eq $targetSizeInfo.NumberOfCores -and
                    $currentSizeInfo.MemoryInMB -eq $targetSizeInfo.MemoryInMB) {
                    $compatibility.Warnings += "Target size has same CPU and memory specifications as current size"
                }
                # Check for significant size changes that might require stopping
                if ($targetSizeInfo.NumberOfCores -gt ($currentSizeInfo.NumberOfCores * 2) -or
                    $targetSizeInfo.MemoryInMB -gt ($currentSizeInfo.MemoryInMB * 2)) {
                    $compatibility.RequiresStop = $true
                    $compatibility.Warnings += "Large size increase may require VM to be stopped"
                }
            }
            $compatibility.Compatible = $true
        } else {
            $compatibility.Warnings += "Could not verify size compatibility - proceeding with caution"
            $compatibility.Compatible = $true
        }
    } catch {
        $compatibility.Issues += "Failed to check compatibility: $($_.Exception.Message)"
    }
    return $compatibility
}
function Get-VMCostEstimate {
    [CmdletBinding(SupportsShouldProcess)]

        [object]$VM,
        [string]$CurrentSize,
        [string]$TargetSize
    )
    # This is a placeholder for cost estimation
    # In a real implementation, this would integrate with Azure Pricing API
    $costInfo = @{
        CurrentSize = $CurrentSize
        TargetSize = $TargetSize
        EstimatedChange = "N/A (requires Azure Pricing API)"
        Warning = "Cost impact varies by region and billing model"
    }
    Write-Host "Cost Impact Analysis:" -ForegroundColor Cyan
    Write-Host "Current Size: $CurrentSize"
    Write-Host "Target Size: $TargetSize"
    Write-Host "Estimated Change: $($costInfo.EstimatedChange)" -ForegroundColor Yellow
    Write-Host "Note: $($costInfo.Warning)" -ForegroundColor Gray
    return $costInfo
}
function Wait-ForVMScaling {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$Name,
        [string]$TargetSize,
        [int]$TimeoutMinutes
    )
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $lastState = ""
    Write-Host "Waiting for VM scaling to complete (timeout: $TimeoutMinutes minutes)..." -ForegroundColor Yellow
    do {
        try {
            $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name
            $currentSize = $vm.HardwareProfile.VmSize
            $vmStatus = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
            $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
            $currentState = "$powerState (Size: $currentSize)"
            if ($currentState -ne $lastState) {
                Write-Host "Current state: $currentState" -ForegroundColor Cyan
                $lastState = $currentState
            }
            if ($currentSize -eq $TargetSize) {
                Write-Host "VM scaling completed: $currentSize" -ForegroundColor Green
                return $true
            }
            Start-Sleep -Seconds 15
        }
        catch {
            Write-Warning "Error checking VM state: $_"
            Start-Sleep -Seconds 15
        }
    } while ((Get-Date) -lt $timeout)
    Write-Warning "Timeout reached. VM scaling may still be in progress."
    return $false
}
function Scale-AzureVM {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$Name,
        [string]$TargetSize
    )
    $result = @{
        VMName = $Name
        StartTime = Get-Date
        Success = $false
        Error = $null
        CurrentSize = $null
        TargetSize = $TargetSize
        ActualFinalSize = $null
        RequiredStop = $false
        CompatibilityCheck = $null
    }
    try {
        Write-Host "`nProcessing VM: $Name" -ForegroundColor Cyan
        Write-Host ("=" * 60) -ForegroundColor Gray
        # Get current VM information
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name
        $result.CurrentSize = $vm.HardwareProfile.VmSize
        Write-Host "VM Information:" -ForegroundColor Cyan
        Write-Host "Name: $($vm.Name)"
        Write-Host "Location: $($vm.Location)"
        Write-Host "Current Size: $($result.CurrentSize)"
        Write-Host "Target Size: $TargetSize"
        # Check if already at target size
        if ($result.CurrentSize -eq $TargetSize) {
            Write-Host "VM is already at target size: $TargetSize" -ForegroundColor Yellow
            $result.Success = $true
            $result.ActualFinalSize = $TargetSize
            return $result
        }
        # Compatibility check
        if ($CheckCompatibility) {
            Write-Host "`nChecking compatibility..." -ForegroundColor Yellow
            $compatibility = Test-VMSizeCompatibility -VM $vm -TargetSize $TargetSize
            $result.CompatibilityCheck = $compatibility
            if ($compatibility.Issues.Count -gt 0) {
                foreach ($issue in $compatibility.Issues) {
                    Write-Host "ERROR: $issue" -ForegroundColor Red
                }
                if (-not $Force) {
                    throw "Compatibility check failed. Use -Force to override."
                }
            }
            if ($compatibility.Warnings.Count -gt 0) {
                foreach ($warning in $compatibility.Warnings) {
                    Write-Host "WARNING: $warning" -ForegroundColor Yellow
                }
            }
            if ($compatibility.RequiresStop) {
                $result.RequiredStop = $true
                Write-Host "INFO: This scaling operation may require stopping the VM" -ForegroundColor Cyan
            }
        }
        # Cost impact analysis
        if ($ShowCostImpact) {
            Get-VMCostEstimate -VM $vm -CurrentSize $result.CurrentSize -TargetSize $TargetSize
        }
        # Check if VM needs to be stopped
        $vmStatus = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $powerState = ($vmStatus.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
        $isRunning = $powerState -eq 'VM running'
        if ($isRunning -and $result.RequiredStop -and $StopIfRequired) {
            Write-Host "`nStopping VM for scaling operation..." -ForegroundColor Yellow
            if (-not $DryRun) {
                Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Force
                Write-Host "VM stopped successfully" -ForegroundColor Green
            } else {
                Write-Host "DRY RUN: Would stop VM: $Name" -ForegroundColor Cyan
            }
        }
        # Perform scaling
        Write-Host "`nScaling VM..." -ForegroundColor Yellow
        if ($PSCmdlet.ShouldProcess($Name, "Scale VM to $TargetSize")) {
            if (-not $DryRun) {
                $vm.HardwareProfile.VmSize = $TargetSize
                Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm
                Write-Host "VM scaling initiated successfully" -ForegroundColor Green
                # Verify the change
                $updatedVM = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name
                $result.ActualFinalSize = $updatedVM.HardwareProfile.VmSize
                if ($result.ActualFinalSize -eq $TargetSize) {
                    Write-Host "VM successfully scaled to: $TargetSize" -ForegroundColor Green
                    $result.Success = $true
                } else {
                    throw "Scaling verification failed. Expected: $TargetSize, Actual: $($result.ActualFinalSize)"
                }
            } else {
                Write-Host "DRY RUN: Would scale VM $Name from $($result.CurrentSize) to $TargetSize" -ForegroundColor Cyan
                $result.Success = $true
                $result.ActualFinalSize = $TargetSize
            }
        }
        # Restart VM if it was stopped for scaling
        if ($isRunning -and $result.RequiredStop -and $StopIfRequired -and -not $DryRun) {
            Write-Host "`nRestarting VM..." -ForegroundColor Yellow
            Start-AzVM -ResourceGroupName $ResourceGroup -Name $Name
            Write-Host "VM restarted successfully" -ForegroundColor Green
        
} catch {
        $result.Error = $_.Exception.Message
        $result.Success = $false
        Write-Host "VM scaling failed: $Name - $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
    }
    return $result
}
function New-ScalingReport {
    [CmdletBinding(SupportsShouldProcess)]
[object[]]$Results)
    $report = @{
        Timestamp = Get-Date
        TotalVMs = $Results.Count
        Successful = ($Results | Where-Object { $_.Success }).Count
        Failed = ($Results | Where-Object { -not $_.Success }).Count
        Details = $Results
    }
    Write-Host "`nVM Scaling Operation Summary" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host "Total VMs: $($report.TotalVMs)"
    Write-Host "Successful: $($report.Successful)" -ForegroundColor Green
    Write-Host "Failed: $($report.Failed)" -ForegroundColor $(if ($report.Failed -gt 0) { 'Red' } else { 'Green' })
    # Show scaling details
    Write-Host "`nScaling Details:" -ForegroundColor Cyan
    foreach ($result in $Results) {
        $status = if ($result.Success) { "" } else { "" }
        $color = if ($result.Success) { 'Green' } else { 'Red' }
        Write-Host "  $status $($result.VMName): $($result.CurrentSize)  $($result.ActualFinalSize)" -ForegroundColor $color
    }
    if ($report.Failed -gt 0) {
        Write-Host "`nFailed Scaling Operations:" -ForegroundColor Red
        $Results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $($_.VMName): $($_.Error)" -ForegroundColor Red
        }
    }
    if ($DryRun) {
        Write-Host "`nDRY RUN COMPLETED - No actual scaling was performed" -ForegroundColor Yellow
    }
    return $report
}
# Main execution
Write-Host "`nAzure VM Scaling Tool" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No actual scaling will be performed" -ForegroundColor Cyan
}
# Test Azure connection
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
# Prepare VM list
$vmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
# Confirmation
if (-not $Force -and -not $DryRun) {
    $vmCount = $vmList.Count
    $vmText = if ($vmCount -eq 1) { "VM" } else { "$vmCount VMs" }
    $action = "scale"
    Write-Host "`nAbout to $action $vmText in resource group '$ResourceGroupName':" -ForegroundColor Yellow
    foreach ($vm in $vmList) {
        Write-Host "  - $vm  $NewVmSize" -ForegroundColor White
    }
    Write-Host "`nScaling Options:" -ForegroundColor Yellow
    Write-Host "Target Size: $NewVmSize"
    Write-Host "Check Compatibility: $(if ($CheckCompatibility) { 'YES' } else { 'NO' })"
    Write-Host "Show Cost Impact: $(if ($ShowCostImpact) { 'YES' } else { 'NO' })"
    Write-Host "Auto-stop if Required: $(if ($StopIfRequired) { 'YES' } else { 'NO' })"
    $confirmation = Read-Host "`nContinue with scaling? (y/N)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}
# Process VMs
Write-Host "`nStarting VM scaling operations..." -ForegroundColor Yellow
foreach ($vm in $vmList) {
    try {
        $result = Scale-AzureVM -ResourceGroup $ResourceGroupName -Name $vm -TargetSize $NewVmSize
        $script:ScalingResults += $result
        # Wait for completion if requested
        if ($result.Success -and $Wait -and -not $DryRun) {
            $waitResult = Wait-ForVMScaling -ResourceGroup $ResourceGroupName -Name $vm -TargetSize $NewVmSize -TimeoutMinutes $TimeoutMinutes
            $result.WaitCompleted = $waitResult
        
} catch {
        $errorResult = @{
            VMName = $vm
            StartTime = Get-Date
            EndTime = Get-Date
            Success = $false
            Error = $_.Exception.Message
            CurrentSize = "Unknown"
            TargetSize = $NewVmSize
            ActualFinalSize = "Unknown"
        }
        $script:ScalingResults += $errorResult
    }
}
# Generate report
$report = New-ScalingReport -Results $script:ScalingResults
# Exit with appropriate code
$exitCode = if ($report.Failed -gt 0) { 1 } else { 0 }
Write-Host "`nOperation completed!" -ForegroundColor $(if ($exitCode -eq 0) { 'Green' } else { 'Yellow' })
exit $exitCode\n

