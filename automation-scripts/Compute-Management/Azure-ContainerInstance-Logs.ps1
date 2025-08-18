# ============================================================================
# Script Name: Azure Container Instance Logs Viewer
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Retrieves and displays logs from Azure Container Instance
# ============================================================================

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

Write-Information -Object "Retrieving logs for container group: $ContainerGroupName"

if ($ContainerName) {
    $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -ContainerName $ContainerName -Tail $Tail
} else {
    $Logs = Get-AzContainerInstanceLog -ResourceGroupName $ResourceGroupName -ContainerGroupName $ContainerGroupName -Tail $Tail
}

Write-Information -Object "`nContainer Logs (Last $Tail lines):"
Write-Information -Object ("=" * 50)
Write-Information -Object $Logs
