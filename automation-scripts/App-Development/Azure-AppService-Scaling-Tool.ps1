#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [string]$ResourceGroupName,
    [string]$PlanName,
    [int]$InstanceCount
)

#region Functions

Set-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $PlanName -NumberofWorkers $InstanceCount


#endregion
