#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$RegistryName,
    
    [Parameter(Mandatory=$true)]
    [string]$Location,
    
    [Parameter(Mandatory=$false)]
    [string]$Sku = "Basic"
)

#region Functions

Write-Information "Creating Container Registry: $RegistryName"

$params = @{
    ErrorAction = "Stop"
    Sku = $Sku
    ResourceGroupName = $ResourceGroupName
    Name = $RegistryName
    Location = $Location
}
$Registry @params

Write-Information " Container Registry created successfully:"
Write-Information "  Name: $($Registry.Name)"
Write-Information "  Login Server: $($Registry.LoginServer)"
Write-Information "  Location: $($Registry.Location)"
Write-Information "  SKU: $($Registry.Sku.Name)"
Write-Information "  Admin Enabled: $($Registry.AdminUserEnabled)"

# Get admin credentials
$Creds = Get-AzContainerRegistryCredential -ResourceGroupName $ResourceGroupName -Name $RegistryName
Write-Information "`nAdmin Credentials:"
Write-Information "  Username: $($Creds.Username)"
Write-Information "  Password: $($Creds.Password)"


#endregion
