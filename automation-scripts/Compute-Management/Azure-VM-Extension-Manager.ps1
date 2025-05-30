# ============================================================================
# Script Name: Azure VM Extension Manager
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Installs and manages Azure VM extensions
# ============================================================================

param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$VmName,
    
    [Parameter(Mandatory=$true)]
    [string]$ExtensionName,
    
    [Parameter(Mandatory=$false)]
    [string]$ExtensionType = "CustomScriptExtension",
    
    [Parameter(Mandatory=$false)]
    [string]$Publisher = "Microsoft.Compute"
)

Write-Host "Managing VM extension: $ExtensionName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

# Install extension
Set-AzVMExtension `
    -ResourceGroupName $ResourceGroupName `
    -VMName $VmName `
    -Name $ExtensionName `
    -Publisher $Publisher `
    -ExtensionType $ExtensionType `
    -TypeHandlerVersion "1.10" `
    -Location $VM.Location

Write-Host "✅ Extension '$ExtensionName' installed successfully"
Write-Host "VM: $VmName"
Write-Host "Publisher: $Publisher"
Write-Host "Type: $ExtensionType"
