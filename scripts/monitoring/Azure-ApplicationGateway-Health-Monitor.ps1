#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage App Gateway

.DESCRIPTION
    Manage App Gateway
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$GatewayName
)
Write-Output "Monitoring Application Gateway: $GatewayName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "============================================"
$AppGateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName
Write-Output "Application Gateway Information:"
Write-Output "Name: $($AppGateway.Name)"
Write-Output "Location: $($AppGateway.Location)"
Write-Output "Provisioning State: $($AppGateway.ProvisioningState)"
Write-Output "Operational State: $($AppGateway.OperationalState)"
Write-Output "SKU: $($AppGateway.Sku.Name) (Tier: $($AppGateway.Sku.Tier))"
Write-Output "Capacity: $($AppGateway.Sku.Capacity)"
Write-Output "`nFrontend Configurations:"
foreach ($Frontend in $AppGateway.FrontendIPConfigurations) {
    Write-Output "  - Name: $($Frontend.Name)"
    if ($Frontend.PublicIPAddress) {
        $PublicIP = Get-AzPublicIpAddress -ResourceId $Frontend.PublicIPAddress.Id
        Write-Output "    Public IP: $($PublicIP.IpAddress)"
    }
    if ($Frontend.PrivateIPAddress) {
        Write-Output "    Private IP: $($Frontend.PrivateIPAddress)"
    }
}
Write-Output "`nBackend Address Pools:"
foreach ($BackendPool in $AppGateway.BackendAddressPools) {
    Write-Output "  - Pool: $($BackendPool.Name)"
    Write-Output "    Backend Addresses: $($BackendPool.BackendAddresses.Count)"
    foreach ($Address in $BackendPool.BackendAddresses) {
        if ($Address.IpAddress) {
            Write-Output "      IP: $($Address.IpAddress)"
        }
        if ($Address.Fqdn) {
            Write-Output "      FQDN: $($Address.Fqdn)"
        }
    }
}
Write-Output "`nHTTP Listeners:"
foreach ($Listener in $AppGateway.HttpListeners) {
    Write-Output "  - Listener: $($Listener.Name)"
    Write-Output "    Protocol: $($Listener.Protocol)"
    Write-Output "    Port: $($Listener.FrontendPort.Port)"
    if ($Listener.HostName) {
        Write-Output "    Host Name: $($Listener.HostName)"
    }
}
Write-Output "`nRequest Routing Rules:"
foreach ($Rule in $AppGateway.RequestRoutingRules) {
    Write-Output "  - Rule: $($Rule.Name)"
    Write-Output "    Type: $($Rule.RuleType)"
    Write-Output "    Priority: $($Rule.Priority)"
}
Write-Output "`nBackend HTTP Settings:"
foreach ($Settings in $AppGateway.BackendHttpSettingsCollection) {
    Write-Output "  - Settings: $($Settings.Name)"
    Write-Output "    Protocol: $($Settings.Protocol)"
    Write-Output "    Port: $($Settings.Port)"
    Write-Output "    Timeout: $($Settings.RequestTimeout) seconds"
    Write-Output "    Cookie Affinity: $($Settings.CookieBasedAffinity)"
}
if ($AppGateway.Probes.Count -gt 0) {
    Write-Output "`nHealth Probes:"
    foreach ($Probe in $AppGateway.Probes) {
        Write-Output "  - Probe: $($Probe.Name)"
        Write-Output "    Protocol: $($Probe.Protocol)"
        Write-Output "    Path: $($Probe.Path)"
        Write-Output "    Interval: $($Probe.Interval) seconds"
        Write-Output "    Timeout: $($Probe.Timeout) seconds"
    }
}
if ($AppGateway.SslCertificates.Count -gt 0) {
    Write-Output "`nSSL Certificates:"
    foreach ($Cert in $AppGateway.SslCertificates) {
        Write-Output "  - Certificate: $($Cert.Name)"
        Write-Output "    Key Vault Secret ID: $($Cert.KeyVaultSecretId)"
    }
}
Write-Output "`nApplication Gateway monitoring completed at $(Get-Date)"



