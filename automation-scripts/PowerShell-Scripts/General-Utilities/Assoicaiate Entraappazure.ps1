<#
.SYNOPSIS
    Assoicaiate Entraappazure

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
az account set --subscription 28c8da4f-f7e4-40b4-9fe8-fd53e4581d26
$ErrorActionPreference = "Stop" ;
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
az account set --subscription 28c8da4f-f7e4-40b4-9fe8-fd53e4581d26

