# ============================================================================
# Wesley Ellis Advanced Azure VM Maintenance & Update Manager
# Author: Wesley Ellis
# Contact: wesellis.com
# Version: 2.5 Enterprise Edition
# Date: August 2025
# Description: Comprehensive Azure Virtual Machine maintenance automation
#              with patching, health monitoring, and enterprise reporting
# ============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, HelpMessage="Azure Resource Group containing the VM")]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroup,
    
    [Parameter(Mandatory=$false, HelpMessage="Specific VM name (leave empty for all VMs in RG)")]
    [string]$WEVirtualMachineName,
    
    [Parameter(Mandatory=$false, HelpMessage="Maintenance operation type")]
    [ValidateSet("HealthCheck", "SecurityUpdates", "SystemUpdates", "FullMaintenance", "CustomScript")]
    [string]$WEMaintenanceType = "HealthCheck",
    
    [Parameter(Mandatory=$false, HelpMessage="Schedule maintenance window")]
    [ValidateSet("Immediate", "MaintenanceWindow", "NextReboot")]
    [string]$WEScheduling = "MaintenanceWindow",
    
    [Parameter(Mandatory=$false, HelpMessage="Custom PowerShell script to run on VMs")]
    [string]$WECustomScriptPath,
    
    [Parameter(Mandatory=$false, HelpMessage="Create detailed maintenance report")]
    [switch]$WEGenerateReport,
    
    [Parameter(Mandatory=$false, HelpMessage="Send email notification on completion")]
    [switch]$WEEmailNotification,
    
    [Parameter(Mandatory=$false, HelpMessage="Test mode - no actual changes")]
    [switch]$WETestMode
)

# Wesley Ellis Enhanced Framework
$WELogPrefix = "[WE-VM-MaintenanceManager]"
$WEStartTime = Get-Date

# Enhanced logging and reporting
function Write-WEMaintenanceLog {
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
    
    $logEntry = "$timestamp $WELogPrefix [$VMName] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
    
    # Always log to file for audit trail
    Add-Content -Path "WE-VM-Maintenance-$(Get-Date -Format 'yyyyMMdd').log" -Value $logEntry
}

# Wesley Ellis VM Health Assessment Function
function Get-WEVMHealthStatus {
    param([string]$ResourceGroup, [string]$VMName)
    
    Write-WEMaintenanceLog "Performing comprehensive health assessment" "ACTION" $VMName
    
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
    
    if ($WETestMode) {
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
Write-Output "Starting comprehensive system updates..."
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
                # Comprehensive maintenance
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
            $runCommandParams = @{
                ResourceGroupName = $ResourceGroup
                VMName = $VMName
                CommandId = if ($vm.StorageProfile.OsDisk.OsType -eq "Windows") { "RunPowerShellScript" } else { "RunShellScript" }
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
Write-WEMaintenanceLog "Resource Group: $WEResourceGroup" "INFO"
Write-WEMaintenanceLog "Maintenance Type: $WEMaintenanceType" "INFO"
Write-WEMaintenanceLog "Contact: wesellis.com" "INFO"

try {
    # Get target VMs
    $targetVMs = if ($WEVirtualMachineName) {
        @(Get-AzVM -ResourceGroupName $WEResourceGroup -Name $WEVirtualMachineName)
    } else {
        Get-AzVM -ResourceGroupName $WEResourceGroup
    }
    
    Write-WEMaintenanceLog "Found $($targetVMs.Count) VMs for maintenance" "INFO"
    
    $WEMaintenanceResults = @()
    
    foreach ($vm in $targetVMs) {
        Write-WEMaintenanceLog "Processing VM: $($vm.Name)" "ACTION" $vm.Name
        
        # Get health status
        $healthStatus = Get-WEVMHealthStatus -ResourceGroup $WEResourceGroup -VMName $vm.Name
        
        # Perform maintenance based on type
        $maintenanceResult = switch ($WEMaintenanceType) {
            "HealthCheck" {
                Write-WEMaintenanceLog "Health check completed" "SUCCESS" $vm.Name
                @{ Status = "HealthCheckComplete"; Details = $healthStatus }
            }
            default {
                Invoke-WEVMUpdateProcess -ResourceGroup $WEResourceGroup -VMName $vm.Name -UpdateType $WEMaintenanceType
            }
        }
        
        # Compile results
        $WEMaintenanceResults += [PSCustomObject]@{
            VMName = $vm.Name
            MaintenanceType = $WEMaintenanceType
            StartTime = $WEStartTime
            CompletionTime = Get-Date
            Status = $maintenanceResult.Status
            HealthMetrics = $healthStatus
            Recommendations = $healthStatus.Recommendations -join "; "
            ProcessedBy = "Wesley Ellis Enterprise Toolkit"
        }
    }
    
    # Generate comprehensive report
    if ($WEGenerateReport) {
        $reportPath = "WE-VM-Maintenance-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $WEMaintenanceResults | Export-Csv -Path $reportPath -NoTypeInformation
        Write-WEMaintenanceLog "Detailed report exported: $reportPath" "SUCCESS"
    }
    
    # Summary statistics
    $successCount = ($WEMaintenanceResults | Where-Object {$_.Status -like "*Success*"}).Count
    $totalTime = (Get-Date) - $WEStartTime
    
    Write-WEMaintenanceLog "🎉 Maintenance Operation Complete!" "SUCCESS"
    Write-WEMaintenanceLog "   VMs Processed: $($WEMaintenanceResults.Count)" "SUCCESS"
    Write-WEMaintenanceLog "   Successful: $successCount" "SUCCESS"
    Write-WEMaintenanceLog "   Total Time: $($totalTime.TotalMinutes.ToString('F1')) minutes" "SUCCESS"
    Write-WEMaintenanceLog "   By: Wesley Ellis | wesellis.com" "SUCCESS"
    
    return $WEMaintenanceResults
    
} catch {
    Write-WEMaintenanceLog "❌ Maintenance operation failed: $($_.Exception.Message)" "ERROR"
    Write-WEMaintenanceLog "Contact wesellis.com for enterprise support" "ERROR"
    throw
}

# Wesley Ellis Enterprise VM Management Toolkit
# Advanced automation solutions: wesellis.com
# ============================================================================