#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Manage VM extensions

.DESCRIPTION
    Manage VM extensions


    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName,
    [Parameter(Mandatory)]
    [string]$ExtensionName,
    [Parameter()]
    [string]$ExtensionType = "CustomScriptExtension",
    [Parameter()]
    [string]$Publisher = "Microsoft.Compute"
)
Write-Output "Managing VM extension: $ExtensionName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
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
Write-Output "Extension '$ExtensionName' installed successfully"
Write-Output "VM: $VmName"
Write-Output "Publisher: $Publisher"
Write-Output "Type: $ExtensionType"



