#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Network Info

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
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$VmName
)
Write-Output "Retrieving network information for VM: $VmName"
$VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
Write-Output " `nNetwork Interfaces:"
foreach ($NicRef in $VM.NetworkProfile.NetworkInterfaces) {
    [string]$NicId = $NicRef.Id
$Nic = Get-AzNetworkInterface -ResourceId $NicId
    Write-Output "NIC: $($Nic.Name)"
    Write-Output "Private IP: $($Nic.IpConfigurations[0].PrivateIpAddress)"
    Write-Output "Subnet: $($Nic.IpConfigurations[0].Subnet.Id.Split('/')[-1])"
    if ($Nic.IpConfigurations[0].PublicIpAddress) {
    [string]$PipId = $Nic.IpConfigurations[0].PublicIpAddress.Id
$Pip = Get-AzPublicIpAddress -ResourceId $PipId
        Write-Output "Public IP: $($Pip.IpAddress)"
    }
}
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
