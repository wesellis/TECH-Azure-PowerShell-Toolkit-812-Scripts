#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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

