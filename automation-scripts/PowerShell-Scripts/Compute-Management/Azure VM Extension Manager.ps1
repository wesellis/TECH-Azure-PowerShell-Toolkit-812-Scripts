<#
.SYNOPSIS
    Azure Vm Extension Manager

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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ExtensionName,
    [Parameter()]
    [string]$ExtensionType = "CustomScriptExtension" ,
    [Parameter()]
    [string]$Publisher = "Microsoft.Compute"
)
Write-Host "Managing VM extension: $ExtensionName"
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
Write-Host "Extension '$ExtensionName' installed successfully"
Write-Host "VM: $VmName"
Write-Host "Publisher: $Publisher"
Write-Host "Type: $ExtensionType"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

