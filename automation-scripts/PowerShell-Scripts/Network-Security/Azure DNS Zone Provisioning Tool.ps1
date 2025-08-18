<#
.SYNOPSIS
    Azure Dns Zone Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Dns Zone Provisioning Tool

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEZoneName,
    [array]$WETags = @()
)

Write-WELog " Provisioning DNS Zone: $WEZoneName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"


if ($WEZoneName -notmatch " ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$" ) {
    throw " Invalid DNS zone name format. Please provide a valid domain name."
}


if ($WETags.Count -gt 0) {
   ;  $WEDnsZone = New-AzDnsZone -ResourceGroupName $WEResourceGroupName -Name $WEZoneName -Tag $WETags
} else {
   ;  $WEDnsZone = New-AzDnsZone -ResourceGroupName $WEResourceGroupName -Name $WEZoneName
}

Write-WELog " `nDNS Zone $WEZoneName provisioned successfully" " INFO"
Write-WELog " Zone ID: $($WEDnsZone.Id)" " INFO"
Write-WELog " Number of Record Sets: $($WEDnsZone.NumberOfRecordSets)" " INFO"


Write-WELog " `nName Servers (configure these at your domain registrar):" " INFO"
foreach ($WENameServer in $WEDnsZone.NameServers) {
    Write-WELog "  $WENameServer" " INFO"
}

Write-WELog " `nDefault Record Sets Created:" " INFO"
Write-WELog "  NS (Name Server) records" " INFO"
Write-WELog "  SOA (Start of Authority) record" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Update your domain registrar with the above name servers" " INFO"
Write-WELog " 2. Add A, CNAME, MX, or other DNS records as needed" " INFO"
Write-WELog " 3. Verify DNS propagation using nslookup or dig" " INFO"

Write-WELog " `nDNS Zone provisioning completed at $(Get-Date)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
