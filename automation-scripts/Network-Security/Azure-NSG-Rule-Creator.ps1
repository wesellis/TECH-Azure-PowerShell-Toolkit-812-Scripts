# ============================================================================
# Script Name: Azure Network Security Group Rule Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Adds a new security rule to an Azure Network Security Group
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$NsgName,
    
    [Parameter(Mandatory=$true)]
    [string]$RuleName,
    
    [Parameter(Mandatory=$true)]
    [string]$Protocol,
    
    [Parameter(Mandatory=$true)]
    [string]$SourcePortRange,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationPortRange,
    
    [Parameter(Mandatory=$true)]
    [string]$Access,
    
    [Parameter(Mandatory=$true)]
    [int]$Priority
)

Write-Host "Adding security rule to NSG: $NsgName"

$Nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NsgName

Add-AzNetworkSecurityRuleConfig `
    -NetworkSecurityGroup $Nsg `
    -Name $RuleName `
    -Protocol $Protocol `
    -SourcePortRange $SourcePortRange `
    -DestinationPortRange $DestinationPortRange `
    -SourceAddressPrefix "*" `
    -DestinationAddressPrefix "*" `
    -Access $Access `
    -Priority $Priority `
    -Direction Inbound

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $Nsg
Write-Host "Security rule '$RuleName' added successfully to NSG: $NsgName"
