#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Vm Scaleset Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

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
    Wes Ellis (wes@wesellis.com)

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

#region Functions

Write-WELog " Creating VM Scale Set: $WEScaleSetName" " INFO"


$params = @{
    ErrorAction = "Stop"
    SkuCapacity = $WEInstanceCount
    SkuName = $WEVmSize
    UpgradePolicyMode = " Manual"
    Location = $WELocation
}
$WEVmssConfig @params


$params = @{
    CreatePublicIPAddress = $false
    IPConfigurationName = " internal"
    Primary = $true
    Name = " network-config"
    VirtualMachineScaleSet = $WEVmssConfig
}
$WEVmssConfig @params


$params = @{
    ComputerNamePrefix = " vmss"
    ErrorAction = "Stop"
    AdminUsername = " azureuser"
    VirtualMachineScaleSet = $WEVmssConfig
}
$WEVmssConfig @params

; 
$params = @{
    ImageReferenceOffer = " WindowsServer"
    ImageReferenceSku = " 2022-Datacenter"
    ErrorAction = "Stop"
    OsDiskCreateOption = " FromImage"
    VirtualMachineScaleSet = $WEVmssConfig
    ImageReferenceVersion = " latest"
    ImageReferencePublisher = " MicrosoftWindowsServer"
}
$WEVmssConfig @params

; 
$params = @{
    ErrorAction = "Stop"
    ResourceGroupName = $WEResourceGroupName
    Name = $WEScaleSetName
    VirtualMachineScaleSet = $WEVmssConfig
}
$WEVmss @params

Write-WELog "  VM Scale Set created successfully:" " INFO"
Write-WELog "  Name: $($WEVmss.Name)" " INFO"
Write-WELog "  Location: $($WEVmss.Location)" " INFO"
Write-WELog "  VM Size: $WEVmSize" " INFO"
Write-WELog "  Instance Count: $WEInstanceCount" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}


#endregion
