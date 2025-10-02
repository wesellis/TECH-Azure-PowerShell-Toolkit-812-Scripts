#Requires -Version 7.4
#Requires -Modules Az.Network

<#
.SYNOPSIS
    Invoke Azure Application Security Group creation

.DESCRIPTION
    Creates a new Azure Application Security Group for network security

.PARAMETER ResourceGroupName
    Name of the resource group

.PARAMETER VMName
    Name of the virtual machine

.PARAMETER LocationName
    Azure location name

.PARAMETER Tags
    Hash table of tags to apply

.EXAMPLE
    Invoke-AzApplicationSecurityGroup -ResourceGroupName "MyRG" -VMName "MyVM" -LocationName "East US" -Tags @{Environment="Dev"}

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [string]$LocationName,

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{}
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Invoke-AzApplicationSecurityGroup {
    $ASGName = -join ($VMName, "_ASG1")
    $NewAzApplicationSecurityGroupSplat = @{
        ResourceGroupName = $ResourceGroupName
        Name              = $ASGName
        Location          = $LocationName
        Tag               = $Tags
    }
    $ASG = New-AzApplicationSecurityGroup -ErrorAction Stop @NewAzApplicationSecurityGroupSplat
    return $ASG
}

# Execute the function
Invoke-AzApplicationSecurityGroup
