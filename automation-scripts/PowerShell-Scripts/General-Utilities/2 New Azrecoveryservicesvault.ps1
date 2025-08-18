<#
.SYNOPSIS
    We Enhanced 2 New Azrecoveryservicesvault

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

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


    Name              : Outlook1ARSV1
ID                : /subscriptions/408a6c03-bd25-471b-ae84-cf82b3dff420/resourceGroups/CanPrintEquip_Outlook_RG/providers/Microsoft.RecoveryServi 
                    ces/vaults/Outlook1ARSV1
Type              : Microsoft.RecoveryServices/vaults
Location          : canadacentral
ResourceGroupName : CanPrintEquip_Outlook_RG
SubscriptionId    : 408a6c03-bd25-471b-ae84-cf82b3dff420
Properties        : Microsoft.Azure.Commands.RecoveryServices.ARSVaultProperties

.NOTES
    General notes

    You will get the vague error below if you have any illegel or imporper or invalid characters in any of your variables specifially the ARS Vault name like under score _ will throw the following error

    New-AzRecoveryServicesVault : Operation failed.
ClientRequestId: 7441125a-cac5-4a2d-92a0-05e3cd327b24-2020-12-12 06:08:34Z-P
One or more errors occurred.
At C:\Users\Abdullah.Ollivierre\AzureRepos2\Azure\Migrating_VM_VNETA-to_VNETB\2-New-AzRecoveryServicesVault.ps1:16 char:1
+ New-AzRecoveryServicesVault @newAzRecoveryServicesVaultSplat
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : CloseError: (:) [New-AzRecoveryServicesVault], Exception
    + FullyQualifiedErrorId : Microsoft.Azure.Commands.RecoveryServices.NewAzureRmRecoveryServicesVault


$WELocationName = 'CanadaCentral'
$WECustomerName = 'CanPrintEquip'
$WEVMName = 'Outlook1'
$WEResourceGroupName = -join (" $WECustomerName", " _Outlook", " _RG")

$WEVaultname = -join (" $WEVMName", " ARSV1")


$WETags = ''

; 
$newAzRecoveryServicesVaultSplat = @{
    Name = $WEVaultname
    ResourceGroupName = $WEResourceGroupName 
    Location = $WELocationName
    Tag = $WETags

}

New-AzRecoveryServicesVault @newAzRecoveryServicesVaultSplat







# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================