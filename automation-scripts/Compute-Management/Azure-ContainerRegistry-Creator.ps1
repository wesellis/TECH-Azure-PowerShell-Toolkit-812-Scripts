# ============================================================================
# Script Name: Azure Container Registry Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Container Registry for container image storage
# ============================================================================

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

Write-Information "Creating Container Registry: $RegistryName"

$Registry = New-AzContainerRegistry -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $RegistryName `
    -Location $Location `
    -Sku $Sku `
    -EnableAdminUser

Write-Information "✅ Container Registry created successfully:"
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
