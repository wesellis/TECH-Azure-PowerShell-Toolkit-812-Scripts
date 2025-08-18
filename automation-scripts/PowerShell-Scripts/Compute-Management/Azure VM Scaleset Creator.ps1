<#
.SYNOPSIS
    Azure Vm Scaleset Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Vm Scaleset Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



[CmdletBinding()]
function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Information $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEScaleSetName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEVmSize,
    
    [Parameter(Mandatory=$false)]
    [int]$WEInstanceCount = 2
)

Write-WELog " Creating VM Scale Set: $WEScaleSetName" " INFO"


$WEVmssConfig = New-AzVmssConfig -ErrorAction Stop `
    -Location $WELocation `
    -SkuCapacity $WEInstanceCount `
    -SkuName $WEVmSize `
    -UpgradePolicyMode " Manual"


$WEVmssConfig = Add-AzVmssNetworkInterfaceConfiguration `
    -VirtualMachineScaleSet $WEVmssConfig `
    -Name " network-config" `
    -Primary $true `
    -IPConfigurationName " internal" `
    -CreatePublicIPAddress $false


$WEVmssConfig = Set-AzVmssOsProfile -ErrorAction Stop `
    -VirtualMachineScaleSet $WEVmssConfig `
    -ComputerNamePrefix " vmss" `
    -AdminUsername " azureuser"

; 
$WEVmssConfig = Set-AzVmssStorageProfile -ErrorAction Stop `
    -VirtualMachineScaleSet $WEVmssConfig `
    -OsDiskCreateOption " FromImage" `
    -ImageReferencePublisher " MicrosoftWindowsServer" `
    -ImageReferenceOffer " WindowsServer" `
    -ImageReferenceSku " 2022-Datacenter" `
    -ImageReferenceVersion " latest"

; 
$WEVmss = New-AzVmss -ErrorAction Stop `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEScaleSetName `
    -VirtualMachineScaleSet $WEVmssConfig

Write-WELog " ✅ VM Scale Set created successfully:" " INFO"
Write-WELog "  Name: $($WEVmss.Name)" " INFO"
Write-WELog "  Location: $($WEVmss.Location)" " INFO"
Write-WELog "  VM Size: $WEVmSize" " INFO"
Write-WELog "  Instance Count: $WEInstanceCount" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
