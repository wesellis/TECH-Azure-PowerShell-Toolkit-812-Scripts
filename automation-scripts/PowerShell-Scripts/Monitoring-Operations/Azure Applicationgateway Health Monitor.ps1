<#
.SYNOPSIS
    Azure Applicationgateway Health Monitor

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [string]$GatewayName
)
Write-Host "Monitoring Application Gateway: $GatewayName" "INFO"
Write-Host "Resource Group: $ResourceGroupName" "INFO"
Write-Host " ============================================" "INFO"

$AppGateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName
Write-Host "Application Gateway Information:" "INFO"
Write-Host "Name: $($AppGateway.Name)" "INFO"
Write-Host "Location: $($AppGateway.Location)" "INFO"
Write-Host "Provisioning State: $($AppGateway.ProvisioningState)" "INFO"
Write-Host "Operational State: $($AppGateway.OperationalState)" "INFO"
Write-Host "SKU: $($AppGateway.Sku.Name) (Tier: $($AppGateway.Sku.Tier))" "INFO"
Write-Host "Capacity: $($AppGateway.Sku.Capacity)" "INFO"
Write-Host " `nFrontend Configurations:" "INFO"
foreach ($Frontend in $AppGateway.FrontendIPConfigurations) {
    Write-Host "  - Name: $($Frontend.Name)" "INFO"
    if ($Frontend.PublicIPAddress) {
$PublicIP = Get-AzPublicIpAddress -ResourceId $Frontend.PublicIPAddress.Id
        Write-Host "    Public IP: $($PublicIP.IpAddress)" "INFO"
    }
    if ($Frontend.PrivateIPAddress) {
        Write-Host "    Private IP: $($Frontend.PrivateIPAddress)" "INFO"
    }
}
Write-Host " `nBackend Address Pools:" "INFO"
foreach ($BackendPool in $AppGateway.BackendAddressPools) {
    Write-Host "  - Pool: $($BackendPool.Name)" "INFO"
    Write-Host "    Backend Addresses: $($BackendPool.BackendAddresses.Count)" "INFO"
    foreach ($Address in $BackendPool.BackendAddresses) {
        if ($Address.IpAddress) {
            Write-Host "      IP: $($Address.IpAddress)" "INFO"
        }
        if ($Address.Fqdn) {
            Write-Host "      FQDN: $($Address.Fqdn)" "INFO"
        }
    }
}
Write-Host " `nHTTP Listeners:" "INFO"
foreach ($Listener in $AppGateway.HttpListeners) {
    Write-Host "  - Listener: $($Listener.Name)" "INFO"
    Write-Host "    Protocol: $($Listener.Protocol)" "INFO"
    Write-Host "    Port: $($Listener.FrontendPort.Port)" "INFO"
    if ($Listener.HostName) {
        Write-Host "    Host Name: $($Listener.HostName)" "INFO"
    }
}
Write-Host " `nRequest Routing Rules:" "INFO"
foreach ($Rule in $AppGateway.RequestRoutingRules) {
    Write-Host "  - Rule: $($Rule.Name)" "INFO"
    Write-Host "    Type: $($Rule.RuleType)" "INFO"
    Write-Host "    Priority: $($Rule.Priority)" "INFO"
}
Write-Host " `nBackend HTTP Settings:" "INFO"
foreach ($Settings in $AppGateway.BackendHttpSettingsCollection) {
    Write-Host "  - Settings: $($Settings.Name)" "INFO"
    Write-Host "    Protocol: $($Settings.Protocol)" "INFO"
    Write-Host "    Port: $($Settings.Port)" "INFO"
    Write-Host "    Timeout: $($Settings.RequestTimeout) seconds" "INFO"
    Write-Host "    Cookie Affinity: $($Settings.CookieBasedAffinity)" "INFO"
}
if ($AppGateway.Probes.Count -gt 0) {
    Write-Host " `nHealth Probes:" "INFO"
    foreach ($Probe in $AppGateway.Probes) {
        Write-Host "  - Probe: $($Probe.Name)" "INFO"
        Write-Host "    Protocol: $($Probe.Protocol)" "INFO"
        Write-Host "    Path: $($Probe.Path)" "INFO"
        Write-Host "    Interval: $($Probe.Interval) seconds" "INFO"
        Write-Host "    Timeout: $($Probe.Timeout) seconds" "INFO"
    }
}
if ($AppGateway.SslCertificates.Count -gt 0) {
    Write-Host " `nSSL Certificates:" "INFO"
    foreach ($Cert in $AppGateway.SslCertificates) {
        Write-Host "  - Certificate: $($Cert.Name)" "INFO"
        Write-Host "    Key Vault Secret ID: $($Cert.KeyVaultSecretId)" "INFO"
    }
}
Write-Host " `nApplication Gateway monitoring completed at $(Get-Date)" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n