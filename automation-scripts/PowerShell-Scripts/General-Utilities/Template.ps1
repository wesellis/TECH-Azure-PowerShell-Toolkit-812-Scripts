<#
.SYNOPSIS
    Template

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
    We Enhanced Template

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WELocationName = 'CanadaCentral'
$WECustomerName = 'FGCHealth'
$WEVMName = 'FGC-CR08NW2'
$WEResourceGroupName = -join ("$WECustomerName" , " _$WEVMName" , " _RG" )


; 
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"     = 'OFF'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"    = " $WECustomerName"
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Dev/test lab'
    " Application"     = 'Kroll'  
    " Purpose"         = 'Kroll Server'
    " Uptime"          = '24/7'
    " Workload"        = 'Kroll Windows'
    " VMGenenetation"  = 'Gen2'
    " RebootCaution"   = 'Schedule a window first before rebooting'
    " VMSize"          = 'B8MS'
    " Location"        = " $WELocationName"
    " Approved By"     = " Sandeep Vedula "
    " Approved On"     = " December 22 2020"
    " Ticket ID"         = " 1516093"
    " CSP"               = " Canada Computing Inc."
    " Subscription Name" = " Microsoft Azure"
    " Subscription ID"   = " fef973de-017d-49f7-9098-1f644064f90d"
    " Tenant ID"         = " e09d9473-1a06-4717-98c1-528067eab3a4"

}

; 
$newAzResourceGroupSplat = @{
    Name = $WEResourceGroupName
    Location = $WELocationName
    Tag = $WETags
}

New-AzResourceGroup @newAzResourceGroupSplat

# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================