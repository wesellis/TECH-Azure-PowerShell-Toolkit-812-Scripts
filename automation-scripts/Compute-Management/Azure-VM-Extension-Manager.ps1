<#
.SYNOPSIS
    Manage VM extensions

.DESCRIPTION
    Manage VM extensions\n    Author: Wes Ellis (wes@wesellis.com)\n#>
param (
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
Write-Host "Managing VM extension: $ExtensionName"
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
Write-Host "Extension '$ExtensionName' installed successfully"
Write-Host "VM: $VmName"
Write-Host "Publisher: $Publisher"
Write-Host "Type: $ExtensionType"\n