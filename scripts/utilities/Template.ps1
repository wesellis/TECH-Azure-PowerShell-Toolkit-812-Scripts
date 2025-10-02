#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Template

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
$ErrorActionPreference = 'Stop'

    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$LocationName = 'CanadaCentral'
$CustomerName = 'FGCHealth'
$VMName = 'FGC-CR08NW2'
$ResourceGroupName = -join ("$CustomerName" , "_$VMName" , "_RG" )
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$Tags = @{
    "Autoshutown"     = 'OFF'
    "Createdby"       = 'Abdullah Ollivierre'
    "CustomerName"    = " $CustomerName"
    "DateTimeCreated" = " $datetime"
    "Environment"     = 'Dev/test lab'
    "Application"     = 'Kroll'
    "Purpose"         = 'Kroll Server'
    "Uptime"          = '24/7'
    "Workload"        = 'Kroll Windows'
    "VMGenenetation"  = 'Gen2'
    "RebootCaution"   = 'Schedule a window first before rebooting'
    "VMSize"          = 'B8MS'
    "Location"        = " $LocationName"
    "Approved By"     = "Sandeep Vedula "
    "Approved On"     = "December 22 2020"
    "Ticket ID"         = " 1516093"
    "CSP"               = "Canada Computing Inc."
    "Subscription Name" = "Microsoft Azure"
    "Subscription ID"   = " fef973de-017d-49f7-9098-1f644064f90d"
    "Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"
}
$NewAzResourceGroupSplat = @{
    Name = $ResourceGroupName
    Location = $LocationName
    Tag = $Tags
}
New-AzResourceGroup -ErrorAction Stop @newAzResourceGroupSplat



