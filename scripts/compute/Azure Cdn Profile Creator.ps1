#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Cdn Profile Creator

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
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ProfileName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$EndpointName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OriginHostName,
    [Parameter()]
    [string]$Sku = "Standard_Microsoft"
)
Write-Output "Creating CDN Profile: $ProfileName"
    $params = @{
    Sku = $Sku
    ErrorAction = "Stop"
    ProfileName = $ProfileName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
    [string]$CdnProfile @params
Write-Output "CDN Profile created: $($CdnProfile.Name)"
Write-Output "Creating CDN Endpoint: $EndpointName"
    $params = @{
    ResourceGroupName = $ResourceGroupName
    ProfileName = $ProfileName
    Location = $Location
    EndpointName = $EndpointName
    OriginHostName = $OriginHostName
    ErrorAction = "Stop"
    OriginName = " origin1"
}
    [string]$CdnEndpoint @params
Write-Output "CDN Profile and Endpoint created successfully:"
Write-Output "Profile Name: $($CdnProfile.Name)"
Write-Output "SKU: $($CdnProfile.Sku.Name)"
Write-Output "Endpoint Name: $($CdnEndpoint.Name)"
Write-Output "Endpoint URL: https://$($CdnEndpoint.HostName)"
Write-Output "Origin: $OriginHostName"
Write-Output " `nCDN Benefits:"
Write-Output "Global content delivery"
Write-Output "Reduced latency"
Write-Output "Improved performance"
Write-Output "Bandwidth cost optimization"
Write-Output "Origin server protection"
Write-Output " `nNext Steps:"
Write-Output " 1. Configure caching rules"
Write-Output " 2. Set up custom domains"
Write-Output " 3. Enable HTTPS"
Write-Output " 4. Configure compression"
Write-Output " 5. Test global distribution"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
