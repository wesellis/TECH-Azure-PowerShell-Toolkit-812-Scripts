#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Extension Manager

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
;
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ExtensionName,
    [Parameter()]
    [string]$ExtensionType = "CustomScriptExtension" ,
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
    TypeHandlerVersion = " 1.10"
    ErrorAction = "Stop"
    VMName = $VmName
}
Set-AzVMExtension @params
Write-Output "Extension '$ExtensionName' installed successfully"
Write-Output "VM: $VmName"
Write-Output "Publisher: $Publisher"
Write-Output "Type: $ExtensionType"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
