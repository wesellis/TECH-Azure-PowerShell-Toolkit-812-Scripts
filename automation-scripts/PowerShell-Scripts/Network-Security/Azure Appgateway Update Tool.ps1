<#
.SYNOPSIS
    Azure Appgateway Update Tool

.DESCRIPTION
    Azure automation
#>
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
[CmdletBinding()];
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GatewayName,
    [hashtable]$Settings
)

$Gateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName
Write-Host "Updating Application Gateway: $GatewayName" "INFO"
Write-Host "Current SKU: $($Gateway.Sku.Name)" "INFO"
Write-Host "Current Tier: $($Gateway.Sku.Tier)" "INFO"
Write-Host "Current Capacity: $($Gateway.Sku.Capacity)" "INFO"
if ($Settings) {
    foreach ($Setting in $Settings.GetEnumerator()) {
        Write-Host "Applying setting: $($Setting.Key) = $($Setting.Value)" "INFO"
    }
}
Set-AzApplicationGateway -ApplicationGateway $Gateway
Write-Host "Application Gateway $GatewayName updated successfully" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

