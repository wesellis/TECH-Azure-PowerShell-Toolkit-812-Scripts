#Requires -Version 7.4

<#`n.SYNOPSIS
    Azure Vm Scaleset Creator

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
    [ValidateNotNullOrEmpty()]
    [string]$ScaleSetName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$VmSize,
    [Parameter()]
    [int]$InstanceCount = 2
)
Write-Output "Creating VM Scale Set: $ScaleSetName"
$params = @{
    ErrorAction = "Stop"
    SkuCapacity = $InstanceCount
    SkuName = $VmSize
    UpgradePolicyMode = "Manual"
    Location = $Location
}
    [string]$VmssConfig @params
$params = @{
    CreatePublicIPAddress = $false
    IPConfigurationName = " internal"
    Primary = $true
    Name = " network-config"
    VirtualMachineScaleSet = $VmssConfig
}
    [string]$VmssConfig @params
$params = @{
    ComputerNamePrefix = " vmss"
    ErrorAction = "Stop"
    AdminUsername = " azureuser"
    VirtualMachineScaleSet = $VmssConfig
}
    [string]$VmssConfig @params
$params = @{
    ImageReferenceOffer = "WindowsServer"
    ImageReferenceSku = " 2022-Datacenter"
    ErrorAction = "Stop"
    OsDiskCreateOption = "FromImage"
    VirtualMachineScaleSet = $VmssConfig
    ImageReferenceVersion = " latest"
    ImageReferencePublisher = "MicrosoftWindowsServer"
}
    [string]$VmssConfig @params
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $ScaleSetName
    VirtualMachineScaleSet = $VmssConfig
}
    [string]$Vmss @params
Write-Output "VM Scale Set created successfully:"
Write-Output "Name: $($Vmss.Name)"
Write-Output "Location: $($Vmss.Location)"
Write-Output "VM Size: $VmSize"
Write-Output "Instance Count: $InstanceCount"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
