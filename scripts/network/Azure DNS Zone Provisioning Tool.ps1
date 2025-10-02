#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Dns Zone Provisioning Tool

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ZoneName,
    [array]$Tags = @()
)
Write-Output "Provisioning DNS Zone: $ZoneName"
Write-Output "Resource Group: $ResourceGroupName"
if ($ZoneName -notmatch " ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$" ) {
    throw "Invalid DNS zone name format. Please provide a valid domain name."
}
if ($Tags.Count -gt 0) {
    [string]$DnsZone = New-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName -Tag $Tags
} else {
    [string]$DnsZone = New-AzDnsZone -ResourceGroupName $ResourceGroupName -Name $ZoneName
}
Write-Output " `nDNS Zone $ZoneName provisioned successfully"
Write-Output "Zone ID: $($DnsZone.Id)"
Write-Output "Number of Record Sets: $($DnsZone.NumberOfRecordSets)"
Write-Output " `nName Servers (configure these at your domain registrar):"
foreach ($NameServer in $DnsZone.NameServers) {
    Write-Output "  $NameServer"
}
Write-Output " `nDefault Record Sets Created:"
Write-Output "NS (Name Server) records"
Write-Output "SOA (Start of Authority) record"
Write-Output " `nNext Steps:"
Write-Output " 1. Update your domain registrar with the above name servers"
Write-Output " 2. Add A, CNAME, MX, or other DNS records as needed"
Write-Output " 3. Verify DNS propagation using nslookup or dig"
Write-Output " `nDNS Zone provisioning completed at $(Get-Date)"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
