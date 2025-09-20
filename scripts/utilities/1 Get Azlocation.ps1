#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Get location

.DESCRIPTION
    Get location operation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName
Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -like '*Canada*'}
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName
Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -eq 'CanadaCentral'}
Get-AzLocation -ErrorAction Stop | Select-Object -Property Location, DisplayName | Where-Object {$_.Location -like '*Canada*'}


