<#
.SYNOPSIS
    Manage App Services

.DESCRIPTION
    Manage App Services
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [string]$ResourceGroupName,
    [string]$PlanName,
    [int]$InstanceCount
)
Set-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $PlanName -NumberofWorkers $InstanceCount

