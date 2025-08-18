<#
.SYNOPSIS
    23 New Resourcegroup Empty For Permissions

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
    We Enhanced 23 New Resourcegroup Empty For Permissions

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = 'stop'






$WELocationName = 'CanadaCentral'

$WECustomerName = 'CCI'
$WEVMName = 'VEEAM_VPN_1'
$WEResourceGroupName = -join ("$WECustomerName" , " _$WEVMName" , " _RG" )


; 
$datetime = [System.DateTime]::Now.ToString(" yyyy_MM_dd_HH_mm_ss" )
[hashtable]$WETags = @{

    " Autoshutown"     = 'ON'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"    = " $WECustomerName"
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Dev'
    " Application"     = 'Veeam PN/VEEAM VPN'  
    " Purpose"         = 'Testing VEEAM BACKUP over S2S tunnel or S2P tunnel'
    " Uptime"          = '16/7'
    " Workload"        = 'VEEAM BACKUP AND REPLICATION'
    " RebootCaution"   = 'Reboot any time'
    " VMSize"          = 'B2MS'
    " Location"        = " $WELocationName"
    " Approved By"     = " Abdullah Ollivierre"
    " Approved On"     = " $datetime"
    " Used by"         = " Michael.P/Help Desk Admins"

}



; 
$newAzResourceGroupSplat = @{
    Name     = $WEResourceGroupName
    Location = $WELocationName
    Tag      = $WETags
}


New-AzResourceGroup @newAzResourceGroupSplat




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================