#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Module Az.Resources
<#`n.SYNOPSIS
    Backup Azurermvm
.DESCRIPTION
    Backup Azurermvm operation


    Author: Wes Ellis (wes@wesellis.com)
    Backup Azurermvm
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    Copies VHD blobs attached to each VM in a resource group to a designated backup container.
    Does not work with VMs configured with managed disks because they allow snapshots.
    Requires AzureRM module version 4.2.1 or later.
   Copies VHD blobs from each VM in a resource group to the vhd-backups container or other container name
   specified in the -BackupContainer parameter
   VMs must be shutdown prior to running this script. It will halt if they are still running.
   .\Backup-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO'
   .\Backup-AzureRMvm.ps1 -ResourceGroupName 'CONTOSO' -BackupContainer 'vhd-backups-9021'
.PARAMETER -ResourceGroupName [string]
  Name of resource group being copied
.PARAMETER -BackupContainer [string]
  Name of container that will hold the backup VHD blobs
.PARAMETER -Environment [string]
  Name of Environment e.g. AzureUSGovernment.  Defaults to AzureCloud
    Original Author:   https://github.com/JeffBow
 ------------------------------------------------------------------------
               Copyright (C) 2017 Microsoft Corporation
 You have a royalty-free right to use, modify, reproduce and distribute
 this sample script (and/or any modified version) in any way
 you find useful, provided that you agree that Microsoft has no warranty,
 obligations or liability for any sample application or script files.
 ------------------------------------------------------------------------
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter(ValueFromPipeline)]`n    $BackupContainer= 'vhd-backups',
    [Parameter(ValueFromPipeline)]`n    $Environment= "AzureCloud"
)
$ProgressPreference = 'SilentlyContinue'
if ((Get-Module -ErrorAction Stop AzureRM).Version -lt " 4.2.1" ) {
   Write-warning "Old version of Azure PowerShell module  $((Get-Module -ErrorAction Stop AzureRM).Version.ToString()) detected.  Minimum of 4.2.1 required. Run Update-Module AzureRM"
   BREAK
}