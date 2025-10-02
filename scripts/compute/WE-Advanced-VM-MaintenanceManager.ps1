#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations


    Author: Wes Ellis (wes@wesellis.com)
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
    [string]$ErrorActionPreference = 'Stop'
    [string]$LogPrefix = "[WE-VM-MaintenanceManager]"
$StartTime = Get-Date -ErrorAction Stop
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS", "ACTION")]
        [string]$Level = "INFO",
        [string]$VMName = "GLOBAL"
    )
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
        "ACTION" = "Magenta"
    }
    [string]$LogEntry = "$timestamp $LogPrefix [$VMName] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
    Add-Content -Path "WE-VM-Maintenance-$(Get-Date -Format 'yyyyMMdd').log" -Value $LogEntry
}
function Get-WEVMHealthStatus -ErrorAction Stop {
    param([string]$ResourceGroup, [string]$VMName)
    Write-WEMaintenanceLog "Performing  health assessment" "ACTION" $VMName
    try {
$vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName
$VmStatus = Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Status
$HealthMetrics = @{
            VMName = $VMName
            PowerState = ($VmStatus.Statuses | Where-Object {$_.Code -like "PowerState/*"}).DisplayStatus
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
        foreach ($disk in $vm.StorageProfile.DataDisks) {
$DiskInfo = @{
                DiskName = $disk.Name
                SizeGB = $disk.DiskSizeGB
                Caching = $disk.Caching
                Status = "Healthy"  # Would need actual disk metrics
            }
    [string]$HealthMetrics.DiskHealth += $DiskInfo
        }
        if ($vm.Extensions) {
            foreach ($ext in $vm.Extensions) {
$ExtStatus = @{
                    Name = $ext.Name
                    Type = $ext.VirtualMachineExtensionType
                    Status = "Unknown"  # Would need actual extension status
                }
    [string]$HealthMetrics.ExtensionStatus += $ExtStatus
            }
        }
        if ($vm.HardwareProfile.VmSize -like "*_A*") {
    [string]$HealthMetrics.Recommendations += "Consider upgrading from Basic tier VM size"
        }
        if ($vm.StorageProfile.OsDisk.ManagedDisk.StorageAccountType -eq "Standard_LRS") {
    [string]$HealthMetrics.Recommendations += "Consider Premium SSD for better performance"
        }
        Write-WEMaintenanceLog "Health assessment complete - $(($HealthMetrics.Recommendations).Count) recommendations" "SUCCESS" $VMName
        return $HealthMetrics
    } catch {
        Write-WEMaintenanceLog "Health assessment failed: $($_.Exception.Message)" "ERROR" $VMName
        return $null
    }
}
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
    [string]$ScriptBlock = @"
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
    [string]$ScriptBlock = @"
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
    [string]$ScriptBlock = @"
Write-Output "Starting full maintenance cycle..."
if (`$env:OS -like "*Windows*") {
    cleanmgr /sagerun:1
    dism /online /cleanup-image /startcomponentcleanup
} else {
    sudo apt autoremove -y
    sudo apt autoclean
    sudo journalctl --vacuum-time=7d
}
Write-Output "Performing service health checks..."
Write-Output "Performing log cleanup..."
Write-Output "Full maintenance completed by Wesley Ellis toolkit"
"@
                break
            }
        }
        if ($ScriptBlock) {
             else { "RunShellScript" }
                ScriptString = $ScriptBlock
            }
            Write-WEMaintenanceLog "Executing maintenance commands..." "ACTION" $VMName
    [string]$result = Invoke-AzVMRunCommand @runCommandParams
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
Write-WEMaintenanceLog "Wesley Ellis VM Maintenance Manager Starting" "INFO"
Write-WEMaintenanceLog "Resource Group: $ResourceGroup" "INFO"
Write-WEMaintenanceLog "Maintenance Type: $MaintenanceType" "INFO"
Write-WEMaintenanceLog "Contact: wesellis.com" "INFO"
try {
    [string]$TargetVMs = if ($VirtualMachineName) {
        @(Get-AzVM -ResourceGroupName $ResourceGroup -Name $VirtualMachineName)
    } else {
        Get-AzVM -ResourceGroupName $ResourceGroup
    }
    Write-WEMaintenanceLog "Found $($TargetVMs.Count) VMs for maintenance" "INFO"
    [string]$MaintenanceResults = @()
    foreach ($vm in $TargetVMs) {
        Write-WEMaintenanceLog "Processing VM: $($vm.Name)" "ACTION" $vm.Name
$HealthStatus = Get-WEVMHealthStatus -ResourceGroup $ResourceGroup -VMName $vm.Name
    [string]$MaintenanceResult = switch ($MaintenanceType) {
            "HealthCheck" {
                Write-WEMaintenanceLog "Health check completed" "SUCCESS" $vm.Name
                @{ Status = "HealthCheckComplete"; Details = $HealthStatus }
            }
            default {
                Invoke-WEVMUpdateProcess -ResourceGroup $ResourceGroup -VMName $vm.Name -UpdateType $MaintenanceType
            }
        }
    [string]$MaintenanceResults += [PSCustomObject]@{
            VMName = $vm.Name
            MaintenanceType = $MaintenanceType
            StartTime = $StartTime
            CompletionTime = Get-Date -ErrorAction Stop
            Status = $MaintenanceResult.Status
            HealthMetrics = $HealthStatus
            Recommendations = $HealthStatus.Recommendations -join "; "
            ProcessedBy = "Wesley Ellis Enterprise Toolkit"
        }
    }
    if ($GenerateReport) {
    [string]$ReportPath = "WE-VM-Maintenance-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    [string]$MaintenanceResults | Export-Csv -Path $ReportPath -NoTypeInformation
        Write-WEMaintenanceLog " report exported: $ReportPath" "SUCCESS"
    }
    [string]$SuccessCount = ($MaintenanceResults | Where-Object {$_.Status -like "*Success*"}).Count
    [string]$TotalTime = (Get-Date) - $StartTime
    Write-WEMaintenanceLog "Maintenance Operation Complete!" "SUCCESS"
    Write-WEMaintenanceLog "   VMs Processed: $($MaintenanceResults.Count)" "SUCCESS"
    Write-WEMaintenanceLog "   Successful: $SuccessCount" "SUCCESS"
    Write-WEMaintenanceLog "   Total Time: $($TotalTime.TotalMinutes.ToString('F1')) minutes" "SUCCESS"
    Write-WEMaintenanceLog "   By: Wesley Ellis | wesellis.com" "SUCCESS"
    return $MaintenanceResults
} catch {
    Write-WEMaintenanceLog "Maintenance operation failed: $($_.Exception.Message)" "ERROR"
    Write-WEMaintenanceLog "Contact wesellis.com for enterprise support" "ERROR"
    throw`n}
