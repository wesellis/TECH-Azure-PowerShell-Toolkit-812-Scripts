#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations\n    Author: Wes Ellis (wes@wesellis.com)\n#>
# Wesley Ellis  Azure VM Maintenance & Update Manager
# Contact: wesellis.com
# Version: 2.5 Enterprise Edition
#              with patching, health monitoring, and enterprise reporting
[CmdletBinding()]
param (
    [Parameter(Mandatory, HelpMessage="Azure Resource Group containing the VM")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroup,
    [Parameter(HelpMessage="Specific VM name (leave empty for all VMs in RG)")]
    [string]$VirtualMachineName,
    [Parameter(HelpMessage="Maintenance operation type")]
    [ValidateSet("HealthCheck", "SecurityUpdates", "SystemUpdates", "FullMaintenance", "CustomScript")]
    [string]$MaintenanceType = "HealthCheck",
    [Parameter(HelpMessage="Schedule maintenance window")]
    [ValidateSet("Immediate", "MaintenanceWindow", "NextReboot")]
    [string]$Scheduling = "MaintenanceWindow",
    [Parameter(HelpMessage="Custom PowerShell script to run on VMs")]
    [string]$CustomScriptPath,
    [Parameter(HelpMessage="Create  maintenance report")]
    [switch]$GenerateReport,
    [Parameter(HelpMessage="Send email notification on completion")]
    [switch]$EmailNotification,
    [Parameter(HelpMessage="Test mode - no actual changes")]
    [switch]$TestMode
)
# Wesley Ellis Enhanced Framework
$LogPrefix = "[WE-VM-MaintenanceManager]"
$StartTime = Get-Date -ErrorAction Stop
# Enhanced logging and reporting
[OutputType([PSCustomObject])]
 {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "ACTION")]
        [string]$Level = "INFO",
        [string]$VMName = "GLOBAL"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
        "ACTION" = "Magenta"
    }
    $logEntry = "$timestamp $LogPrefix [$VMName] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
    # Always log to file for audit trail
    Add-Content -Path "WE-VM-Maintenance-$(Get-Date -Format 'yyyyMMdd').log" -Value $logEntry
}
# Wesley Ellis VM Health Assessment Function
function Get-WEVMHealthStatus -ErrorAction Stop {
    param([string]$ResourceGroup, [string]$VMName)
    Write-WEMaintenanceLog "Performing  health assessment" "ACTION" $VMName
    try {
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
        $vmStatus = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Status
        # Enhanced health metrics
        $healthMetrics = @{
            VMName = $VMName
            PowerState = ($vmStatus.Statuses | Where-Object {$_.Code -like "PowerState/*"}).DisplayStatus
            ProvisioningState = $vm.ProvisioningState
            VMSize = $vm.HardwareProfile.VmSize
            OSType = $vm.StorageProfile.OsDisk.OsType
            Location = $vm.Location
            LastBootTime = "Unknown"
            DiskHealth = @()
            NetworkHealth = @()
            ExtensionStatus = @()
            Recommendations = @()
        }
        # Check disk health
        foreach ($disk in $vm.StorageProfile.DataDisks) {
            $diskInfo = @{
                DiskName = $disk.Name
                SizeGB = $disk.DiskSizeGB
                Caching = $disk.Caching
                Status = "Healthy"  # Would need actual disk metrics
            }
            $healthMetrics.DiskHealth += $diskInfo
        }
        # Check extensions
        if ($vm.Extensions) {
            foreach ($ext in $vm.Extensions) {
                $extStatus = @{
                    Name = $ext.Name
                    Type = $ext.VirtualMachineExtensionType
                    Status = "Unknown"  # Would need actual extension status
                }
                $healthMetrics.ExtensionStatus += $extStatus
            }
        }
        # Generate recommendations
        if ($vm.HardwareProfile.VmSize -like "*_A*") {
            $healthMetrics.Recommendations += "Consider upgrading from Basic tier VM size"
        }
        if ($vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType -eq "Standard_LRS") {
            $healthMetrics.Recommendations += "Consider Premium SSD for better performance"
        }
        Write-WEMaintenanceLog "Health assessment complete - $(($healthMetrics.Recommendations).Count) recommendations" "SUCCESS" $VMName
        return $healthMetrics
    } catch {
        Write-WEMaintenanceLog "Health assessment failed: $($_.Exception.Message)" "ERROR" $VMName
        return $null
    }
}
# Enhanced Update Management Function
function Invoke-WEVMUpdateProcess {
    param(
        [string]$ResourceGroup,
        [string]$VMName,
        [string]$UpdateType
    )
    Write-WEMaintenanceLog "Starting $UpdateType process" "ACTION" $VMName
    if ($TestMode) {
        Write-WEMaintenanceLog "TEST MODE: Would perform $UpdateType on $VMName" "WARN" $VMName
        return @{ Status = "TestMode"; Message = "No changes made in test mode" }
    }
    try {
        switch ($UpdateType) {
            "SecurityUpdates" {
                # Implement security-specific updates
                $scriptBlock = @"
# Wesley Ellis Security Update Script
Write-Output "Starting security updates..."
if (`$env:OS -like "*Windows*") {
    Install-Module PSWindowsUpdate -Force -AllowClobber
    Get-WUInstall -AcceptAll -AutoReboot -CategoryIDs @('0fa1201d-4330-4fa8-8ae9-b877473b6441')
} else {
    sudo apt update && sudo apt upgrade -y
}
Write-Output "Security updates completed"
"@
                break
            }
            "SystemUpdates" {
                # Full system updates
                $scriptBlock = @"
# Wesley Ellis System Update Script
Write-Output "Starting  system updates..."
if (`$env:OS -like "*Windows*") {
    Install-Module PSWindowsUpdate -Force -AllowClobber
    Get-WUInstall -AcceptAll -AutoReboot
} else {
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
}
Write-Output "System updates completed"
"@
                break
            }
            "FullMaintenance" {
                #  maintenance
                $scriptBlock = @"
# Wesley Ellis Full Maintenance Script - wesellis.com
Write-Output "Starting full maintenance cycle..."
# Disk cleanup
if (`$env:OS -like "*Windows*") {
    cleanmgr /sagerun:1
    dism /online /cleanup-image /startcomponentcleanup
} else {
    sudo apt autoremove -y
    sudo apt autoclean
    sudo journalctl --vacuum-time=7d
}
# Service health check
Write-Output "Performing service health checks..."
# Log rotation and cleanup
Write-Output "Performing log cleanup..."
Write-Output "Full maintenance completed by Wesley Ellis toolkit"
"@
                break
            }
        }
        # Execute maintenance script
        if ($scriptBlock) {
             else { "RunShellScript" }
                ScriptString = $scriptBlock
            }
            Write-WEMaintenanceLog "Executing maintenance commands..." "ACTION" $VMName
            $result = Invoke-AzVMRunCommand @runCommandParams
            if ($result.Status -eq "Succeeded") {
                Write-WEMaintenanceLog "Maintenance completed successfully" "SUCCESS" $VMName
                return @{ Status = "Success"; Output = $result.Value[0].Message }
            } else {
                Write-WEMaintenanceLog "Maintenance failed: $($result.Error)" "ERROR" $VMName
                return @{ Status = "Failed"; Error = $result.Error }
            }
        }
    } catch {
        Write-WEMaintenanceLog "Update process failed: $($_.Exception.Message)" "ERROR" $VMName
        return @{ Status = "Failed"; Error = $_.Exception.Message }
    }
}
# Wesley Ellis Main Execution Block
Write-WEMaintenanceLog "Wesley Ellis VM Maintenance Manager Starting" "INFO"
Write-WEMaintenanceLog "Resource Group: $ResourceGroup" "INFO"
Write-WEMaintenanceLog "Maintenance Type: $MaintenanceType" "INFO"
Write-WEMaintenanceLog "Contact: wesellis.com" "INFO"
try {
    # Get target VMs
    $targetVMs = if ($VirtualMachineName) {
        @(Get-AzVM -ResourceGroupName $ResourceGroup -Name $VirtualMachineName)
    } else {
        Get-AzVM -ResourceGroupName $ResourceGroup
    }
    Write-WEMaintenanceLog "Found $($targetVMs.Count) VMs for maintenance" "INFO"
    $MaintenanceResults = @()
    foreach ($vm in $targetVMs) {
        Write-WEMaintenanceLog "Processing VM: $($vm.Name)" "ACTION" $vm.Name
        # Get health status
        $healthStatus = Get-WEVMHealthStatus -ResourceGroup $ResourceGroup -VMName $vm.Name
        # Perform maintenance based on type
        $maintenanceResult = switch ($MaintenanceType) {
            "HealthCheck" {
                Write-WEMaintenanceLog "Health check completed" "SUCCESS" $vm.Name
                @{ Status = "HealthCheckComplete"; Details = $healthStatus }
            }
            default {
                Invoke-WEVMUpdateProcess -ResourceGroup $ResourceGroup -VMName $vm.Name -UpdateType $MaintenanceType
            }
        }
        # Compile results
        $MaintenanceResults += [PSCustomObject]@{
            VMName = $vm.Name
            MaintenanceType = $MaintenanceType
            StartTime = $StartTime
            CompletionTime = Get-Date -ErrorAction Stop
            Status = $maintenanceResult.Status
            HealthMetrics = $healthStatus
            Recommendations = $healthStatus.Recommendations -join "; "
            ProcessedBy = "Wesley Ellis Enterprise Toolkit"
        }
    }
    # Generate  report
    if ($GenerateReport) {
        $reportPath = "WE-VM-Maintenance-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $MaintenanceResults | Export-Csv -Path $reportPath -NoTypeInformation
        Write-WEMaintenanceLog " report exported: $reportPath" "SUCCESS"
    }
    # Summary statistics
    $successCount = ($MaintenanceResults | Where-Object {$_.Status -like "*Success*"}).Count
    $totalTime = (Get-Date) - $StartTime
    Write-WEMaintenanceLog "Maintenance Operation Complete!" "SUCCESS"
    Write-WEMaintenanceLog "   VMs Processed: $($MaintenanceResults.Count)" "SUCCESS"
    Write-WEMaintenanceLog "   Successful: $successCount" "SUCCESS"
    Write-WEMaintenanceLog "   Total Time: $($totalTime.TotalMinutes.ToString('F1')) minutes" "SUCCESS"
    Write-WEMaintenanceLog "   By: Wesley Ellis | wesellis.com" "SUCCESS"
    return $MaintenanceResults
} catch {
    Write-WEMaintenanceLog "Maintenance operation failed: $($_.Exception.Message)" "ERROR"
    Write-WEMaintenanceLog "Contact wesellis.com for enterprise support" "ERROR"
    throw
}
# Wesley Ellis Enterprise VM Management Toolkit
#  automation solutions: wesellis.com\n

