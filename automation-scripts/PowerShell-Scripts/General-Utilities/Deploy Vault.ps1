<#
.SYNOPSIS
    #	   Deploy a new Key Vault and add a key that will be used as encryption protector for Azure SQL Server
	#
.DESCRIPTION
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
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,
      [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
      [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$KeyVaultLocation,
      [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$KeyVaultName,
      [Parameter(Mandatory)]
      [string]$KeyName
    )
    Add-AzureRmAccount
    Write-Information \'Selecting Azure Subscription...\' $SubscriptionId -foregroundcolor Yellow
    Select-AzureRmSubscription -SubscriptionId $SubscriptionId
    # Create a new Key vault, with enable soft delete (prerequisites to use a stored key as encryption protector for SQL)
    Write-Information \'Creating the new Key Vault...\'
    New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $KeyVaultLocation -EnableSoftDelete
    # Generate a key
    Write-Information \'Adding the new key inside the Key Vault...\'
    Add-AzureKeyVaultKey -VaultName $KeyVaultName -Name $KeyName -Destination 'Software'
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

