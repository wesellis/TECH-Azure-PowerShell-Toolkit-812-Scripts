#Requires -Version 7.0

<#`n.SYNOPSIS
    Overall

.DESCRIPTION
    Overall operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    General notes
Restore an Azure VM
There's an important difference between the restoring a VM using the Azure portal and restoring a VM using PowerShell. With PowerShell, the restore operation is complete once the disks and configuration information from the recovery point are created. The restore operation doesn't create the virtual machine. To create a virtual machine from disk, see the section, Create the VM from restored disks. If you don't want to restore the entire VM, but want to restore or recover a few files from an Azure VM backup, refer to the file recovery section.
    To restore backup data, identify the backed-up item and the recovery point that holds the point-in-time data. Use Restore-AzRecoveryServicesBackupItem to restore data from the vault to your account.
The basic steps to restore an Azure VM are:
Select the VM.
Choose a recovery point.
Restore the disks.
Create the VM from stored disks.

