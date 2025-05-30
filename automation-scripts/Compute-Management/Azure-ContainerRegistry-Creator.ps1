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

Write-Host "Creating Container Registry: $RegistryName"

$Registry = New-AzContainerRegistry `
    -ResourceGroupName $ResourceGroupName `
    -Name $RegistryName `
    -Location $Location `
    -Sku $Sku `
    -EnableAdminUser

Write-Host "✅ Container Registry created successfully:"
Write-Host "  Name: $($Registry.Name)"
Write-Host "  Login Server: $($Registry.LoginServer)"
Write-Host "  Location: $($Registry.Location)"
Write-Host "  SKU: $($Registry.Sku.Name)"
Write-Host "  Admin Enabled: $($Registry.AdminUserEnabled)"

# Get admin credentials
$Creds = Get-AzContainerRegistryCredential -ResourceGroupName $ResourceGroupName -Name $RegistryName
Write-Host "`nAdmin Credentials:"
Write-Host "  Username: $($Creds.Username)"
Write-Host "  Password: $($Creds.Password)"
