#Requires -Version 7.4
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Update VMs

.DESCRIPTION
    Update VMs


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$VmName
)
Write-Output "Update VM functionality to be implemented for $VmName in $ResourceGroupName"



