#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding(SupportsShouldProcess)]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$ContainerName
)
if ($PSCmdlet.ShouldProcess("target", "operation")) {`n}
