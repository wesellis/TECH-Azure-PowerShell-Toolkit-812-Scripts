#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    9 Enable Azrecoveryservicesbackupprotection

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 9 Enable Azrecoveryservicesbackupprotection

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS
    Short description
.DESCRIPTION
    Long description
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)

    WorkloadName     Operation            Status               StartTime                 EndTime                   JobID
------------     ---------            ------               ---------                 -------                   -----
outlook1         ConfigureBackup      Completed            2020-12-12 9:55:55 PM     2020-12-12 9:56:26 PM     423b65eb-fca8-48b5-8394-2... 
.NOTES
    General notes

    Enable protection
Once you've defined the protection policy, you still must enable the policy for an item. Use Enable-AzRecoveryServicesBackupProtection to enable protection. Enabling protection requires two objects - the item and the policy. Once the policy has been associated with the vault, the backup workflow is triggered at the time defined in the policy schedule.

The following examples enable protection for the item, V2VM, using the policy, NewPolicy. The examples differ based on whether the VM is encrypted, and what type of encryption.



$WECustomerName = 'CanPrintEquip'
$WEVMName = 'Outlook1'
$WEResourceGroupName = -join ("$WECustomerName" , " _Outlook" , " _RG" )

$WEVaultname = -join (" $WEVMName" , " ARSV1" )

$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $WEResourceGroupName -Name $WEVaultname


$getAzRecoveryServicesBackupProtectionPolicySplat = @{
    Name = " DefaultPolicy"
    VaultId = $targetVault.ID
}
; 
$pol = Get-AzRecoveryServicesBackupProtectionPolicy -ErrorAction Stop @getAzRecoveryServicesBackupProtectionPolicySplat
; 
$enableAzRecoveryServicesBackupProtectionSplat = @{
    Policy = $pol
    Name = $WEVMName
    ResourceGroupName = $WEResourceGroupName
    VaultId = $targetVault.ID
}

Enable-AzRecoveryServicesBackupProtection @enableAzRecoveryServicesBackupProtectionSplat

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
