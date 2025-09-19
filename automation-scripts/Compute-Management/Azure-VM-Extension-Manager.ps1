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
    [string]$VmName,
    
    [Parameter(Mandatory=$true)]
    [string]$ExtensionName,
    
    [Parameter(Mandatory=$false)]
    [string]$ExtensionType = "CustomScriptExtension",
    
    [Parameter(Mandatory=$false)]
    [string]$Publisher = "Microsoft.Compute"
)

#region Functions

Write-Information "Managing VM extension: $ExtensionName"

$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName

# Install extension
$params = @{
    ResourceGroupName = $ResourceGroupName
    Publisher = $Publisher
    Name = $ExtensionName
    ExtensionType = $ExtensionType
    Location = $VM.Location
    TypeHandlerVersion = "1.10"
    ErrorAction = "Stop"
    VMName = $VmName
}
Set-AzVMExtension @params

Write-Information " Extension '$ExtensionName' installed successfully"
Write-Information "VM: $VmName"
Write-Information "Publisher: $Publisher"
Write-Information "Type: $ExtensionType"


#endregion
