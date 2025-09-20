<#
.SYNOPSIS
    Get resourcegroup

.DESCRIPTION
    Get resourcegroup operation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Author: Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Get-AzResourceGroup -ErrorAction Stop | Select-Object -Property ResourceGroupName, Location
Get-AzResourceGroup -ErrorAction Stop | Select-Object -Property ResourceGroupName, Location
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
Get-AzResourceGroup -ErrorAction Stop | Select-Object -Property ResourceGroupName, Location\n