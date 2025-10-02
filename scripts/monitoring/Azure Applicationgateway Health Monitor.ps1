#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Applicationgateway Health Monitor

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$GatewayName
)
Write-Output "Monitoring Application Gateway: $GatewayName" "INFO"
Write-Output "Resource Group: $ResourceGroupName" "INFO"
Write-Output " ============================================" "INFO"
    [string]$AppGateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName
Write-Output "Application Gateway Information:" "INFO"
Write-Output "Name: $($AppGateway.Name)" "INFO"
Write-Output "Location: $($AppGateway.Location)" "INFO"
Write-Output "Provisioning State: $($AppGateway.ProvisioningState)" "INFO"
Write-Output "Operational State: $($AppGateway.OperationalState)" "INFO"
Write-Output "SKU: $($AppGateway.Sku.Name) (Tier: $($AppGateway.Sku.Tier))" "INFO"
Write-Output "Capacity: $($AppGateway.Sku.Capacity)" "INFO"
Write-Output " `nFrontend Configurations:" "INFO"
foreach ($Frontend in $AppGateway.FrontendIPConfigurations) {
    Write-Output "  - Name: $($Frontend.Name)" "INFO"
    if ($Frontend.PublicIPAddress) {
    [string]$PublicIP = Get-AzPublicIpAddress -ResourceId $Frontend.PublicIPAddress.Id
        Write-Output "    Public IP: $($PublicIP.IpAddress)" "INFO"
    }
    if ($Frontend.PrivateIPAddress) {
        Write-Output "    Private IP: $($Frontend.PrivateIPAddress)" "INFO"
    }
}
Write-Output " `nBackend Address Pools:" "INFO"
foreach ($BackendPool in $AppGateway.BackendAddressPools) {
    Write-Output "  - Pool: $($BackendPool.Name)" "INFO"
    Write-Output "    Backend Addresses: $($BackendPool.BackendAddresses.Count)" "INFO"
    foreach ($Address in $BackendPool.BackendAddresses) {
        if ($Address.IpAddress) {
            Write-Output "      IP: $($Address.IpAddress)" "INFO"
        }
        if ($Address.Fqdn) {
            Write-Output "      FQDN: $($Address.Fqdn)" "INFO"
        }
    }
}
Write-Output " `nHTTP Listeners:" "INFO"
foreach ($Listener in $AppGateway.HttpListeners) {
    Write-Output "  - Listener: $($Listener.Name)" "INFO"
    Write-Output "    Protocol: $($Listener.Protocol)" "INFO"
    Write-Output "    Port: $($Listener.FrontendPort.Port)" "INFO"
    if ($Listener.HostName) {
        Write-Output "    Host Name: $($Listener.HostName)" "INFO"
    }
}
Write-Output " `nRequest Routing Rules:" "INFO"
foreach ($Rule in $AppGateway.RequestRoutingRules) {
    Write-Output "  - Rule: $($Rule.Name)" "INFO"
    Write-Output "    Type: $($Rule.RuleType)" "INFO"
    Write-Output "    Priority: $($Rule.Priority)" "INFO"
}
Write-Output " `nBackend HTTP Settings:" "INFO"
foreach ($Settings in $AppGateway.BackendHttpSettingsCollection) {
    Write-Output "  - Settings: $($Settings.Name)" "INFO"
    Write-Output "    Protocol: $($Settings.Protocol)" "INFO"
    Write-Output "    Port: $($Settings.Port)" "INFO"
    Write-Output "    Timeout: $($Settings.RequestTimeout) seconds" "INFO"
    Write-Output "    Cookie Affinity: $($Settings.CookieBasedAffinity)" "INFO"
}
if ($AppGateway.Probes.Count -gt 0) {
    Write-Output " `nHealth Probes:" "INFO"
    foreach ($Probe in $AppGateway.Probes) {
        Write-Output "  - Probe: $($Probe.Name)" "INFO"
        Write-Output "    Protocol: $($Probe.Protocol)" "INFO"
        Write-Output "    Path: $($Probe.Path)" "INFO"
        Write-Output "    Interval: $($Probe.Interval) seconds" "INFO"
        Write-Output "    Timeout: $($Probe.Timeout) seconds" "INFO"
    }
}
if ($AppGateway.SslCertificates.Count -gt 0) {
    Write-Output " `nSSL Certificates:" "INFO"
    foreach ($Cert in $AppGateway.SslCertificates) {
        Write-Output "  - Certificate: $($Cert.Name)" "INFO"
        Write-Output "    Key Vault Secret ID: $($Cert.KeyVaultSecretId)" "INFO"
    }
}
Write-Output " `nApplication Gateway monitoring completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
