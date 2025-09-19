#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Applicationgateway Health Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Applicationgateway Health Monitor

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [string]$WEGatewayName
)

#region Functions

Write-WELog " Monitoring Application Gateway: $WEGatewayName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " ============================================" " INFO"

; 
$WEAppGateway = Get-AzApplicationGateway -ResourceGroupName $WEResourceGroupName -Name $WEGatewayName

Write-WELog " Application Gateway Information:" " INFO"
Write-WELog "  Name: $($WEAppGateway.Name)" " INFO"
Write-WELog "  Location: $($WEAppGateway.Location)" " INFO"
Write-WELog "  Provisioning State: $($WEAppGateway.ProvisioningState)" " INFO"
Write-WELog "  Operational State: $($WEAppGateway.OperationalState)" " INFO"
Write-WELog "  SKU: $($WEAppGateway.Sku.Name) (Tier: $($WEAppGateway.Sku.Tier))" " INFO"
Write-WELog "  Capacity: $($WEAppGateway.Sku.Capacity)" " INFO"


Write-WELog " `nFrontend Configurations:" " INFO"
foreach ($WEFrontend in $WEAppGateway.FrontendIPConfigurations) {
    Write-WELog "  - Name: $($WEFrontend.Name)" " INFO"
    if ($WEFrontend.PublicIPAddress) {
       ;  $WEPublicIP = Get-AzPublicIpAddress -ResourceId $WEFrontend.PublicIPAddress.Id
        Write-WELog "    Public IP: $($WEPublicIP.IpAddress)" " INFO"
    }
    if ($WEFrontend.PrivateIPAddress) {
        Write-WELog "    Private IP: $($WEFrontend.PrivateIPAddress)" " INFO"
    }
}


Write-WELog " `nBackend Address Pools:" " INFO"
foreach ($WEBackendPool in $WEAppGateway.BackendAddressPools) {
    Write-WELog "  - Pool: $($WEBackendPool.Name)" " INFO"
    Write-WELog "    Backend Addresses: $($WEBackendPool.BackendAddresses.Count)" " INFO"
    foreach ($WEAddress in $WEBackendPool.BackendAddresses) {
        if ($WEAddress.IpAddress) {
            Write-WELog "      IP: $($WEAddress.IpAddress)" " INFO"
        }
        if ($WEAddress.Fqdn) {
            Write-WELog "      FQDN: $($WEAddress.Fqdn)" " INFO"
        }
    }
}


Write-WELog " `nHTTP Listeners:" " INFO"
foreach ($WEListener in $WEAppGateway.HttpListeners) {
    Write-WELog "  - Listener: $($WEListener.Name)" " INFO"
    Write-WELog "    Protocol: $($WEListener.Protocol)" " INFO"
    Write-WELog "    Port: $($WEListener.FrontendPort.Port)" " INFO"
    if ($WEListener.HostName) {
        Write-WELog "    Host Name: $($WEListener.HostName)" " INFO"
    }
}


Write-WELog " `nRequest Routing Rules:" " INFO"
foreach ($WERule in $WEAppGateway.RequestRoutingRules) {
    Write-WELog "  - Rule: $($WERule.Name)" " INFO"
    Write-WELog "    Type: $($WERule.RuleType)" " INFO"
    Write-WELog "    Priority: $($WERule.Priority)" " INFO"
}


Write-WELog " `nBackend HTTP Settings:" " INFO"
foreach ($WESettings in $WEAppGateway.BackendHttpSettingsCollection) {
    Write-WELog "  - Settings: $($WESettings.Name)" " INFO"
    Write-WELog "    Protocol: $($WESettings.Protocol)" " INFO"
    Write-WELog "    Port: $($WESettings.Port)" " INFO"
    Write-WELog "    Timeout: $($WESettings.RequestTimeout) seconds" " INFO"
    Write-WELog "    Cookie Affinity: $($WESettings.CookieBasedAffinity)" " INFO"
}


if ($WEAppGateway.Probes.Count -gt 0) {
    Write-WELog " `nHealth Probes:" " INFO"
    foreach ($WEProbe in $WEAppGateway.Probes) {
        Write-WELog "  - Probe: $($WEProbe.Name)" " INFO"
        Write-WELog "    Protocol: $($WEProbe.Protocol)" " INFO"
        Write-WELog "    Path: $($WEProbe.Path)" " INFO"
        Write-WELog "    Interval: $($WEProbe.Interval) seconds" " INFO"
        Write-WELog "    Timeout: $($WEProbe.Timeout) seconds" " INFO"
    }
}


if ($WEAppGateway.SslCertificates.Count -gt 0) {
    Write-WELog " `nSSL Certificates:" " INFO"
    foreach ($WECert in $WEAppGateway.SslCertificates) {
        Write-WELog "  - Certificate: $($WECert.Name)" " INFO"
        Write-WELog "    Key Vault Secret ID: $($WECert.KeyVaultSecretId)" " INFO"
    }
}

Write-WELog " `nApplication Gateway monitoring completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
