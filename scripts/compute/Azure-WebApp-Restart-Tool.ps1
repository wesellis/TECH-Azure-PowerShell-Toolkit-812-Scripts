#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$AppName
)
Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppName


