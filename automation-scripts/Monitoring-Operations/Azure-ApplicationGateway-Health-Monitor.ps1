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

Write-Host "Monitoring Application Gateway: $GatewayName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "============================================"

# Get Application Gateway details
$AppGateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName

Write-Host "Application Gateway Information:"
Write-Host "  Name: $($AppGateway.Name)"
Write-Host "  Location: $($AppGateway.Location)"
Write-Host "  Provisioning State: $($AppGateway.ProvisioningState)"
Write-Host "  Operational State: $($AppGateway.OperationalState)"
Write-Host "  SKU: $($AppGateway.Sku.Name) (Tier: $($AppGateway.Sku.Tier))"
Write-Host "  Capacity: $($AppGateway.Sku.Capacity)"

# Frontend configurations
Write-Host "`nFrontend Configurations:"
foreach ($Frontend in $AppGateway.FrontendIPConfigurations) {
    Write-Host "  - Name: $($Frontend.Name)"
    if ($Frontend.PublicIPAddress) {
        $PublicIP = Get-AzPublicIpAddress -ResourceId $Frontend.PublicIPAddress.Id
        Write-Host "    Public IP: $($PublicIP.IpAddress)"
    }
    if ($Frontend.PrivateIPAddress) {
        Write-Host "    Private IP: $($Frontend.PrivateIPAddress)"
    }
}

# Backend address pools
Write-Host "`nBackend Address Pools:"
foreach ($BackendPool in $AppGateway.BackendAddressPools) {
    Write-Host "  - Pool: $($BackendPool.Name)"
    Write-Host "    Backend Addresses: $($BackendPool.BackendAddresses.Count)"
    foreach ($Address in $BackendPool.BackendAddresses) {
        if ($Address.IpAddress) {
            Write-Host "      IP: $($Address.IpAddress)"
        }
        if ($Address.Fqdn) {
            Write-Host "      FQDN: $($Address.Fqdn)"
        }
    }
}

# HTTP listeners
Write-Host "`nHTTP Listeners:"
foreach ($Listener in $AppGateway.HttpListeners) {
    Write-Host "  - Listener: $($Listener.Name)"
    Write-Host "    Protocol: $($Listener.Protocol)"
    Write-Host "    Port: $($Listener.FrontendPort.Port)"
    if ($Listener.HostName) {
        Write-Host "    Host Name: $($Listener.HostName)"
    }
}

# Request routing rules
Write-Host "`nRequest Routing Rules:"
foreach ($Rule in $AppGateway.RequestRoutingRules) {
    Write-Host "  - Rule: $($Rule.Name)"
    Write-Host "    Type: $($Rule.RuleType)"
    Write-Host "    Priority: $($Rule.Priority)"
}

# Backend HTTP settings
Write-Host "`nBackend HTTP Settings:"
foreach ($Settings in $AppGateway.BackendHttpSettingsCollection) {
    Write-Host "  - Settings: $($Settings.Name)"
    Write-Host "    Protocol: $($Settings.Protocol)"
    Write-Host "    Port: $($Settings.Port)"
    Write-Host "    Timeout: $($Settings.RequestTimeout) seconds"
    Write-Host "    Cookie Affinity: $($Settings.CookieBasedAffinity)"
}

# Health probes
if ($AppGateway.Probes.Count -gt 0) {
    Write-Host "`nHealth Probes:"
    foreach ($Probe in $AppGateway.Probes) {
        Write-Host "  - Probe: $($Probe.Name)"
        Write-Host "    Protocol: $($Probe.Protocol)"
        Write-Host "    Path: $($Probe.Path)"
        Write-Host "    Interval: $($Probe.Interval) seconds"
        Write-Host "    Timeout: $($Probe.Timeout) seconds"
    }
}

# SSL certificates
if ($AppGateway.SslCertificates.Count -gt 0) {
    Write-Host "`nSSL Certificates:"
    foreach ($Cert in $AppGateway.SslCertificates) {
        Write-Host "  - Certificate: $($Cert.Name)"
        Write-Host "    Key Vault Secret ID: $($Cert.KeyVaultSecretId)"
    }
}

Write-Host "`nApplication Gateway monitoring completed at $(Get-Date)"
