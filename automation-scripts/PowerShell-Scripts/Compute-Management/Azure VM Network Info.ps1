#Requires -Version 7.0
#Requires -Modules Az.Compute

<#
.SYNOPSIS
    Azure Vm Network Info

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
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
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName
)
Write-Host "Retrieving network information for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
Write-Host " `nNetwork Interfaces:"
foreach ($NicRef in $VM.NetworkProfile.NetworkInterfaces) {
    $NicId = $NicRef.Id
    $Nic = Get-AzNetworkInterface -ResourceId $NicId
    Write-Host "NIC: $($Nic.Name)"
    Write-Host "Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
    Write-Host "Subnet: $($Nic.IpConfigurations[0].Subnet.Id.Split('/')[-1])"
    if ($Nic.IpConfigurations[0].PublicIpAddress) {
$PipId = $Nic.IpConfigurations[0].PublicIpAddress.Id
$Pip = Get-AzPublicIpAddress -ResourceId $PipId
        Write-Host "Public IP: $($Pip.IpAddress)"
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

