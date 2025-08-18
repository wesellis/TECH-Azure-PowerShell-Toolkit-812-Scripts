<#
.SYNOPSIS
    We Enhanced Azure Vm Network Info

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$WEVmName
)

Write-WELog " Retrieving network information for VM: $WEVmName" " INFO"

$WEVM = Get-AzVM -ResourceGroupName $WEResourceGroupName -Name $WEVmName

Write-WELog " `nNetwork Interfaces:" " INFO"
foreach ($WENicRef in $WEVM.NetworkProfile.NetworkInterfaces) {
    $WENicId = $WENicRef.Id
    $WENic = Get-AzNetworkInterface -ResourceId $WENicId
    
    Write-WELog "  NIC: $($WENic.Name)" " INFO"
    Write-WELog "  Private IP: $($WENic.IpConfigurations[0].PrivateIpAddress)" " INFO"
    Write-WELog "  Subnet: $($WENic.IpConfigurations[0].Subnet.Id.Split('/')[-1])" " INFO"
    
    if ($WENic.IpConfigurations[0].PublicIpAddress) {
        $WEPipId = $WENic.IpConfigurations[0].PublicIpAddress.Id
       ;  $WEPip = Get-AzPublicIpAddress -ResourceId $WEPipId
        Write-WELog "  Public IP: $($WEPip.IpAddress)" " INFO"
    }
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
