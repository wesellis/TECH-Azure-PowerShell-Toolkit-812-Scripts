#Requires -Version 7.4
#Requires -Modules Az.Resources
#Requires -Modules Az.Compute

<#`n.SYNOPSIS
    Azure Vm Provisioning Tool

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VmName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$VmSize = "Standard_B2s" ,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUsername,
    [securestring]$AdminPassword,
    [string]$ImagePublisher = "MicrosoftWindowsServer" ,
    [string]$ImageOffer = "WindowsServer" ,
    [string]$ImageSku = " 2022-Datacenter"
)
Write-Output "Provisioning Virtual Machine: $VmName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "VM Size: $VmSize"
$VmConfig = New-AzVMConfig -VMName $VmName -VMSize $VmSize
$VmoperatingsystemSplat = @{
    VM = $VmConfig
    ComputerName = $VmName
    ErrorAction = Stop PSCredential($AdminUsername, $AdminPassword))
}
Set-AzVMOperatingSystem @vmoperatingsystemSplat
$VmsourceimageSplat = @{
    VM = $VmConfig
    PublisherName = $ImagePublisher
    Offer = $ImageOffer
    Skus = $ImageSku
    Version = " latest"
}
Set-AzVMSourceImage @vmsourceimageSplat
$VmSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    VM = $VmConfig
}
New-AzVM @vmSplat
Write-Output "Virtual Machine $VmName provisioned successfully"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
