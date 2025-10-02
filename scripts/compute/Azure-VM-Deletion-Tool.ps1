#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Delete VMs and optionally their resources

.DESCRIPTION

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
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
$script:DeletionResults = @()
$script:BackupResults = @()
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
function Get-VMDependencies {
    [string]$ResourceGroup,
        [string]$Name
    )
    try {
        Write-Host "Analyzing dependencies for VM: $Name" -ForegroundColor Green
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
        if ($vm.StorageProfile.OsDisk.ManagedDisk) {
            $dependencies.OSDisk = @{
                Name = $vm.StorageProfile.OsDisk.Name
                Id = $vm.StorageProfile.OsDisk.ManagedDisk.Id
                Type = "Managed"
            }
        }
        foreach ($DataDisk in $vm.StorageProfile.DataDisks) {
            if ($DataDisk.ManagedDisk) {
                $dependencies.DataDisks += @{
                    Name = $DataDisk.Name
                    Id = $DataDisk.ManagedDisk.Id
                    Lun = $DataDisk.Lun
                    Type = "Managed"
                }
            }
        }
        foreach ($NicRef in $vm.NetworkProfile.NetworkInterfaces) {
            try {
                $nic = Get-AzNetworkInterface | Where-Object { $_.Id -eq $NicRef.Id }
                if ($nic) {
                    $NicInfo = @{
                        Name = $nic.Name
                        Id = $nic.Id
                        Primary = $NicRef.Primary
                        PublicIPs = @()
                    }
                    foreach ($IpConfig in $nic.IpConfigurations) {
                        if ($IpConfig.PublicIpAddress) {
                            $pip = Get-AzPublicIpAddress | Where-Object { $_.Id -eq $IpConfig.PublicIpAddress.Id }
                            if ($pip) {
                                $NicInfo.PublicIPs += @{
                                    Name = $pip.Name
                                    Id = $pip.Id
                                    IP = $pip.IpAddress
                                }
                                $dependencies.PublicIPs += $NicInfo.PublicIPs[-1]
                            }
                        }
                    }
                    $dependencies.NetworkInterfaces += $NicInfo

} catch {
                Write-Warning "Could not retrieve network interface: $($NicRef.Id)"
            }
        }
        if ($vm.AvailabilitySetReference) {
            try {
                $AvSet = Get-AzAvailabilitySet | Where-Object { $_.Id -eq $vm.AvailabilitySetReference.Id }
                if ($AvSet) {
                    $dependencies.AvailabilitySet = @{
                        Name = $AvSet.Name
                        Id = $AvSet.Id
                        VMCount = $AvSet.VirtualMachinesReferences.Count
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
    [object]$DiskInfo,
        [string]$VMName
    )
    try {
        $SnapshotName = "snapshot-$VMName-$($DiskInfo.Name)-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "Creating snapshot: $SnapshotName" -ForegroundColor Green
        if (-not $DryRun) {
            $disk = Get-AzDisk | Where-Object { $_.Id -eq $DiskInfo.Id }
            $SnapshotConfig = New-AzSnapshotConfig -SourceUri $disk.Id -CreateOption Copy -Location $disk.Location
            $snapshot = New-AzSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $SnapshotName -Snapshot $SnapshotConfig
            Write-Host "Snapshot created: $SnapshotName" -ForegroundColor Green
            return @{
                Name = $SnapshotName
                Id = $snapshot.Id
                DiskName = $DiskInfo.Name
                Success = $true
            }
        } else {
            Write-Host "DRY RUN: Would create snapshot: $SnapshotName" -ForegroundColor Green
            return @{
                Name = $SnapshotName
                DiskName = $DiskInfo.Name
                Success = $true
                DryRun = $true
            }

} catch {
        Write-Error "Failed to create snapshot for disk $($DiskInfo.Name): $_"
        return @{
            Name = $SnapshotName
            DiskName = $DiskInfo.Name
            Success = $false
            Error = $_.Exception.Message
        }
    }
}
function Remove-VMSafely {
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
        Write-Host "`nProcessing VM: $Name" -ForegroundColor Green
        Write-Host ("=" * 60) -ForegroundColor Gray
        $dependencies = Get-VMDependencies -ResourceGroup $ResourceGroup -Name $Name
        $result.Dependencies = $dependencies
        Write-Host "VM Information:" -ForegroundColor Green
        Write-Output "Name: $($dependencies.VM.Name)"
        Write-Output "Location: $($dependencies.VM.Location)"
        Write-Output "Size: $($dependencies.VM.HardwareProfile.VmSize)"
        Write-Output "OS Disk: $($dependencies.OSDisk.Name)" -ForegroundColor $(if ($DeleteDisks) { 'Red' } else { 'Yellow' })
        Write-Output "Data Disks: $($dependencies.DataDisks.Count)" -ForegroundColor $(if ($DeleteDisks) { 'Red' } else { 'Yellow' })
        Write-Output "Network Interfaces: $($dependencies.NetworkInterfaces.Count)" -ForegroundColor $(if ($DeleteNetworkResources) { 'Red' } else { 'Yellow' })
        Write-Output "Public IPs: $($dependencies.PublicIPs.Count)" -ForegroundColor $(if ($DeleteNetworkResources) { 'Red' } else { 'Yellow' })
        if ($BackupFirst) {
            Write-Host "`nCreating disk snapshots..." -ForegroundColor Green
            if ($dependencies.OSDisk) {
                $BackupResult = New-DiskSnapshot -DiskInfo $dependencies.OSDisk -VMName $Name
                $result.BackupResults += $BackupResult
                $script:BackupResults += $BackupResult
            }
            foreach ($DataDisk in $dependencies.DataDisks) {
                $BackupResult = New-DiskSnapshot -DiskInfo $DataDisk -VMName $Name
                $result.BackupResults += $BackupResult
                $script:BackupResults += $BackupResult
            }
        }
        Write-Host "`nDeleting Virtual Machine..." -ForegroundColor Green
        if ($PSCmdlet.ShouldProcess($Name, "Delete VM")) {
            if (-not $DryRun) {
                Remove-AzVM -ResourceGroupName $ResourceGroup -Name $Name -Force
                Write-Host "VM deleted: $Name" -ForegroundColor Green
            } else {
                Write-Host "DRY RUN: Would delete VM: $Name" -ForegroundColor Green
            }
            $result.DeletionSteps += "VM: $Name"
        }
        if ($DeleteDisks) {
            Write-Host "`nDeleting associated disks..." -ForegroundColor Green
            if ($dependencies.OSDisk) {
                Write-Host "Deleting OS disk: $($dependencies.OSDisk.Name)" -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess($dependencies.OSDisk.Name, "Delete OS Disk")) {
                    if (-not $DryRun) {
                        Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $dependencies.OSDisk.Name -Force
                        Write-Host "OS disk deleted: $($dependencies.OSDisk.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "DRY RUN: Would delete OS disk: $($dependencies.OSDisk.Name)" -ForegroundColor Green
                    }
                    $result.DeletionSteps += "OS Disk: $($dependencies.OSDisk.Name)"
                }
            }
            foreach ($DataDisk in $dependencies.DataDisks) {
                Write-Host "Deleting data disk: $($DataDisk.Name)" -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess($DataDisk.Name, "Delete Data Disk")) {
                    if (-not $DryRun) {
                        Remove-AzDisk -ResourceGroupName $ResourceGroup -DiskName $DataDisk.Name -Force
                        Write-Host "Data disk deleted: $($DataDisk.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "DRY RUN: Would delete data disk: $($DataDisk.Name)" -ForegroundColor Green
                    }
                    $result.DeletionSteps += "Data Disk: $($DataDisk.Name)"
                }
            }
        }
        if ($DeleteNetworkResources) {
            Write-Host "`nDeleting network resources..." -ForegroundColor Green
            foreach ($pip in $dependencies.PublicIPs) {
                Write-Host "Deleting public IP: $($pip.Name)" -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess($pip.Name, "Delete Public IP")) {
                    if (-not $DryRun) {
                        Remove-AzPublicIpAddress -ResourceGroupName $ResourceGroup -Name $pip.Name -Force
                        Write-Host "Public IP deleted: $($pip.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "DRY RUN: Would delete public IP: $($pip.Name)" -ForegroundColor Green
                    }
                    $result.DeletionSteps += "Public IP: $($pip.Name)"
                }
            }
            foreach ($nic in $dependencies.NetworkInterfaces) {
                Write-Host "Deleting network interface: $($nic.Name)" -ForegroundColor Green
                if ($PSCmdlet.ShouldProcess($nic.Name, "Delete Network Interface")) {
                    if (-not $DryRun) {
                        Remove-AzNetworkInterface -ResourceGroupName $ResourceGroup -Name $nic.Name -Force
                        Write-Host "Network interface deleted: $($nic.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "DRY RUN: Would delete network interface: $($nic.Name)" -ForegroundColor Green
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
        Write-Host "VM deletion failed: $Name - $($_.Exception.Message)" -ForegroundColor Green
    }
    finally {
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
    }
    return $result
}
function New-DeletionReport {
    [object[]]$Results)
    $report = @{
        Timestamp = Get-Date
        TotalVMs = $Results.Count
        Successful = ($Results | Where-Object { $_.Success }).Count
        Failed = ($Results | Where-Object { -not $_.Success }).Count
        BackupsCreated = $script:BackupResults.Count
        Details = $Results
    }
    Write-Host "`nDeletion Operation Summary" -ForegroundColor Green
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Output "Total VMs: $($report.TotalVMs)"
    Write-Host "Successful: $($report.Successful)" -ForegroundColor Green
    Write-Output "Failed: $($report.Failed)" -ForegroundColor $(if ($report.Failed -gt 0) { 'Red' } else { 'Green' })
    if ($BackupFirst) {
        $SuccessfulBackups = ($script:BackupResults | Where-Object { $_.Success }).Count
        Write-Host "Backups Created: $SuccessfulBackups/$($report.BackupsCreated)" -ForegroundColor Green
    }
    if ($report.Failed -gt 0) {
        Write-Host "`nFailed Deletions:" -ForegroundColor Green
        $Results | Where-Object { -not $_.Success } | ForEach-Object {
            Write-Host "  - $($_.VMName): $($_.Error)" -ForegroundColor Green
        }
    }
    if ($DryRun) {
        Write-Host "`nDRY RUN COMPLETED - No actual deletions were performed" -ForegroundColor Green
    }
    return $report
}
Write-Host "`nAzure VM Deletion Tool" -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Red
Write-Host "WARNING: This tool permanently deletes Azure resources!" -ForegroundColor Green
if ($DryRun) {
    Write-Host "DRY RUN MODE - No actual deletions will be performed" -ForegroundColor Green
}
if (-not (Test-AzureConnection)) {
    throw "Azure connection required. Please run Connect-AzAccount first."
}
Write-Host "Connected to subscription: $((Get-AzContext).Subscription.Name)" -ForegroundColor Green
$VmList = if ($PSCmdlet.ParameterSetName -eq 'Multiple') { $VmNames } else { @($VmName) }
if (-not $Force -and -not $DryRun) {
    $VmCount = $VmList.Count
    $VmText = if ($VmCount -eq 1) { "VM" } else { "$VmCount VMs" }
    $action = "DELETE"
    Write-Host "`n  DESTRUCTIVE OPERATION WARNING " -ForegroundColor Green
    Write-Host "About to $action $VmText in resource group '$ResourceGroupName':" -ForegroundColor Green
    foreach ($vm in $VmList) {
        Write-Host "  - $vm" -ForegroundColor Green
    }
    Write-Host "`nAdditional resources that will be deleted:" -ForegroundColor Green
    Write-Output "Disks: $(if ($DeleteDisks) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($DeleteDisks) { 'Red' } else { 'Green' })
    Write-Output "Network Resources: $(if ($DeleteNetworkResources) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($DeleteNetworkResources) { 'Red' } else { 'Green' })
    Write-Output "Backup First: $(if ($BackupFirst) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($BackupFirst) { 'Green' } else { 'Yellow' })
    Write-Host "`n  THIS OPERATION CANNOT BE UNDONE! " -ForegroundColor Green
    $confirmation = Read-Host "`nType 'DELETE' to confirm this destructive operation"
    if ($confirmation -ne 'DELETE') {
        Write-Host "Operation cancelled - confirmation not provided" -ForegroundColor Green
        exit 0
    }
}
Write-Host "`nStarting VM deletion operations..." -ForegroundColor Green
foreach ($vm in $VmList) {
    try {
        $result = Remove-VMSafely -ResourceGroup $ResourceGroupName -Name $vm
        $script:DeletionResults += $result
    }
    catch {
        $ErrorResult = @{
            VMName = $vm
            StartTime = Get-Date
            EndTime = Get-Date
            Success = $false
            Error = $_.Exception.Message
        }
        $script:DeletionResults += $ErrorResult
    }
}
$report = New-DeletionReport -Results $script:DeletionResults
if ($BackupFirst -and $script:BackupResults.Count -gt 0) {
    Write-Host "`nBackup Snapshots Created:" -ForegroundColor Green
    $script:BackupResults | Where-Object { $_.Success } | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Green
    }
}
$ExitCode = if ($report.Failed -gt 0) { 1 } else { 0 }
Write-Output "`nOperation completed!" -ForegroundColor $(if ($ExitCode -eq 0) { 'Green' } else { 'Yellow' })
exit $ExitCode



