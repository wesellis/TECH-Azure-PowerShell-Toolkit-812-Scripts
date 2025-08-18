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

Write-Information "Creating Service Bus queue: $QueueName"

$Queue = New-AzServiceBusQueue -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -NamespaceName $NamespaceName `
    -Name $QueueName `
    -MaxSizeInMegabytes $MaxSizeInMegabytes

Write-Information "Queue created successfully:"
Write-Information "  Name: $($Queue.Name)"
Write-Information "  Max Size: $($Queue.MaxSizeInMegabytes) MB"
Write-Information "  Status: $($Queue.Status)"
Write-Information "  Namespace: $NamespaceName"
