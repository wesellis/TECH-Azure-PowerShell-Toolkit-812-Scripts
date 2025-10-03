#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    New Resourcegroup Empty For Permissions

.DESCRIPTION
    New Resourcegroup Empty For Permissions operation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerName = 'CCI',

    [Parameter(Mandatory = $true)]
    [string]$VMName = 'VEEAM_VPN_1',

    [Parameter(Mandatory = $true)]
    [string]$LocationName = 'CanadaCentral'
)

$ErrorActionPreference = 'Stop'

$ResourceGroupName = -join ("$CustomerName" , "_$VMName" , "_RG" )
$datetime = [System.DateTime]::Now.ToString("yyyy_MM_dd_HH_mm_ss")

[hashtable]$Tags = @{
    "Autoshutown"     = 'ON'
    "Createdby"       = 'Abdullah Ollivierre'
    "CustomerName"    = "$CustomerName"
    "DateTimeCreated" = "$datetime"
    "Environment"     = 'Dev'
    "Application"     = 'Veeam PN/VEEAM VPN'
    "Purpose"         = 'Testing VEEAM BACKUP over S2S tunnel or S2P tunnel'
    "Uptime"          = '16/7'
    "Workload"        = 'VEEAM BACKUP AND REPLICATION'
    "RebootCaution"   = 'Reboot any time'
    "VMSize"          = 'B2MS'
    "Location"        = "$LocationName"
    "Approved By"     = "Abdullah Ollivierre"
    "Approved On"     = "$datetime"
    "Used by"         = "Michael.P/Help Desk Admins"
}

$NewAzResourceGroupSplat = @{
    Name     = $ResourceGroupName
    Location = $LocationName
    Tag      = $Tags
}
New-AzResourceGroup -ErrorAction Stop @NewAzResourceGroupSplat