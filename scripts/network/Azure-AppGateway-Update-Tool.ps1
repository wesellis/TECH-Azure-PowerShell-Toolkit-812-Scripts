#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$GatewayName,
    [hashtable]$Settings
)
$Gateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName
Write-Output "Updating Application Gateway: $GatewayName"
Write-Output "Current SKU: $($Gateway.Sku.Name)"
Write-Output "Current Tier: $($Gateway.Sku.Tier)"
Write-Output "Current Capacity: $($Gateway.Sku.Capacity)"
if ($Settings) {
    foreach ($Setting in $Settings.GetEnumerator()) {
        Write-Output "Applying setting: $($Setting.Key) = $($Setting.Value)"
    }
}
Set-AzApplicationGateway -ApplicationGateway $Gateway
Write-Output "Application Gateway $GatewayName updated successfully"



