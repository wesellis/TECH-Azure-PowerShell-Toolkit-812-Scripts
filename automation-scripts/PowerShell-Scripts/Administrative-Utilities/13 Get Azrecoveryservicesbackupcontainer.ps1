<#
.SYNOPSIS
    13 Get Azrecoveryservicesbackupcontainer

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
.SYNOPSIS
    We Enhanced 13 Get Azrecoveryservicesbackupcontainer

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    FriendlyName                             ResourceGroupName                        Status               ContainerType       
------------                             -----------------                        ------               -------------
Outlook1                                 canprintequip_outlook_rg                 Registered           AzureVM
.NOTES
    General notes






$WECustomerName = 'CanPrintEquip'
$WEVMName = 'Outlook1'
$WEResourceGroupName = -join ("$WECustomerName" , " _Outlook" , " _RG" )

$WEVaultname = -join (" $WEVMName" , " ARSV1" )

$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $WEResourceGroupName
    Name = $WEVaultname
}

$targetVault = Get-AzRecoveryServicesVault -ErrorAction Stop @getAzRecoveryServicesVaultSplat


; 
$getAzRecoveryServicesBackupContainerSplat = @{
    ContainerType = " AzureVM"
    Status = " Registered"
    FriendlyName = $WEVMName
    VaultId = $targetVault.ID
}
; 
$namedContainer = Get-AzRecoveryServicesBackupContainer -ErrorAction Stop  @getAzRecoveryServicesBackupContainerSplat
$namedContainer

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================