#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    1 Get Azlocation

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced 1 Get Azlocation

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName
Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -like '*Canada*'}


$WEErrorActionPreference = "Stop" ; 
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName
Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -eq 'CanadaCentral'}
Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -like '*Canada*'}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
