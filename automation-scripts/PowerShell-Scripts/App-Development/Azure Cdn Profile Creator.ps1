<#
.SYNOPSIS
    Azure Cdn Profile Creator

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
Write-Host "Creating CDN Profile: $ProfileName"
$params = @{
    Sku = $Sku
    ErrorAction = "Stop"
    ProfileName = $ProfileName
    ResourceGroupName = $ResourceGroupName
    Location = $Location
}
$CdnProfile @params
Write-Host "CDN Profile created: $($CdnProfile.Name)"
Write-Host "Creating CDN Endpoint: $EndpointName"
$params = @{
    ResourceGroupName = $ResourceGroupName
    ProfileName = $ProfileName
    Location = $Location
    EndpointName = $EndpointName
    OriginHostName = $OriginHostName
    ErrorAction = "Stop"
    OriginName = " origin1"
}
$CdnEndpoint @params
Write-Host "CDN Profile and Endpoint created successfully:"
Write-Host "Profile Name: $($CdnProfile.Name)"
Write-Host "SKU: $($CdnProfile.Sku.Name)"
Write-Host "Endpoint Name: $($CdnEndpoint.Name)"
Write-Host "Endpoint URL: https://$($CdnEndpoint.HostName)"
Write-Host "Origin: $OriginHostName"
Write-Host " `nCDN Benefits:"
Write-Host "Global content delivery"
Write-Host "Reduced latency"
Write-Host "Improved performance"
Write-Host "Bandwidth cost optimization"
Write-Host "Origin server protection"
Write-Host " `nNext Steps:"
Write-Host " 1. Configure caching rules"
Write-Host " 2. Set up custom domains"
Write-Host " 3. Enable HTTPS"
Write-Host " 4. Configure compression"
Write-Host " 5. Test global distribution"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n