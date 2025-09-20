<#
.SYNOPSIS
    Azure Vm Bootdiagnostics Enabler

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
[CmdletBinding()];
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
Write-Host "Enabling boot diagnostics for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
if ($StorageAccountName) {
    Set-AzVMBootDiagnostic -VM $VM -Enable -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName
    Write-Host "Using storage account: $StorageAccountName"
} else {
    Set-AzVMBootDiagnostic -VM $VM -Enable
    Write-Host "Using managed storage"
}
Update-AzVM -ResourceGroupName $ResourceGroupName -VM $VM
Write-Host "Boot diagnostics enabled successfully:"
Write-Host "VM: $VmName"
Write-Host "Resource Group: $ResourceGroupName"
if ($StorageAccountName) {
    Write-Host "Storage Account: $StorageAccountName"
}
Write-Host "Status: Enabled"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

