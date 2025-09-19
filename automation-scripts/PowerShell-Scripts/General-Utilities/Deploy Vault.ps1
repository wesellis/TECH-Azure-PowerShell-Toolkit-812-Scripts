#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Deploy Vault

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
    We Enhanced Deploy Vault

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


function WE-New-KeyVaultAndKey()
try {
    # Main script execution
{
     #<#
	#.Synopsis
	#	   Deploy a new Key Vault and add a key that will be used as encryption protector for Azure SQL Server
	#.Description
    #      Use this script if you do not have already a Key Vault - otherwise, you can use yours in the ARM template included in this repo
    #
	#.Parameter SubscriptionId
    #      SubscriptionId is the identifier of the subscription to use. 
	#.Parameter ResourceGroupName
    #      Azure resource group name. If this resource group exists, it will be used for the new Key Vault deployment
    #.Parameter KeyVaultLocation
    #      Azure Key Vault deployment location 
    #.Parameter KeyVaultName
    #      Azure Key Vault name to deploy
    #.Parameter KeyName
    #      Azure Key Vault key name to insert in the Azure Key Vault
	##>
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
      [Parameter(Mandatory)]
      [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionId,

      [Parameter(Mandatory)]
      [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
      
      [Parameter(Mandatory)]
      [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEKeyVaultLocation,

      [Parameter(Mandatory)]
      [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEKeyVaultName,

      [Parameter(Mandatory)]
      [string]$WEKeyName
    )

    Add-AzureRmAccount

    Write-Information \'Selecting Azure Subscription...\' $WESubscriptionId -foregroundcolor Yellow
    Select-AzureRmSubscription -SubscriptionId $WESubscriptionId

    # Create a new Key vault, with enable soft delete (prerequisites to use a stored key as encryption protector for SQL)
    Write-Information \'Creating the new Key Vault...\'
    New-AzureRmKeyVault -VaultName $WEKeyVaultName -ResourceGroupName $WEResourceGroupName -Location $WEKeyVaultLocation -EnableSoftDelete

    # Generate a key
    Write-Information \'Adding the new key inside the Key Vault...\'
    Add-AzureKeyVaultKey -VaultName $WEKeyVaultName -Name $WEKeyName -Destination 'Software'
}



} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
