<#
.SYNOPSIS
    9 New Aztag

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
    We Enhanced 9 New Aztag

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WETag = @{



$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }
; 
$WETag = @{

    " Autoshutown"     = 'OFF'
    " Createdby"       = 'Abdullah Ollivierre'
    " CustomerName"   = 'FGC Health'
    " DateTimeCreated" = " $datetime"
    " Environment"     = 'Lab'
    " Application"     = 'Kroll'  
    " Purpose"         = 'Dev & Test'
    " Uptime"         = '240 hrs/month'
    " Workload"        = 'Kroll Lab'
    " VMGenenetation"  = 'Gen2'
    " RebootCaution"   = 'Reboot If needed'
    " VMSize"          = 'B2MS'

}
; 
$tags = @{" Team" =" Compliance" ; " Environment" =" Production" }
New-AzTag -ResourceId $resource.id -Tag $tags



$tags = @{" Dept" =" Finance" ; " Status" =" Normal" }
Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge




# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================