#Requires -Version 7.4
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Create DNS Forwarder Resources

.DESCRIPTION
    Azure automation script to create DNS forwarder resources including VMs and resource groups.
    Deploys two DNS proxy VMs using an ARM template.

.PARAMETER ResourceGroupName
    Name of the resource group to create (default: 'DnsForwardExample')

.PARAMETER Location
    Azure location for resources (default: 'northeurope')

.PARAMETER VmNamePrefix
    Prefix for VM names (default: 'dnsproxy')

.PARAMETER AdminUsername
    Administrator username for VMs (default: 'mradmin')

.PARAMETER AdminPassword
    Administrator password for VMs (SecureString)

.PARAMETER TemplateFile
    Path to the ARM template file

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.NOTES
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName = 'DnsForwardExample',

    [Parameter(Mandatory = $false)]
    [string]$Location = 'northeurope',

    [Parameter(Mandatory = $false)]
    [string]$VmNamePrefix = 'dnsproxy',

    [Parameter(Mandatory = $false)]
    [string]$AdminUsername = 'mradmin',

    [Parameter(Mandatory = $true)]
    [SecureString]$AdminPassword,

    [Parameter(Mandatory = $false)]
    [string]$TemplateFile
)

$ErrorActionPreference = 'Stop'

try {
    Write-Output "Starting DNS forwarder deployment..."

    # Set template file path if not provided
    if (-not $TemplateFile) {
        $ScriptDir = Split-Path $MyInvocation.MyCommand.Path
        $TemplateFile = Join-Path $ScriptDir "azuredeploy.json"
    }

    # Validate template file exists
    if (-not (Test-Path $TemplateFile)) {
        throw "Template file not found: $TemplateFile"
    }

    # Connect to Azure (if not already connected)
    $context = Get-AzContext
    if (-not $context) {
        Write-Output "Not connected to Azure. Please run Connect-AzAccount first."
        throw "Not connected to Azure"
    }

    # Create resource group
    Write-Output "Creating resource group: $ResourceGroupName in $Location"
    $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

    # Convert secure password to plain text for template (required for ARM template)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AdminPassword)
    $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Create storage account name
    $storageAccName = "$($ResourceGroupName.ToLower())stor"
    if ($storageAccName.Length -gt 24) {
        $storageAccName = $storageAccName.Substring(0, 24)
    }
    $storageAccName = $storageAccName -replace '[^a-z0-9]', ''

    # Deploy first DNS proxy VM
    Write-Output "Deploying first DNS proxy VM: ${VmNamePrefix}1"
    $params1 = @{
        vmName = "${VmNamePrefix}1"
        adminUsername = $AdminUsername
        adminPassword = $PlainPassword
        storageAccName = $storageAccName
    }

    $deployment1 = New-AzResourceGroupDeployment `
        -Name "${ResourceGroupName}-vm1" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterObject $params1 `
        -Force

    Write-Output "First VM deployment completed: $($deployment1.ProvisioningState)"

    # Deploy second DNS proxy VM
    Write-Output "Deploying second DNS proxy VM: ${VmNamePrefix}2"
    $params2 = @{
        vmName = "${VmNamePrefix}2"
        adminUsername = $AdminUsername
        adminPassword = $PlainPassword
        storageAccName = $storageAccName
    }

    $deployment2 = New-AzResourceGroupDeployment `
        -Name "${ResourceGroupName}-vm2" `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterObject $params2 `
        -Force

    Write-Output "Second VM deployment completed: $($deployment2.ProvisioningState)"

    # Clear sensitive data
    Clear-Variable -Name PlainPassword -Force -ErrorAction SilentlyContinue
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

    Write-Output "DNS forwarder deployment completed successfully"
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
finally {
    # Clean up sensitive variables
    if ($BSTR) {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
    Clear-Variable -Name PlainPassword -Force -ErrorAction SilentlyContinue
}