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
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ContainerGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$ContainerName,
    
    [Parameter(Mandatory=$false)]
    [int]$Tail = 50
)

#region Functions

Write-Information -Object "Retrieving logs for container group: $ContainerGroupName"

if ($ContainerName) {
    $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -ContainerName $ContainerName -Tail $Tail
} else {
    $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -Tail $Tail
}

Write-Information -Object "`nContainer Logs (Last $Tail lines):"
Write-Information -Object ("=" * 50)
Write-Information -Object $Logs


#endregion
