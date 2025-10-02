#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage App Services

.DESCRIPTION
    Manage App Services
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [string]$ResourceGroupName,
    [string]$PlanName,
    [int]$InstanceCount
)
Set-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $PlanName -NumberofWorkers $InstanceCount


