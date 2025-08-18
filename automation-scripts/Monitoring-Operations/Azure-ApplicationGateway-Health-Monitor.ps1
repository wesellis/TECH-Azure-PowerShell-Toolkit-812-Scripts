# ============================================================================
# Script Name: Azure Application Gateway Health Monitor
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Monitors Azure Application Gateway health, backend pools, and routing rules
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$GatewayName
)

Write-Information "Monitoring Application Gateway: $GatewayName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "============================================"

# Get Application Gateway details
$AppGateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName

Write-Information "Application Gateway Information:"
Write-Information "  Name: $($AppGateway.Name)"
Write-Information "  Location: $($AppGateway.Location)"
Write-Information "  Provisioning State: $($AppGateway.ProvisioningState)"
Write-Information "  Operational State: $($AppGateway.OperationalState)"
Write-Information "  SKU: $($AppGateway.Sku.Name) (Tier: $($AppGateway.Sku.Tier))"
Write-Information "  Capacity: $($AppGateway.Sku.Capacity)"

# Frontend configurations
Write-Information "`nFrontend Configurations:"
foreach ($Frontend in $AppGateway.FrontendIPConfigurations) {
    Write-Information "  - Name: $($Frontend.Name)"
    if ($Frontend.PublicIPAddress) {
        $PublicIP = Get-AzPublicIpAddress -ResourceId $Frontend.PublicIPAddress.Id
        Write-Information "    Public IP: $($PublicIP.IpAddress)"
    }
    if ($Frontend.PrivateIPAddress) {
        Write-Information "    Private IP: $($Frontend.PrivateIPAddress)"
    }
}

# Backend address pools
Write-Information "`nBackend Address Pools:"
foreach ($BackendPool in $AppGateway.BackendAddressPools) {
    Write-Information "  - Pool: $($BackendPool.Name)"
    Write-Information "    Backend Addresses: $($BackendPool.BackendAddresses.Count)"
    foreach ($Address in $BackendPool.BackendAddresses) {
        if ($Address.IpAddress) {
            Write-Information "      IP: $($Address.IpAddress)"
        }
        if ($Address.Fqdn) {
            Write-Information "      FQDN: $($Address.Fqdn)"
        }
    }
}

# HTTP listeners
Write-Information "`nHTTP Listeners:"
foreach ($Listener in $AppGateway.HttpListeners) {
    Write-Information "  - Listener: $($Listener.Name)"
    Write-Information "    Protocol: $($Listener.Protocol)"
    Write-Information "    Port: $($Listener.FrontendPort.Port)"
    if ($Listener.HostName) {
        Write-Information "    Host Name: $($Listener.HostName)"
    }
}

# Request routing rules
Write-Information "`nRequest Routing Rules:"
foreach ($Rule in $AppGateway.RequestRoutingRules) {
    Write-Information "  - Rule: $($Rule.Name)"
    Write-Information "    Type: $($Rule.RuleType)"
    Write-Information "    Priority: $($Rule.Priority)"
}

# Backend HTTP settings
Write-Information "`nBackend HTTP Settings:"
foreach ($Settings in $AppGateway.BackendHttpSettingsCollection) {
    Write-Information "  - Settings: $($Settings.Name)"
    Write-Information "    Protocol: $($Settings.Protocol)"
    Write-Information "    Port: $($Settings.Port)"
    Write-Information "    Timeout: $($Settings.RequestTimeout) seconds"
    Write-Information "    Cookie Affinity: $($Settings.CookieBasedAffinity)"
}

# Health probes
if ($AppGateway.Probes.Count -gt 0) {
    Write-Information "`nHealth Probes:"
    foreach ($Probe in $AppGateway.Probes) {
        Write-Information "  - Probe: $($Probe.Name)"
        Write-Information "    Protocol: $($Probe.Protocol)"
        Write-Information "    Path: $($Probe.Path)"
        Write-Information "    Interval: $($Probe.Interval) seconds"
        Write-Information "    Timeout: $($Probe.Timeout) seconds"
    }
}

# SSL certificates
if ($AppGateway.SslCertificates.Count -gt 0) {
    Write-Information "`nSSL Certificates:"
    foreach ($Cert in $AppGateway.SslCertificates) {
        Write-Information "  - Certificate: $($Cert.Name)"
        Write-Information "    Key Vault Secret ID: $($Cert.KeyVaultSecretId)"
    }
}

Write-Information "`nApplication Gateway monitoring completed at $(Get-Date)"
