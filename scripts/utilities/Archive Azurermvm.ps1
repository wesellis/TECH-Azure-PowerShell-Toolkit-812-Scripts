#Requires -Version 7.4
#Requires -Modules Az.Resources, Az.Compute, Az.Storage

<#
.SYNOPSIS
    Archive Azure Virtual Machines

.DESCRIPTION
    Archives or rehydrates Azure Virtual Machines from specified resource group to save VM core allotment.
    Removes VMs from a subscription leaving the VHDs, NICs and other assets along with a JSON configuration
    file that can be used later to recreate the environment using the -Rehydrate switch.

.PARAMETER ResourceGroupName
    Name of resource group containing VMs to archive/rehydrate

.PARAMETER Rehydrate
    Switch to rebuild VMs from configuration file

.PARAMETER Environment
    Name of the Azure Environment (AzureCloud, AzureUSGovernment, AzureGermanCloud, AzureChinaCloud)

.EXAMPLE
    .\Archive-Azurermvm.ps1 -ResourceGroupName 'CONTOSO'
    Archives all VMs in the CONTOSO resource group.

.EXAMPLE
    .\Archive-Azurermvm.ps1 -ResourceGroupName 'CONTOSO' -Rehydrate
    Rehydrates the VMs using the saved configuration and remaining resource group components.

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules

    Original concept by: https://github.com/JeffBow
    Copyright (C) 2017 Microsoft Corporation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Enter the name of the Azure Resource Group")]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(HelpMessage = "Use this switch to rebuild VMs from saved configuration")]
    [switch]$Rehydrate,

    [Parameter(HelpMessage = "Azure Environment name")]
    [ValidateSet('AzureCloud', 'AzureUSGovernment', 'AzureGermanCloud', 'AzureChinaCloud')]
    [string]$Environment = 'AzureCloud'
)

$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
$ProgressPreference = 'SilentlyContinue'

# Check Az module version
try {
    $azModule = Get-Module -Name Az -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $azModule) {
        throw "Az PowerShell module not found. Please install the Az module."
    }
    Write-Output "Using Az PowerShell module version: $($azModule.Version)"
}
catch {
    Write-Error "Failed to validate Az module: $($_.Exception.Message)"
    throw
}

# Connect to Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Output "Connecting to Azure Environment: $Environment"
        Connect-AzAccount -Environment $Environment -ErrorAction Stop
    } else {
        Write-Output "Using existing Azure context for subscription: $($context.Subscription.Name)"
    }
}
catch {
    Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
    throw
}

# Verify resource group exists
try {
    $resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    Write-Output "Found resource group: $($resourceGroup.ResourceGroupName) in location: $($resourceGroup.Location)"
}
catch {
    Write-Error "Resource group '$ResourceGroupName' not found: $($_.Exception.Message)"
    throw
}

$configFileName = "$ResourceGroupName-VMConfig.json"
$configFilePath = Join-Path $PWD $configFileName

if ($Rehydrate) {
    # Rehydrate VMs from configuration
    try {
        if (-not (Test-Path $configFilePath)) {
            throw "Configuration file '$configFilePath' not found. Cannot rehydrate VMs."
        }

        Write-Output "Reading VM configuration from: $configFilePath"
        $vmConfigs = Get-Content $configFilePath | ConvertFrom-Json

        foreach ($vmConfig in $vmConfigs) {
            Write-Output "Rehydrating VM: $($vmConfig.Name)"

            # Create VM configuration
            $vmConfigObj = New-AzVMConfig -VMName $vmConfig.Name -VMSize $vmConfig.Size

            # Set OS disk
            if ($vmConfig.OSType -eq "Windows") {
                Set-AzVMOSDisk -VM $vmConfigObj -Name $vmConfig.OSDiskName -VhdUri $vmConfig.OSDiskUri -CreateOption Attach -Windows
            } else {
                Set-AzVMOSDisk -VM $vmConfigObj -Name $vmConfig.OSDiskName -VhdUri $vmConfig.OSDiskUri -CreateOption Attach -Linux
            }

            # Add data disks
            foreach ($dataDisk in $vmConfig.DataDisks) {
                Add-AzVMDataDisk -VM $vmConfigObj -Name $dataDisk.Name -VhdUri $dataDisk.Uri -CreateOption Attach -Lun $dataDisk.Lun
            }

            # Set network interface
            $nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $vmConfig.NetworkInterfaceName
            Add-AzVMNetworkInterface -VM $vmConfigObj -Id $nic.Id

            # Create the VM
            New-AzVM -ResourceGroupName $ResourceGroupName -Location $resourceGroup.Location -VM $vmConfigObj -ErrorAction Stop
            Write-Output "Successfully rehydrated VM: $($vmConfig.Name)"
        }

        Write-Output "VM rehydration completed successfully"
    }
    catch {
        Write-Error "Failed to rehydrate VMs: $($_.Exception.Message)"
        throw
    }
} else {
    # Archive VMs
    try {
        $vms = Get-AzVM -ResourceGroupName $ResourceGroupName -ErrorAction Stop

        if ($vms.Count -eq 0) {
            Write-Output "No VMs found in resource group '$ResourceGroupName'"
            return
        }

        Write-Output "Found $($vms.Count) VMs to archive"
        $vmConfigs = @()

        foreach ($vm in $vms) {
            Write-Output "Archiving VM: $($vm.Name)"

            # Get VM details
            $vmDetail = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -ErrorAction Stop

            # Create configuration object
            $vmConfig = @{
                Name = $vm.Name
                Size = $vm.HardwareProfile.VmSize
                OSType = $vm.StorageProfile.OsDisk.OsType
                OSDiskName = $vm.StorageProfile.OsDisk.Name
                OSDiskUri = $vm.StorageProfile.OsDisk.Vhd.Uri
                NetworkInterfaceName = (Get-AzResource -ResourceId $vm.NetworkProfile.NetworkInterfaces[0].Id).Name
                DataDisks = @()
            }

            # Get data disks
            foreach ($dataDisk in $vm.StorageProfile.DataDisks) {
                $vmConfig.DataDisks += @{
                    Name = $dataDisk.Name
                    Uri = $dataDisk.Vhd.Uri
                    Lun = $dataDisk.Lun
                }
            }

            $vmConfigs += $vmConfig

            # Remove the VM (but keep disks and other resources)
            Write-Output "Removing VM: $($vm.Name) (keeping disks and network resources)"
            Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Force -ErrorAction Stop
        }

        # Save configuration to file
        Write-Output "Saving VM configuration to: $configFilePath"
        $vmConfigs | ConvertTo-Json -Depth 10 | Out-File -FilePath $configFilePath

        Write-Output "VM archival completed successfully. Configuration saved to: $configFilePath"
        Write-Output "To rehydrate VMs later, run: .\Archive-Azurermvm.ps1 -ResourceGroupName '$ResourceGroupName' -Rehydrate"
    }
    catch {
        Write-Error "Failed to archive VMs: $($_.Exception.Message)"
        throw
    }
}