#Requires -Version 7.4
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Invoke Azure VM Config creation

.DESCRIPTION
    Creates a new Azure VM configuration with system assigned identity

.PARAMETER VMName
    Name of the virtual machine

.PARAMETER VMSize
    Size of the virtual machine

.PARAMETER Tags
    Hash table of tags to apply

.EXAMPLE
    Invoke-AzVMConfig -VMName "MyVM" -VMSize "Standard_B2s" -Tags @{Environment="Dev"}

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory = $true)]
    [string]$VMSize,

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{}
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Invoke-AzVMConfig {
    $NewAzVMConfigSplat = @{
        VMName       = $VMName
        VMSize       = $VMSize
        Tags         = $Tags
        IdentityType = 'SystemAssigned'
    }
    $VirtualMachine = New-AzVMConfig -ErrorAction Stop @NewAzVMConfigSplat
    return $VirtualMachine
}

# Execute the function
Invoke-AzVMConfig
