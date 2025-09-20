#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Fetch vault ID

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$CustomerName = 'CanPrintEquip'
$VMName = 'Outlook1'
$ResourceGroupName = -join (" $CustomerName" , "_Outlook" , "_RG" )
$Vaultname = -join (" $VMName" , "ARSV1" )
$getAzRecoveryServicesVaultSplat = @{
    ResourceGroupName = $ResourceGroupName
    Name = $Vaultname
}
$targetVault = Get-AzRecoveryServicesVault -ErrorAction Stop @getAzRecoveryServicesVaultSplat
$targetVault.ID
$targetVault


