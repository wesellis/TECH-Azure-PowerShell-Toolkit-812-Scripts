<#
.SYNOPSIS
    Azure Vm Provisioning Tool

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
Write-Host "Provisioning Virtual Machine: $VmName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "VM Size: $VmSize"
$VmConfig = New-AzVMConfig -VMName $VmName -VMSize $VmSize
$vmoperatingsystemSplat = @{
    VM = $VmConfig
    ComputerName = $VmName
    ErrorAction = Stop PSCredential($AdminUsername, $AdminPassword))
}
Set-AzVMOperatingSystem @vmoperatingsystemSplat
$vmsourceimageSplat = @{
    VM = $VmConfig
    PublisherName = $ImagePublisher
    Offer = $ImageOffer
    Skus = $ImageSku
    Version = " latest"
}
Set-AzVMSourceImage @vmsourceimageSplat
$vmSplat = @{
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    VM = $VmConfig
}
New-AzVM @vmSplat
Write-Host "Virtual Machine $VmName provisioned successfully"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

