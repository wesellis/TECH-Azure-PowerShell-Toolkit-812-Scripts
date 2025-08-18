<#
.SYNOPSIS
    Azure Resourcegroup Creator

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
    We Enhanced Azure Resourcegroup Creator

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
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
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
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$WETags = @{}
)

Write-WELog " Creating Resource Group: $WEResourceGroupName" " INFO"

if ($WETags.Count -gt 0) {
   ;  $WEResourceGroup = New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation -Tag $WETags
    Write-WELog " Tags applied:" " INFO"
    foreach ($WETag in $WETags.GetEnumerator()) {
        Write-WELog "  $($WETag.Key): $($WETag.Value)" " INFO"
    }
} else {
   ;  $WEResourceGroup = New-AzResourceGroup -Name $WEResourceGroupName -Location $WELocation
}

Write-WELog " ✅ Resource Group created successfully:" " INFO"
Write-WELog "  Name: $($WEResourceGroup.ResourceGroupName)" " INFO"
Write-WELog "  Location: $($WEResourceGroup.Location)" " INFO"
Write-WELog "  Provisioning State: $($WEResourceGroup.ProvisioningState)" " INFO"
Write-WELog "  Resource ID: $($WEResourceGroup.ResourceId)" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
