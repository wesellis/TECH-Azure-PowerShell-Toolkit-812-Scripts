#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    New Aztag

.DESCRIPTION
    New Aztag operation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$Tag = @{
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$Tag = @{
    "Autoshutown"     = 'OFF'
    "Createdby"       = 'Abdullah Ollivierre'
    "CustomerName"   = 'FGC Health'
    "DateTimeCreated" = " $datetime"
    "Environment"     = 'Lab'
    "Application"     = 'Kroll'
    "Purpose"         = 'Dev & Test'
    "Uptime"         = '240 hrs/month'
    "Workload"        = 'Kroll Lab'
    "VMGenenetation"  = 'Gen2'
    "RebootCaution"   = 'Reboot If needed'
    "VMSize"          = 'B2MS'
}
$tags = @{"Team" ="Compliance" ; "Environment" ="Production" }
New-AzTag -ResourceId $resource.id -Tag $tags
$tags = @{"Dept" ="Finance" ; "Status" ="Normal" }
Update-AzTag -ResourceId $resource.id -Tag $tags -Operation Merge


