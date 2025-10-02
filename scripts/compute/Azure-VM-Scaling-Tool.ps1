#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Scale VM sizes

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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
param(
[Parameter(Mandatory = $true)]
)
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
$script:ScalingResults = @()
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
function Get-AvailableVMSizes {
    [string]$Location
    )
    try {
        $AvailableSizes = Get-AzVMSize -Location $Location
        return $AvailableSizes
    }
    catch {
        Write-Warning "Could not retrieve available VM sizes for location: $Location"
        return @()
    }
}
function Test-VMSizeCompatibility {
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
        $AvailableSizes = Get-AvailableVMSizes -Location $VM.Location
        if ($AvailableSizes) {
            $TargetSizeInfo = $AvailableSizes | Where-Object { $_.Name -eq $TargetSize }
            if (-not $TargetSizeInfo) {
                $compatibility.Issues += "Target size '$TargetSize' is not available in location '$($VM.Location)'"
                return $compatibility
            }
            $CurrentSizeInfo = $AvailableSizes | Where-Object { $_.Name -eq $VM.HardwareProfile.VmSize }
            if ($CurrentSizeInfo) {
                if ($CurrentSizeInfo.NumberOfCores -eq $TargetSizeInfo.NumberOfCores -and
                    $CurrentSizeInfo.MemoryInMB -eq $TargetSizeInfo.MemoryInMB) {
                    $compatibility.Warnings += "Target size has same CPU and memory specifications as current size"
                }
                if ($TargetSizeInfo.NumberOfCores -gt ($CurrentSizeInfo.NumberOfCores * 2) -or
                    $TargetSizeInfo.MemoryInMB -gt ($CurrentSizeInfo.MemoryInMB * 2)) {
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
    [object]$VM,
        [string]$CurrentSize,
        [string]$TargetSize
    )
    $CostInfo = @{
        CurrentSize = $CurrentSize
        TargetSize = $TargetSize
        EstimatedChange = "N/A (requires Azure Pricing API)"
        Warning = "Cost impact varies by region and billing model"
    }
    Write-Host "Cost Impact Analysis:" -ForegroundColor Green
    Write-Output "Current Size: $CurrentSize"
    Write-Output "Target Size: $TargetSize"
    Write-Host "Estimated Change: $($CostInfo.EstimatedChange)" -ForegroundColor Green
    Write-Host "Note: $($CostInfo.Warning)" -ForegroundColor Green
    return $CostInfo
}
function Wait-ForVMScaling {
    [string]$ResourceGroup,
        [string]$Name,
        [string]$TargetSize,
        [int]$TimeoutMinutes
    )
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $LastState = ""
    Write-Host "Waiting for VM scaling to complete (timeout: $TimeoutMinutes minutes)..." -ForegroundColor Green
    do {
        try {
            $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name
            $CurrentSize = $vm.HardwareProfile.VmSize
            $VmStatus = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
            $PowerState = ($VmStatus.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
            $CurrentState = "$PowerState (Size: $CurrentSize)"
            if ($CurrentState -ne $LastState) {
                Write-Host "Current state: $CurrentState" -ForegroundColor Green
                $LastState = $CurrentState
            }
            if ($CurrentSize -eq $TargetSize) {
                Write-Host "VM scaling completed: $CurrentSize" -ForegroundColor Green
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
        Write-Host "`nProcessing VM: $Name" -ForegroundColor Green
        Write-Host ("=" * 60) -ForegroundColor Gray
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name
        $result.CurrentSize = $vm.HardwareProfile.VmSize
        Write-Host "VM Information:" -ForegroundColor Green
        Write-Output "Name: $($vm.Name)"
        Write-Output "Location: $($vm.Location)"
        Write-Output "Current Size: $($result.CurrentSize)"
        Write-Output "Target Size: $TargetSize"
        if ($result.CurrentSize -eq $TargetSize) {
            Write-Host "VM is already at target size: $TargetSize" -ForegroundColor Green
            $result.Success = $true
            $result.ActualFinalSize = $TargetSize
            return $result
        }
        if ($CheckCompatibility) {
            Write-Host "`nChecking compatibility..." -ForegroundColor Green
            $compatibility = Test-VMSizeCompatibility -VM $vm -TargetSize $TargetSize
            $result.CompatibilityCheck = $compatibility
            if ($compatibility.Issues.Count -gt 0) {
                foreach ($issue in $compatibility.Issues) {
                    Write-Host "ERROR: $issue" -ForegroundColor Green
                }
                if (-not $Force) {
                    throw "Compatibility check failed. Use -Force to override."
                }
            }
            if ($compatibility.Warnings.Count -gt 0) {
                foreach ($warning in $compatibility.Warnings) {
                    Write-Host "WARNING: $warning" -ForegroundColor Green
                }
            }
            if ($compatibility.RequiresStop) {
                $result.RequiredStop = $true
                Write-Host "INFO: This scaling operation may require stopping the VM" -ForegroundColor Green
            }
        }
        if ($ShowCostImpact) {
            Get-VMCostEstimate -VM $vm -CurrentSize $result.CurrentSize -TargetSize $TargetSize
        }
        $VmStatus = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Status
        $PowerState = ($VmStatus.Statuses | Where-Object { $_.Code -like 'PowerState/*' }).DisplayStatus
        $IsRunning = $PowerState -eq 'VM running'
        if ($IsRunning -and $result.RequiredStop -and $StopIfRequired) {
            Write-Host "`nStopping VM for scaling operation..." -ForegroundColor Green
            if (-not $DryRun) {
                Stop-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Force
                Write-Host "VM stopped successfully" -ForegroundColor Green
            } else {
                Write-Host "DRY RUN: Would stop VM: $Name" -ForegroundColor Green
            }
        }
        Write-Host "`nScaling VM..." -ForegroundColor Green
        if ($PSCmdlet.ShouldProcess($Name, "Scale VM to $TargetSize")) {
            if (-not $DryRun) {
                $vm.HardwareProfile.VmSize = $TargetSize
                Update-AzVM -ResourceGroupName $ResourceGroup -VM $vm
                Write-Host "VM scaling initiated successfully" -ForegroundColor Green
                $UpdatedVM = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name
                $result.ActualFinalSize = $UpdatedVM.HardwareProfile.VmSize
                if ($result.ActualFinalSize -eq $TargetSize) {
                    Write-Host "VM successfully scaled to: $TargetSize" -ForegroundColor Green
                    $result.Success = $true
                } else {
                    throw "Scaling verification failed. Expected: $TargetSize, Actual: $($result.ActualFinalSize)"
                }
            } else {
                Write-Host "DRY RUN: Would scale VM $Name from $($result.CurrentSize) to $TargetSize" -ForegroundColor Green
                $result.Success = $true
                $result.ActualFinalSize = $TargetSize
            }
        }
        if ($IsRunning -and $result.RequiredStop -and $StopIfRequired -and -not $DryRun) {
            Write-Host "`nRestarting VM..." -ForegroundColor Green
            Start-AzVM -ResourceGroupName $ResourceGroup -Name $Name
            Write-Host "VM restarted successfully" -ForegroundColor Green

} catch {
        $result.Error = $_.Exception.Message
        $result.Success = $false
        Write-Host "VM scaling failed: $Name - $($_.Exception.Message)" -ForegroundColor Green
    }
    finally {
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
    }
    return $result
}
function New-ScalingReport {
    [object[]]$Results)
    $report = @{
        Timestamp = Get-Date
        TotalVMs = $Results.Count
        Successful = ($Results | Where-Object { $_.Success }).Count
        Failed = ($Results | Where-Object { -not $_.Success }).Count
        Details = $Results
    }
    Write-Host "`nVM Scaling Operation Summary" -ForegroundColor Green
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Output "Total VMs: $($report.TotalVMs)"
    Write-Host "Successful: $($report.Successful)" -ForegroundColor Green
    Write-Output "Failed: $($report.Failed)" -ForegroundColor $(if ($report.Failed -gt 0) { 'Red' } else { 'Green' })
    Write-Host "`nScaling Details:" -ForegroundColor Green
    foreach ($result in $Results) {
        $status = if ($result.Success) { "" } else { "" }
        $color = if ($result.Success) { 'Green' } else { 'Red' }
        Write-Output "  $status $($result.VMName): $($result.CurrentSize)  $($result.ActualFinalSize)" -ForegroundColor $color
    }
    if ($report.Failed -gt 0) {
        Write-Host "`nFailed Scaling Operations:" -ForegroundColor Green
        $Results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $($_.VMName): $($_.Error)" -ForegroundColor Green
        }
    }
    if ($DryRun) {
        Write-Host "`nDRY RUN COMPLETED - No actual scaling was performed" -ForegroundColor Green
    }
    return $report
}
Write-Host "`nAzure VM Scaling Tool" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No actual scaling will be performed" -ForegroundColor Green
}
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
$VmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
if (-not $Force -and -not $DryRun) {
    $VmCount = $VmList.Count
    $VmText = if ($VmCount -eq 1) { "VM" } else { "$VmCount VMs" }
    $action = "scale"
    Write-Host "`nAbout to $action $VmText in resource group '$ResourceGroupName':" -ForegroundColor Green
    foreach ($vm in $VmList) {
        Write-Host "  - $vm  $NewVmSize" -ForegroundColor Green
    }
    Write-Host "`nScaling Options:" -ForegroundColor Green
    Write-Output "Target Size: $NewVmSize"
    Write-Output "Check Compatibility: $(if ($CheckCompatibility) { 'YES' } else { 'NO' })"
    Write-Output "Show Cost Impact: $(if ($ShowCostImpact) { 'YES' } else { 'NO' })"
    Write-Output "Auto-stop if Required: $(if ($StopIfRequired) { 'YES' } else { 'NO' })"
    $confirmation = Read-Host "`nContinue with scaling? (y/N)"
    if ($confirmation -ne 'y') {
        Write-Host "Operation cancelled" -ForegroundColor Green
        exit 0
    }
}
Write-Host "`nStarting VM scaling operations..." -ForegroundColor Green
foreach ($vm in $VmList) {
    try {
        $result = Scale-AzureVM -ResourceGroup $ResourceGroupName -Name $vm -TargetSize $NewVmSize
        $script:ScalingResults += $result
        if ($result.Success -and $Wait -and -not $DryRun) {
            $WaitResult = Wait-ForVMScaling -ResourceGroup $ResourceGroupName -Name $vm -TargetSize $NewVmSize -TimeoutMinutes $TimeoutMinutes
            $result.WaitCompleted = $WaitResult

} catch {
        $ErrorResult = @{
            VMName = $vm
            StartTime = Get-Date
            EndTime = Get-Date
            Success = $false
            Error = $_.Exception.Message
            CurrentSize = "Unknown"
            TargetSize = $NewVmSize
            ActualFinalSize = "Unknown"
        }
        $script:ScalingResults += $ErrorResult
    }
}
$report = New-ScalingReport -Results $script:ScalingResults
$ExitCode = if ($report.Failed -gt 0) { 1 } else { 0 }
Write-Output "`nOperation completed!" -ForegroundColor $(if ($ExitCode -eq 0) { 'Green' } else { 'Yellow' })
exit $ExitCode



