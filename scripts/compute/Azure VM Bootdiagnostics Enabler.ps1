#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Bootdiagnostics Enabler

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
    [Parameter()]
    [string]$StorageAccountName
)
Write-Output "Enabling boot diagnostics for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
if ($StorageAccountName) {
    Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
    Write-Output "Using storage account: $StorageAccountName"
} else {
    Set-AzVMBootDiagnostic -VM $VM -Enable
    Write-Output "Using managed storage"
}
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Output "Boot diagnostics enabled successfully:"
Write-Output "VM: $VmName"
Write-Output "Resource Group: $ResourceGroupName"
if ($StorageAccountName) {
    Write-Output "Storage Account: $StorageAccountName"
}
Write-Output "Status: Enabled"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
