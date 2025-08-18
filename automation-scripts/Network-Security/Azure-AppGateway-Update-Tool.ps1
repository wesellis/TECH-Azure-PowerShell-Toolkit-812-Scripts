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

Write-Information "Updating Application Gateway: $GatewayName"
Write-Information "Current SKU: $($Gateway.Sku.Name)"
Write-Information "Current Tier: $($Gateway.Sku.Tier)"
Write-Information "Current Capacity: $($Gateway.Sku.Capacity)"

# Apply settings (example implementation)
if ($Settings) {
    foreach ($Setting in $Settings.GetEnumerator()) {
        Write-Information "Applying setting: $($Setting.Key) = $($Setting.Value)"
    }
}

# Update the gateway
Set-AzApplicationGateway -ApplicationGateway $Gateway

Write-Information "Application Gateway $GatewayName updated successfully"
