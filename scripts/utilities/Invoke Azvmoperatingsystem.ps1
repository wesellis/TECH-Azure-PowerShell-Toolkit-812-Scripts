#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Configure Azure VM Operating System settings

.DESCRIPTION
    Sets the operating system configuration for an Azure virtual machine, including
    computer name, credentials, and VM agent provisioning.

.PARAMETER VirtualMachine
    The Azure VM object to configure

.PARAMETER ComputerName
    The computer name for the VM

.PARAMETER Credential
    The credentials for the VM administrator account

.PARAMETER ProvisionVMAgent
    Whether to provision the VM agent (default: true)

.PARAMETER Windows
    Specifies this is a Windows VM (default: true)

.EXAMPLE
    $vm = Get-AzVM -ResourceGroupName "MyRG" -Name "MyVM"
    $cred = Get-Credential
    $updatedVM = Invoke-AzVMOperatingSystem -VirtualMachine $vm -ComputerName "MyComputer" -Credential $cred

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VirtualMachine,

    [Parameter(Mandatory = $true)]
    [string]$ComputerName,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [bool]$ProvisionVMAgent = $true,

    [Parameter(Mandatory = $false)]
    [bool]$Windows = $true
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

function Invoke-AzVMOperatingSystem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VirtualMachine,

        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [bool]$ProvisionVMAgent = $true,

        [Parameter(Mandatory = $false)]
        [bool]$Windows = $true
    )

    try {
        Write-Verbose "Configuring operating system settings for VM: $($VirtualMachine.Name)"

        $SetAzVMOperatingSystemSplat = @{
            VM               = $VirtualMachine
            Windows          = $Windows
            ComputerName     = $ComputerName
            Credential       = $Credential
            ProvisionVMAgent = $ProvisionVMAgent
        }

        $UpdatedVirtualMachine = Set-AzVMOperatingSystem -ErrorAction Stop @SetAzVMOperatingSystemSplat

        Write-Output "Successfully configured operating system settings for VM: $($VirtualMachine.Name)"
        return $UpdatedVirtualMachine
    }
    catch {
        Write-Error "Failed to configure VM operating system: $_"
        throw
    }
}

# Execute the function with script parameters
Invoke-AzVMOperatingSystem -VirtualMachine $VirtualMachine -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent $ProvisionVMAgent -Windows $Windows