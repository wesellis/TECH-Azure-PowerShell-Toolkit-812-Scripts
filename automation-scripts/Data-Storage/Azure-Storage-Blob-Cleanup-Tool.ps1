#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Manage storage

.DESCRIPTION
    Manage storage
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding(SupportsShouldProcess)]

    [string]$ResourceGroupName,
    [string]$StorageAccountName,
    [string]$ContainerName
)
if ($PSCmdlet.ShouldProcess("target", "operation")) {
        
    }

