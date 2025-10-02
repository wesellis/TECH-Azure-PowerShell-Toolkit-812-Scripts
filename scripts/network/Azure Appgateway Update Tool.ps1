#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Appgateway Update Tool

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
;
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GatewayName,
    [hashtable]$Settings
)
    [string]$Gateway = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $GatewayName
Write-Output "Updating Application Gateway: $GatewayName" "INFO"
Write-Output "Current SKU: $($Gateway.Sku.Name)" "INFO"
Write-Output "Current Tier: $($Gateway.Sku.Tier)" "INFO"
Write-Output "Current Capacity: $($Gateway.Sku.Capacity)" "INFO"
if ($Settings) {
    foreach ($Setting in $Settings.GetEnumerator()) {
        Write-Output "Applying setting: $($Setting.Key) = $($Setting.Value)" "INFO"
    }
}
Set-AzApplicationGateway -ApplicationGateway $Gateway
Write-Output "Application Gateway $GatewayName updated successfully" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
