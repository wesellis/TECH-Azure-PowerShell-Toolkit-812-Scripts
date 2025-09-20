#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    New Azrecoveryservicesvault

.DESCRIPTION
    New Azrecoveryservicesvault operation
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
    Name              : Outlook1ARSV1
ID                : /subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/resourceGroups/CanPrintEquip_Outlook_RG/providers/Microsoft.RecoveryServi
                    ces/vaults/Outlook1ARSV1
Type              : Microsoft.RecoveryServices/vaults
Location          : canadacentral
ResourceGroupName : CanPrintEquip_Outlook_RG
SubscriptionId    : 408a6c03-bd25-471b-ae84-cf82b3dff420
Properties        : Microsoft.Azure.Commands.RecoveryServices.ARSVaultProperties
    General notes
    You will get the vague error below if you have any illegel or imporper or invalid characters in any of your variables specifially the ARS Vault name like under score _ will throw the following error
    New-AzRecoveryServicesVault -ErrorAction Stop : Operation failed.
ClientRequestId: 7441125a-cac5-4a2d-92a0-05e3cd327b24-2020-12-12 06:08:34Z-P
One or more errors occurred.
At C:\Users\Abdullah.Ollivierre\AzureRepos2\Azure\Migrating_VM_VNETA-to_VNETB\2-New-AzRecoveryServicesVault.ps1:16 char:1
+ New-AzRecoveryServicesVault -ErrorAction Stop @newAzRecoveryServicesVaultSplat
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [New-AzRecoveryServicesVault], Exception
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.RecoveryServices.NewAzureRmRecoveryServicesVault
$LocationName = 'CanadaCentral'
$CustomerName = 'CanPrintEquip'
$VMName = 'Outlook1'
$ResourceGroupName = -join (" $CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join (" $VMName" , "ARSV1" )
$Tags = ''
$newAzRecoveryServicesVaultSplat = @{
    Name = $Vaultname
    ResourceGroupName = $ResourceGroupName
    Location = $LocationName
    Tag = $Tags
}
New-AzRecoveryServicesVault -ErrorAction Stop @newAzRecoveryServicesVaultSplat

