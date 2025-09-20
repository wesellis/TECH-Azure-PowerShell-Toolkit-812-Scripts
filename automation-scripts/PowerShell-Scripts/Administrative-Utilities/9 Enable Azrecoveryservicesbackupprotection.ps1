<#
.SYNOPSIS
    Enable Azrecoveryservicesbackupprotection

.DESCRIPTION
    Enable Azrecoveryservicesbackupprotection operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
    Short description
    Long description
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
    WorkloadName     Operation            Status               StartTime                 EndTime                   JobID
------------     ---------            ------               ---------                 -------                   -----
outlook1         ConfigureBackup      Completed            2020-12-12 9:55:55 PM     2020-12-12 9:56:26 PM     423b65eb-fca8-48b5-8394-2...
    General notes
    Enable protection
Once you've defined the protection policy, you still must enable the policy for an item. Use Enable-AzRecoveryServicesBackupProtection to enable protection. Enabling protection requires two objects - the item and the policy. Once the policy has been associated with the vault, the backup workflow is triggered at the time defined in the policy schedule.
The following examples enable protection for the item, V2VM, using the policy, NewPolicy. The examples differ based on whether the VM is encrypted, and what type of encryption.
$CustomerName = 'CanPrintEquip'
$VMName = 'Outlook1'
$ResourceGroupName = -join ("$CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join (" $VMName" , "ARSV1" )
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $ResourceGroupName -Name $Vaultname
$getAzRecoveryServicesBackupProtectionPolicySplat = @{
    Name = "DefaultPolicy"
    VaultId = $targetVault.ID
}
$pol = Get-AzRecoveryServicesBackupProtectionPolicy -ErrorAction Stop @getAzRecoveryServicesBackupProtectionPolicySplat
$enableAzRecoveryServicesBackupProtectionSplat = @{
    Policy = $pol
    Name = $VMName
    ResourceGroupName = $ResourceGroupName
    VaultId = $targetVault.ID
}
Enable-AzRecoveryServicesBackupProtection @enableAzRecoveryServicesBackupProtectionSplat

