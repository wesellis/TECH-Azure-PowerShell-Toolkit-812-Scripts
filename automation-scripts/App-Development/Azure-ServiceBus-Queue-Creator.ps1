# ============================================================================
# Script Name: Azure Service Bus Queue Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates a new queue in Azure Service Bus namespace
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$NamespaceName,
    
    [Parameter(Mandatory=$true)]
    [string]$QueueName,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxSizeInMegabytes = 1024
)

Write-Host "Creating Service Bus queue: $QueueName"

$Queue = New-AzServiceBusQueue `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName `
    -Name $QueueName `
    -MaxSizeInMegabytes $MaxSizeInMegabytes

Write-Host "Queue created successfully:"
Write-Host "  Name: $($Queue.Name)"
Write-Host "  Max Size: $($Queue.MaxSizeInMegabytes) MB"
Write-Host "  Status: $($Queue.Status)"
Write-Host "  Namespace: $NamespaceName"
