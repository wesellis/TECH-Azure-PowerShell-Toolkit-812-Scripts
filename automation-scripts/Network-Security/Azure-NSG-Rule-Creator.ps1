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

#region Functions

Write-Information "Adding security rule to NSG: $NsgName"

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
Write-Information "Security rule '$RuleName' added successfully to NSG: $NsgName"


#endregion
