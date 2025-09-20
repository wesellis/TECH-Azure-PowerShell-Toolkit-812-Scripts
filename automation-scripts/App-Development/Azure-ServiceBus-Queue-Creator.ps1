<#
.SYNOPSIS
    Manage Service Bus

.DESCRIPTION
    Manage Service Bus
    Author: Wes Ellis (wes@wesellis.com)#>
param (
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$NamespaceName,
    [Parameter(Mandatory)]
    [string]$QueueName,
    [Parameter()]
    [int]$MaxSizeInMegabytes = 1024
)
Write-Host "Creating Service Bus queue: $QueueName"
$params = @{
    ErrorAction = "Stop"
    MaxSizeInMegabytes = $MaxSizeInMegabytes
    ResourceGroupName = $ResourceGroupName
    NamespaceName = $NamespaceName
    Name = $QueueName
}
$Queue @params
Write-Host "Queue created successfully:"
Write-Host "Name: $($Queue.Name)"
Write-Host "Max Size: $($Queue.MaxSizeInMegabytes) MB"
Write-Host "Status: $($Queue.Status)"
Write-Host "Namespace: $NamespaceName"

