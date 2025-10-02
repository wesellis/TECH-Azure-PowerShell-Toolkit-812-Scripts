#Requires -Version 7.4
#Requires -Modules Az.ServiceBus

<#`n.SYNOPSIS
    Manage Service Bus

.DESCRIPTION
    Manage Service Bus
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$NamespaceName,
    [Parameter(Mandatory)]
    [string]$QueueName,
    [Parameter()]
    [int]$MaxSizeInMegabytes = 1024
)
Write-Output "Creating Service Bus queue: $QueueName"
$params = @{
    ErrorAction = "Stop"
    MaxSizeInMegabytes = $MaxSizeInMegabytes
    ResourceGroupName = $ResourceGroupName
    NamespaceName = $NamespaceName
    Name = $QueueName
}
$Queue @params
Write-Output "Queue created successfully:"
Write-Output "Name: $($Queue.Name)"
Write-Output "Max Size: $($Queue.MaxSizeInMegabytes) MB"
Write-Output "Status: $($Queue.Status)"
Write-Output "Namespace: $NamespaceName"



