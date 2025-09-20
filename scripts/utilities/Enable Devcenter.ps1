#Requires -Version 7.0

<#`n.SYNOPSIS
    Enable Devcenter

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
Register-AzResourceProvider -ProviderNamespace Microsoft.DevCenter
