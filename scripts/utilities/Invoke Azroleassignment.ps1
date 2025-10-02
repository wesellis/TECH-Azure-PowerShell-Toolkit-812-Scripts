#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Invoke Azure Role Assignment creation

.DESCRIPTION
    Creates a new Azure Role Assignment for VM user login access

.PARAMETER ResourceGroupName
    Name of the resource group

.PARAMETER VMName
    Name of the virtual machine

.PARAMETER UsersGroupName
    Name of the Azure AD group for users

.EXAMPLE
    Invoke-AzRoleAssignment -ResourceGroupName "MyRG" -VMName "MyVM" -UsersGroupName "Azure VM - Standard User"

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

    [Parameter(Mandatory = $false)]
    [string]$UsersGroupName = "Azure VM - Standard User"
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Invoke-AzRoleAssignment {
    $ObjectID = (Get-AzADGroup -SearchString $UsersGroupName).Id
    $vmtype = (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName).Type
    $RoleAssignment = New-AzRoleAssignment -ObjectId $ObjectID -RoleDefinitionName 'Virtual Machine User Login' -ResourceGroupName $ResourceGroupName -ResourceName $VMName -ResourceType $vmtype
    return $RoleAssignment
}

# Execute the function
Invoke-AzRoleAssignment
