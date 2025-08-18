<#
.SYNOPSIS
    We Enhanced 1 Get Azlocation

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

Get-AzLocation | Select-Object -Property Location, DisplayName
Get-AzLocation | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -like '*Canada*'}


$WEErrorActionPreference = "Stop"; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

Get-AzLocation | Select-Object -Property Location, DisplayName
Get-AzLocation | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -eq 'CanadaCentral'}
Get-AzLocation | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -like '*Canada*'}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================