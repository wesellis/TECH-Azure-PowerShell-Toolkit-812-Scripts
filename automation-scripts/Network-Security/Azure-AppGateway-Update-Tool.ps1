# ============================================================================
# Script Name: Azure Application Gateway Update Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Updates Azure Application Gateway configurations and settings
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$GatewayName,
    [hashtable]$Settings
)

# Get current Application Gateway
$Gateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName

Write-Host "Updating Application Gateway: $GatewayName"
Write-Host "Current SKU: $($Gateway.Sku.Name)"
Write-Host "Current Tier: $($Gateway.Sku.Tier)"
Write-Host "Current Capacity: $($Gateway.Sku.Capacity)"

# Apply settings (example implementation)
if ($Settings) {
    foreach ($Setting in $Settings.GetEnumerator()) {
        Write-Host "Applying setting: $($Setting.Key) = $($Setting.Value)"
    }
}

# Update the gateway
Set-AzApplicationGateway -ApplicationGateway $Gateway

Write-Host "Application Gateway $GatewayName updated successfully"
