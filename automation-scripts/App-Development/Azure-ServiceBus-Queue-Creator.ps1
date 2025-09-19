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
    [string]$NamespaceName,
    
    [Parameter(Mandatory=$true)]
    [string]$QueueName,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxSizeInMegabytes = 1024
)

#region Functions

Write-Information "Creating Service Bus queue: $QueueName"

$params = @{
    ErrorAction = "Stop"
    MaxSizeInMegabytes = $MaxSizeInMegabytes
    ResourceGroupName = $ResourceGroupName
    NamespaceName = $NamespaceName
    Name = $QueueName
}
$Queue @params

Write-Information "Queue created successfully:"
Write-Information "  Name: $($Queue.Name)"
Write-Information "  Max Size: $($Queue.MaxSizeInMegabytes) MB"
Write-Information "  Status: $($Queue.Status)"
Write-Information "  Namespace: $NamespaceName"


#endregion
