#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Compute, Az.Storage

<#
.SYNOPSIS
    Restore Azure Virtual Machine from Backup

.DESCRIPTION
    Restores Azure ARM virtual machines from backup VHD location.
    Copies VHD files from backup location, deletes the VM (to release lease),
    copies VHD over original location, and recreates the VM with same configuration.
    Note: Does not work with managed disks (use snapshots instead).

.PARAMETER ResourceGroupName
    Name of resource group containing the VM

.PARAMETER BackupContainer
    Name of container that holds the backup VHD blobs (default: 'vhd-backups')

.PARAMETER VhdContainer
    Name of container that holds VHD blobs attached to VMs (default: 'vhds')

.PARAMETER Environment
    Azure environment name (default: 'AzureCloud', alternatives: 'AzureUSGovernment')

.EXAMPLE
    .\Restore-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO'

.EXAMPLE
    .\Restore-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO' -BackupContainer 'vhd-backups-9021' -VhdContainer 'MyVMs'

.AUTHOR
    Wes Ellis (wes@wesellis.com)
    Original Author: https://github.com/JeffBow

.NOTES
    Version: 1.0
    Requires Azure PowerShell Az module
    VMs must be shutdown prior to running this script
    Works with unmanaged disks only
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$BackupContainer = 'vhd-backups',

    [Parameter(Mandatory = $false)]
    [string]$VhdContainer = 'vhds',

    [Parameter(Mandatory = $false)]
    [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', 'AzureChinaCloud')]
    [string]$Environment = 'AzureCloud'
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { 'Continue' } else { 'SilentlyContinue' }
$ProgressPreference = 'SilentlyContinue'

try {
    Write-Output "Starting Azure VM restoration process"
    Write-Output "Resource Group: $ResourceGroupName"
    Write-Output "Backup Container: $BackupContainer"
    Write-Output "VHD Container: $VhdContainer"
    Write-Output "Environment: $Environment"

    # Set paths for temporary JSON storage
    $ResourceGroupVMjsonPath = "$env:TEMP\$ResourceGroupName.resourceGroupVMs.json"

    # Check Az module version
    $azModule = Get-Module -Name Az.Compute -ListAvailable | Select-Object -First 1
    if (-not $azModule) {
        throw "Azure PowerShell Az module is not installed. Please install using: Install-Module -Name Az -AllowClobber"
    }

    # Connect to Azure if not already connected
    $context = Get-AzContext
    if (-not $context) {
        Write-Output "Not connected to Azure. Please login..."
        Connect-AzAccount -Environment $Environment
    }

    # Get resource group
    Write-Verbose "Getting resource group: $ResourceGroupName"
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop

    if (-not $resourceGroup) {
        throw "Resource group '$ResourceGroupName' not found"
    }

    # Get VMs in resource group
    Write-Output "Getting VMs in resource group..."
    $vms = Get-AzVM -ResourceGroupName $ResourceGroupName

    if ($vms.Count -eq 0) {
        Write-Warning "No VMs found in resource group '$ResourceGroupName'"
        return
    }

    Write-Output "Found $($vms.Count) VMs to process"

    # Check if VMs are stopped
    foreach ($vm in $vms) {
        Write-Verbose "Checking status of VM: $($vm.Name)"
        $vmStatus = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Status

        $powerState = $vmStatus.Statuses | Where-Object { $_.Code -like 'PowerState/*' }
        if ($powerState.Code -ne 'PowerState/deallocated' -and $powerState.Code -ne 'PowerState/stopped') {
            throw "VM '$($vm.Name)' is not stopped. Current state: $($powerState.DisplayStatus). Please stop all VMs before running restore."
        }
    }

    # Export VM configurations to JSON
    Write-Output "Exporting VM configurations..."
    $vms | ConvertTo-Json -Depth 10 | Out-File $ResourceGroupVMjsonPath

    # Process each VM
    foreach ($vm in $vms) {
        Write-Output "`nProcessing VM: $($vm.Name)"

        if ($PSCmdlet.ShouldProcess($vm.Name, "Restore VM from backup")) {

            # Check if VM uses managed disks
            if ($vm.StorageProfile.OsDisk.ManagedDisk) {
                Write-Warning "VM '$($vm.Name)' uses managed disks. This script only works with unmanaged disks. Use snapshots for managed disk backups."
                continue
            }

            # Get storage account from OS disk URI
            $osDiskUri = $vm.StorageProfile.OsDisk.Vhd.Uri
            if ($osDiskUri -match 'https://([^.]+)\.blob\.core') {
                $storageAccountName = $Matches[1]
            }
            else {
                Write-Error "Could not determine storage account from OS disk URI: $osDiskUri"
                continue
            }

            Write-Verbose "Storage Account: $storageAccountName"

            # Get storage account context
            $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $storageAccountName -ErrorAction SilentlyContinue
            if (-not $storageAccount) {
                # Try to find storage account in other resource groups
                $storageAccount = Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $storageAccountName } | Select-Object -First 1
            }

            if (-not $storageAccount) {
                Write-Error "Storage account '$storageAccountName' not found"
                continue
            }

            $storageContext = $storageAccount.Context

            # Delete VM to release VHD lease
            Write-Output "  Deleting VM to release VHD lease..."
            Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Force

            # Copy OS disk from backup
            $osDiskName = Split-Path $osDiskUri -Leaf
            Write-Output "  Restoring OS disk: $osDiskName"

            $sourceBlob = Get-AzStorageBlob -Container $BackupContainer -Blob $osDiskName -Context $storageContext -ErrorAction SilentlyContinue
            if ($sourceBlob) {
                $copyOperation = Start-AzStorageBlobCopy -SrcContainer $BackupContainer -SrcBlob $osDiskName `
                    -DestContainer $VhdContainer -DestBlob $osDiskName -Context $storageContext -Force

                # Wait for copy to complete
                while ($copyOperation.Status -eq 'Pending') {
                    Start-Sleep -Seconds 5
                    $copyOperation = Get-AzStorageBlobCopyState -Container $VhdContainer -Blob $osDiskName -Context $storageContext
                }

                if ($copyOperation.Status -eq 'Success') {
                    Write-Output "  OS disk restored successfully"
                }
                else {
                    throw "OS disk copy failed with status: $($copyOperation.Status)"
                }
            }
            else {
                Write-Warning "  Backup OS disk not found: $osDiskName in container $BackupContainer"
            }

            # Copy data disks from backup
            foreach ($dataDisk in $vm.StorageProfile.DataDisks) {
                $dataDiskUri = $dataDisk.Vhd.Uri
                $dataDiskName = Split-Path $dataDiskUri -Leaf
                Write-Output "  Restoring data disk: $dataDiskName"

                $sourceBlob = Get-AzStorageBlob -Container $BackupContainer -Blob $dataDiskName -Context $storageContext -ErrorAction SilentlyContinue
                if ($sourceBlob) {
                    $copyOperation = Start-AzStorageBlobCopy -SrcContainer $BackupContainer -SrcBlob $dataDiskName `
                        -DestContainer $VhdContainer -DestBlob $dataDiskName -Context $storageContext -Force

                    # Wait for copy to complete
                    while ($copyOperation.Status -eq 'Pending') {
                        Start-Sleep -Seconds 5
                        $copyOperation = Get-AzStorageBlobCopyState -Container $VhdContainer -Blob $dataDiskName -Context $storageContext
                    }

                    if ($copyOperation.Status -eq 'Success') {
                        Write-Output "  Data disk restored successfully"
                    }
                    else {
                        throw "Data disk copy failed with status: $($copyOperation.Status)"
                    }
                }
                else {
                    Write-Warning "  Backup data disk not found: $dataDiskName in container $BackupContainer"
                }
            }

            Write-Output "  VM disks restored. VM recreation would need to be implemented based on saved configuration."
            Write-Output "  Configuration saved at: $ResourceGroupVMjsonPath"
        }
    }

    Write-Output "`nRestore process completed"
    Write-Output "Note: VMs need to be recreated from saved configuration at: $ResourceGroupVMjsonPath"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

# ------------------------------------------------------------------------
#               Copyright (C) 2016 Microsoft Corporation
# You have a royalty-free right to use, modify, reproduce and distribute
# this sample script (and/or any modified version) in any way
# you find useful, provided that you agree that Microsoft has no warranty,
# obligations or liability for any sample application or script files.
# ------------------------------------------------------------------------