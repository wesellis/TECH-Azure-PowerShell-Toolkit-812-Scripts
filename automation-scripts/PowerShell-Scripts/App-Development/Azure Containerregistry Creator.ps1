<#
.SYNOPSIS
    We Enhanced Azure Containerregistry Creator

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
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WERegistryName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    
    [Parameter(Mandatory=$false)]
    [string]$WESku = " Basic"
)

Write-WELog " Creating Container Registry: $WERegistryName" " INFO"

$WERegistry = New-AzContainerRegistry `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WERegistryName `
    -Location $WELocation `
    -Sku $WESku `
    -EnableAdminUser

Write-WELog " ✅ Container Registry created successfully:" " INFO"
Write-WELog "  Name: $($WERegistry.Name)" " INFO"
Write-WELog "  Login Server: $($WERegistry.LoginServer)" " INFO"
Write-WELog "  Location: $($WERegistry.Location)" " INFO"
Write-WELog "  SKU: $($WERegistry.Sku.Name)" " INFO"
Write-WELog "  Admin Enabled: $($WERegistry.AdminUserEnabled)" " INFO"

; 
$WECreds = Get-AzContainerRegistryCredential -ResourceGroupName $WEResourceGroupName -Name $WERegistryName
Write-WELog " `nAdmin Credentials:" " INFO"
Write-WELog "  Username: $($WECreds.Username)" " INFO"
Write-WELog "  Password: $($WECreds.Password)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}
