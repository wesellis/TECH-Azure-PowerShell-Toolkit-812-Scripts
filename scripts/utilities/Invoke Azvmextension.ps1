#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Invoke Azure VM Extension installation

.DESCRIPTION
    Installs the Azure Active Directory Login extension on a specified Azure VM.
    This enables Azure AD authentication for Windows VMs.

.PARAMETER ResourceGroupName
    The name of the resource group containing the VM

.PARAMETER LocationName
    The Azure location where the VM is located

.PARAMETER VMName
    The name of the virtual machine

.EXAMPLE
    Invoke-AzVMExtension -ResourceGroupName "MyRG" -LocationName "East US" -VMName "MyVM"

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$LocationName,

    [Parameter(Mandatory = $true)]
    [string]$VMName
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Invoke-AzVMExtension {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string]$LocationName,

        [Parameter(Mandatory = $true)]
        [string]$VMName
    )

    try {
        Write-Verbose "Installing AADLoginForWindows extension on VM: $VMName"

        $SetAzVMExtensionSplat = @{
            ResourceGroupName = $ResourceGroupName
            Location = $LocationName
            VMName = $VMName
            Name = "AADLoginForWindows"
            Publisher = "Microsoft.Azure.ActiveDirectory"
            ExtensionType = "AADLoginForWindows"
            TypeHandlerVersion = "1.0"
        }

        Set-AzVMExtension -ErrorAction Stop @SetAzVMExtensionSplat
        Write-Output "Successfully installed AADLoginForWindows extension on VM: $VMName"
    }
    catch {
        Write-Error "Failed to install VM extension: $_"
        throw
    }
}

# Execute the function with script parameters
Invoke-AzVMExtension -ResourceGroupName $ResourceGroupName -LocationName $LocationName -VMName $VMName