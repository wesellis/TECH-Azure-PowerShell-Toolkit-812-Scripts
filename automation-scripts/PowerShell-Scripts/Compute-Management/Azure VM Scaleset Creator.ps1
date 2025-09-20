<#
.SYNOPSIS
    Azure Vm Scaleset Creator

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
Write-Host "Creating VM Scale Set: $ScaleSetName"
$params = @{
    ErrorAction = "Stop"
    SkuCapacity = $InstanceCount
    SkuName = $VmSize
    UpgradePolicyMode = "Manual"
    Location = $Location
}
$VmssConfig @params
$params = @{
    CreatePublicIPAddress = $false
    IPConfigurationName = " internal"
    Primary = $true
    Name = " network-config"
    VirtualMachineScaleSet = $VmssConfig
}
$VmssConfig @params
$params = @{
    ComputerNamePrefix = " vmss"
    ErrorAction = "Stop"
    AdminUsername = " azureuser"
    VirtualMachineScaleSet = $VmssConfig
}
$VmssConfig @params
$params = @{
    ImageReferenceOffer = "WindowsServer"
    ImageReferenceSku = " 2022-Datacenter"
    ErrorAction = "Stop"
    OsDiskCreateOption = "FromImage"
    VirtualMachineScaleSet = $VmssConfig
    ImageReferenceVersion = " latest"
    ImageReferencePublisher = "MicrosoftWindowsServer"
}
$VmssConfig @params
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $ResourceGroupName
    Name = $ScaleSetName
    VirtualMachineScaleSet = $VmssConfig
}
$Vmss @params
Write-Host "VM Scale Set created successfully:"
Write-Host "Name: $($Vmss.Name)"
Write-Host "Location: $($Vmss.Location)"
Write-Host "VM Size: $VmSize"
Write-Host "Instance Count: $InstanceCount"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n