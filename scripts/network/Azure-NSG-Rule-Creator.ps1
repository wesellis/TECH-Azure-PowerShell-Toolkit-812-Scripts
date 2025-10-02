#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Manage NSGs

.DESCRIPTION
    Manage NSGs
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$NsgName,
    [Parameter(Mandatory)]
    [string]$RuleName,
    [Parameter(Mandatory)]
    [string]$Protocol,
    [Parameter(Mandatory)]
    [string]$SourcePortRange,
    [Parameter(Mandatory)]
    [string]$DestinationPortRange,
    [Parameter(Mandatory)]
    [string]$Access,
    [Parameter(Mandatory)]
    [int]$Priority
)
Write-Output "Adding security rule to NSG: $NsgName"
$Nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NsgName
$params = @{
    DestinationAddressPrefix = "*"
    Direction = "Inbound"
    Protocol = $Protocol
    Name = $RuleName
    Priority = $Priority
    DestinationPortRange = $DestinationPortRange
    SourcePortRange = $SourcePortRange
    Access = $Access
    NetworkSecurityGroup = $Nsg
    SourceAddressPrefix = "*"
}
Add-AzNetworkSecurityRuleConfig @params
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $Nsg
Write-Output "Security rule '$RuleName' added successfully to NSG: $NsgName"



