<#
.SYNOPSIS
    Set Azrecoveryservicesvaultcontext(Deprecated)

.DESCRIPTION
    Set Azrecoveryservicesvaultcontext(Deprecated) operation
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
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
    Description
The Set-AzRecoveryServicesVaultContext -ErrorAction Stop cmdlet sets the vault context for Azure Site Recovery services.
Warning: This cmdlet is being deprecated in a future breaking change release. There will be no replacement for it. Please use the -VaultId parameter in all Recovery Services commands going forward.
    Use a Recovery Services vault to protect your virtual machines. Before you apply the protection, set the vault context (the type of data protected in the vault), and verify the protection policy. The protection policy is the schedule when the backup jobs run, and how long each backup snapshot is retained.
Set vault context
Before enabling protection on a VM, use Set-AzRecoveryServicesVaultContext -ErrorAction Stop to set the vault context. Once the vault context is set, it applies to all subsequent cmdlets. The following example sets the vault context for the vault, testvault.
$CustomerName = 'CanPrintEquip'
$VMName = 'Outlook1'
$ResourceGroupName = -join (" $CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join (" $VMName" , "ARSV1" )
$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Vaultname
}
Get-AzRecoveryServicesVault -ErrorAction Stop @getAzRecoveryServicesVaultSplat | Set-AzRecoveryServicesVaultContext -ErrorAction Stop

