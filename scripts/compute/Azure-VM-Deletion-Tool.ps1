#Requires -Version 7.0
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Delete VMs and optionally their resources

.DESCRIPTION
    Deletes Azure VMs 
.PARAMETER ResourceGroupName
    Resource group
.PARAMETER VmName
    VM name
.PARAMETER VmNames
    VM names array
.PARAMETER DeleteDisks
    Delete disks
.PARAMETER DeleteNetworkResources
    Delete NICs and IPs
.PARAMETER Force
    Skip confirmation
.PARAMETER BackupFirst
    Backup disks first
.PARAMETER WaitForCompletion
    Wait for deletion operations to complete before returning
.PARAMETER TimeoutMinutes
    Timeout (minutes)
.PARAMETER DryRun
    Dry run mode
    .\Azure-VM-Deletion-Tool.ps1 -ResourceGroupName "RG-Test" -VmName "VM-TestServer01"
    .\Azure-VM-Deletion-Tool.ps1 -ResourceGroupName "RG-Test" -VmNames @("VM-Test01", "VM-Test02") -DeleteDisks -BackupFirst
    .\Azure-VM-Deletion-Tool.ps1 -ResourceGroupName "RG-Test" -VmName "VM-TestServer01" -DryRun
    WARNING: This tool permanently deletes Azure resources. Use with extreme caution.
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
    [Parameter()]
    [switch]$DeleteDisks,
    [Parameter()]
    [switch]$DeleteNetworkResources,
    [Parameter()]
    [switch]$Force,
    [Parameter()]
    [switch]$BackupFirst,
    [Parameter()]
    [switch]$WaitForCompletion,
    [Parameter()]
    [ValidateRange(5, 120)]
    [int]$TimeoutMinutes = 30,
    [Parameter()]
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
# Global tracking variables
$script:DeletionResults = @()
$script:BackupResults = @()
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
function Get-VMDependencies {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$Name
    )
    try {
        Write-Host "Analyzing dependencies for VM: $Name" -ForegroundColor Yellow
        $vm = Get-AzVM -ResourceGroupName $ResourceGroup -Name $Name
        $dependencies = @{
            VM = $vm
            OSDisk = $null
            DataDisks = @()
            NetworkInterfaces = @()
            PublicIPs = @()
            AvailabilitySet = $null
            Dependencies = @()
        }
        # Get OS Disk
        if ($vm.StorageProfile.OsDisk.ManagedDisk) {
            $dependencies.OSDisk = @{
                Name = $vm.StorageProfile.OsDisk.Name
                Id = $vm.StorageProfile.OsDisk.ManagedDisk.Id
                Type = "Managed"
            }
        }
        # Get Data Disks
        foreach ($dataDisk in $vm.StorageProfile.DataDisks) {
            if ($dataDisk.ManagedDisk) {
                $dependencies.DataDisks += @{
                    Name = $dataDisk.Name
                    Id = $dataDisk.ManagedDisk.Id
                    Lun = $dataDisk.Lun
                    Type = "Managed"
                }
            }
        }
        # Get Network Interfaces
        foreach ($nicRef in $vm.NetworkProfile.NetworkInterfaces) {
            try {
                $nic = Get-AzNetworkInterface | Where-Object { $_.Id -eq $nicRef.Id }
                if ($nic) {
                    $nicInfo = @{
                        Name = $nic.Name
                        Id = $nic.Id
                        Primary = $nicRef.Primary
                        PublicIPs = @()
                    }
                    # Check for Public IPs
                    foreach ($ipConfig in $nic.IpConfigurations) {
                        if ($ipConfig.PublicIpAddress) {
                            $pip = Get-AzPublicIpAddress | Where-Object { $_.Id -eq $ipConfig.PublicIpAddress.Id }
                            if ($pip) {
                                $nicInfo.PublicIPs += @{
                                    Name = $pip.Name
                                    Id = $pip.Id
                                    IP = $pip.IpAddress
                                }
                                $dependencies.PublicIPs += $nicInfo.PublicIPs[-1]
                            }
                        }
                    }
                    $dependencies.NetworkInterfaces += $nicInfo
                
} catch {
                Write-Warning "Could not retrieve network interface: $($nicRef.Id)"
            }
        }
        # Get Availability Set
        if ($vm.AvailabilitySetReference) {
            try {
                $avSet = Get-AzAvailabilitySet | Where-Object { $_.Id -eq $vm.AvailabilitySetReference.Id }
                if ($avSet) {
                    $dependencies.AvailabilitySet = @{
                        Name = $avSet.Name
                        Id = $avSet.Id
                        VMCount = $avSet.VirtualMachinesReferences.Count
                    }
                
} catch {
                Write-Warning "Could not retrieve availability set information"
            }
        }
        return $dependencies
    }
    catch {
        throw "Failed to analyze dependencies for VM $Name : $_"
    }
}
function New-DiskSnapshot {
    [CmdletBinding(SupportsShouldProcess)]

        [object]$DiskInfo,
        [string]$VMName
    )
    try {
        $snapshotName = "snapshot-$VMName-$($DiskInfo.Name)-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "Creating snapshot: $snapshotName" -ForegroundColor Yellow
        if (-not $DryRun) {
            $disk = Get-AzDisk | Where-Object { $_.Id -eq $DiskInfo.Id }
            $snapshotConfig = New-AzSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $disk.Location
            $snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotConfig
            Write-Host "Snapshot created: $snapshotName" -ForegroundColor Green
            return @{
                Name = $snapshotName
                Id = $snapshot.Id
                DiskName = $DiskInfo.Name
                Success = $true
            }
        } else {
            Write-Host "DRY RUN: Would create snapshot: $snapshotName" -ForegroundColor Cyan
            return @{
                Name = $snapshotName
                DiskName = $DiskInfo.Name
                Success = $true
                DryRun = $true
            }
        
} catch {
        Write-Error "Failed to create snapshot for disk $($DiskInfo.Name): $_"
        return @{
            Name = $snapshotName
            DiskName = $DiskInfo.Name
            Success = $false
            Error = $_.Exception.Message
        }
    }
}
function Remove-VMSafely {
    [CmdletBinding(SupportsShouldProcess)]

        [string]$ResourceGroup,
        [string]$Name
    )
    $result = @{
        VMName = $Name
        StartTime = Get-Date
        Success = $false
        Error = $null
        Dependencies = $null
        BackupResults = @()
        DeletionSteps = @()
    }
    try {
        Write-Host "`nProcessing VM: $Name" -ForegroundColor Cyan
        Write-Host ("=" * 60) -ForegroundColor Gray
        # Get VM dependencies
        $dependencies = Get-VMDependencies -ResourceGroup $ResourceGroup -Name $Name
        $result.Dependencies = $dependencies
        # Display VM information
        Write-Host "VM Information:" -ForegroundColor Cyan
        Write-Host "Name: $($dependencies.VM.Name)"
        Write-Host "Location: $($dependencies.VM.Location)"
        Write-Host "Size: $($dependencies.VM.HardwareProfile.VmSize)"
        Write-Host "OS Disk: $($dependencies.OSDisk.Name)" -ForegroundColor $(if ($DeleteDisks) { 'Red' } else { 'Yellow' })
        Write-Host "Data Disks: $($dependencies.DataDisks.Count)" -ForegroundColor $(if ($DeleteDisks) { 'Red' } else { 'Yellow' })
        Write-Host "Network Interfaces: $($dependencies.NetworkInterfaces.Count)" -ForegroundColor $(if ($DeleteNetworkResources) { 'Red' } else { 'Yellow' })
        Write-Host "Public IPs: $($dependencies.PublicIPs.Count)" -ForegroundColor $(if ($DeleteNetworkResources) { 'Red' } else { 'Yellow' })
        # Create backups if requested
        if ($BackupFirst) {
            Write-Host "`nCreating disk snapshots..." -ForegroundColor Yellow
            # Backup OS disk
            if ($dependencies.OSDisk) {
                $backupResult = New-DiskSnapshot -DiskInfo $dependencies.OSDisk -VMName $Name
                $result.BackupResults += $backupResult
                $script:BackupResults += $backupResult
            }
            # Backup data disks
            foreach ($dataDisk in $dependencies.DataDisks) {
                $backupResult = New-DiskSnapshot -DiskInfo $dataDisk -VMName $Name
                $result.BackupResults += $backupResult
                $script:BackupResults += $backupResult
            }
        }
        # Delete VM
        Write-Host "`nDeleting Virtual Machine..." -ForegroundColor Red
        if ($PSCmdlet.ShouldProcess($Name, "Delete VM")) {
            if (-not $DryRun) {
                Remove-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Force
                Write-Host "VM deleted: $Name" -ForegroundColor Green
            } else {
                Write-Host "DRY RUN: Would delete VM: $Name" -ForegroundColor Cyan
            }
            $result.DeletionSteps += "VM: $Name"
        }
        # Delete associated resources if requested
        if ($DeleteDisks) {
            Write-Host "`nDeleting associated disks..." -ForegroundColor Red
            # Delete OS disk
            if ($dependencies.OSDisk) {
                Write-Host "Deleting OS disk: $($dependencies.OSDisk.Name)" -ForegroundColor Red
                if ($PSCmdlet.ShouldProcess($dependencies.OSDisk.Name, "Delete OS Disk")) {
                    if (-not $DryRun) {
                        Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $dependencies.OSDisk.Name -Force
                        Write-Host "OS disk deleted: $($dependencies.OSDisk.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "DRY RUN: Would delete OS disk: $($dependencies.OSDisk.Name)" -ForegroundColor Cyan
                    }
                    $result.DeletionSteps += "OS Disk: $($dependencies.OSDisk.Name)"
                }
            }
            # Delete data disks
            foreach ($dataDisk in $dependencies.DataDisks) {
                Write-Host "Deleting data disk: $($dataDisk.Name)" -ForegroundColor Red
                if ($PSCmdlet.ShouldProcess($dataDisk.Name, "Delete Data Disk")) {
                    if (-not $DryRun) {
                        Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $dataDisk.Name -Force
                        Write-Host "Data disk deleted: $($dataDisk.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "DRY RUN: Would delete data disk: $($dataDisk.Name)" -ForegroundColor Cyan
                    }
                    $result.DeletionSteps += "Data Disk: $($dataDisk.Name)"
                }
            }
        }
        if ($DeleteNetworkResources) {
            Write-Host "`nDeleting network resources..." -ForegroundColor Red
            # Delete Public IPs
            foreach ($pip in $dependencies.PublicIPs) {
                Write-Host "Deleting public IP: $($pip.Name)" -ForegroundColor Red
                if ($PSCmdlet.ShouldProcess($pip.Name, "Delete Public IP")) {
                    if (-not $DryRun) {
                        Remove-AzPublicIpAddress -ResourceGroupName $ResourceGroup -Name $pip.Name -Force
                        Write-Host "Public IP deleted: $($pip.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "DRY RUN: Would delete public IP: $($pip.Name)" -ForegroundColor Cyan
                    }
                    $result.DeletionSteps += "Public IP: $($pip.Name)"
                }
            }
            # Delete Network Interfaces
            foreach ($nic in $dependencies.NetworkInterfaces) {
                Write-Host "Deleting network interface: $($nic.Name)" -ForegroundColor Red
                if ($PSCmdlet.ShouldProcess($nic.Name, "Delete Network Interface")) {
                    if (-not $DryRun) {
                        Remove-AzNetworkInterface -ResourceGroupName $ResourceGroup -Name $nic.Name -Force
                        Write-Host "Network interface deleted: $($nic.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "DRY RUN: Would delete network interface: $($nic.Name)" -ForegroundColor Cyan
                    }
                    $result.DeletionSteps += "NIC: $($nic.Name)"
                }
            }
        }
        $result.Success = $true
        Write-Host "VM deletion completed: $Name" -ForegroundColor Green
    }
    catch {
        $result.Error = $_.Exception.Message
        $result.Success = $false
        Write-Host "VM deletion failed: $Name - $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
    }
    return $result
}
function New-DeletionReport {
    [CmdletBinding(SupportsShouldProcess)]
[object[]]$Results)
    $report = @{
        Timestamp = Get-Date
        TotalVMs = $Results.Count
        Successful = ($Results | Where-Object { $_.Success }).Count
        Failed = ($Results | Where-Object { -not $_.Success }).Count
        BackupsCreated = $script:BackupResults.Count
        Details = $Results
    }
    Write-Host "`nDeletion Operation Summary" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host "Total VMs: $($report.TotalVMs)"
    Write-Host "Successful: $($report.Successful)" -ForegroundColor Green
    Write-Host "Failed: $($report.Failed)" -ForegroundColor $(if ($report.Failed -gt 0) { 'Red' } else { 'Green' })
    if ($BackupFirst) {
        $successfulBackups = ($script:BackupResults | Where-Object { $_.Success }).Count
        Write-Host "Backups Created: $successfulBackups/$($report.BackupsCreated)" -ForegroundColor Cyan
    }
    if ($report.Failed -gt 0) {
        Write-Host "`nFailed Deletions:" -ForegroundColor Red
        $Results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $($_.VMName): $($_.Error)" -ForegroundColor Red
        }
    }
    if ($DryRun) {
        Write-Host "`nDRY RUN COMPLETED - No actual deletions were performed" -ForegroundColor Yellow
    }
    return $report
}
# Main execution
Write-Host "`nAzure VM Deletion Tool" -ForegroundColor Red
Write-Host ("=" * 50) -ForegroundColor Red
Write-Host "WARNING: This tool permanently deletes Azure resources!" -ForegroundColor Yellow
if ($DryRun) {
    Write-Host "DRY RUN MODE - No actual deletions will be performed" -ForegroundColor Cyan
}
# Test Azure connection
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
# Prepare VM list
$vmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
# Safety confirmation
if (-not $Force -and -not $DryRun) {
    $vmCount = $vmList.Count
    $vmText = if ($vmCount -eq 1) { "VM" } else { "$vmCount VMs" }
    $action = "DELETE"
    Write-Host "`n  DESTRUCTIVE OPERATION WARNING " -ForegroundColor Red
    Write-Host "About to $action $vmText in resource group '$ResourceGroupName':" -ForegroundColor Red
    foreach ($vm in $vmList) {
        Write-Host "  - $vm" -ForegroundColor White
    }
    Write-Host "`nAdditional resources that will be deleted:" -ForegroundColor Yellow
    Write-Host "Disks: $(if ($DeleteDisks) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($DeleteDisks) { 'Red' } else { 'Green' })
    Write-Host "Network Resources: $(if ($DeleteNetworkResources) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($DeleteNetworkResources) { 'Red' } else { 'Green' })
    Write-Host "Backup First: $(if ($BackupFirst) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($BackupFirst) { 'Green' } else { 'Yellow' })
    Write-Host "`n  THIS OPERATION CANNOT BE UNDONE! " -ForegroundColor Red
    $confirmation = Read-Host "`nType 'DELETE' to confirm this destructive operation"
    if ($confirmation -ne 'DELETE') {
        Write-Host "Operation cancelled - confirmation not provided" -ForegroundColor Yellow
        exit 0
    }
}
# Process VMs
Write-Host "`nStarting VM deletion operations..." -ForegroundColor Red
foreach ($vm in $vmList) {
    try {
        $result = Remove-VMSafely -ResourceGroup $ResourceGroupName -Name $vm
        $script:DeletionResults += $result
    }
    catch {
        $errorResult = @{
            VMName = $vm
            StartTime = Get-Date
            EndTime = Get-Date
            Success = $false
            Error = $_.Exception.Message
        }
        $script:DeletionResults += $errorResult
    }
}
# Generate report
$report = New-DeletionReport -Results $script:DeletionResults
# Display backup information
if ($BackupFirst -and $script:BackupResults.Count -gt 0) {
    Write-Host "`nBackup Snapshots Created:" -ForegroundColor Cyan
    $script:BackupResults | Where-Object { $_.Success } | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Green
    }
}
# Exit with appropriate code
$exitCode = if ($report.Failed -gt 0) { 1 } else { 0 }
Write-Host "`nOperation completed!" -ForegroundColor $(if ($exitCode -eq 0) { 'Green' } else { 'Yellow' })
exit $exitCode


