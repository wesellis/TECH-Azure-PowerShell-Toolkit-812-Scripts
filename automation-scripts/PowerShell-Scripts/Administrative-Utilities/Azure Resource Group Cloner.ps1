<#
.SYNOPSIS
    Azure Resource Group Cloner

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
    We Enhanced Azure Resource Group Cloner

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
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESourceResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETargetResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETargetLocation,
    
    [Parameter(Mandatory=$false)]
    [switch]$WEExportOnly,
    
    [Parameter(Mandatory=$false)]
    [string]$WEExportPath = " .\rg-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

Import-Module (Join-Path $WEPSScriptRoot " ..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1" ) -Force
Show-Banner -ScriptName " Azure Resource Group Cloner" -Version " 1.0" -Description " Clone resource groups and their contents"

try {
    if (-not (Test-AzureConnection)) { throw " Azure connection validation failed" }

    $sourceRG = Get-AzResourceGroup -Name $WESourceResourceGroupName
    if (-not $WETargetLocation) { $WETargetLocation = $sourceRG.Location }

    Write-Log " 📤 Exporting resource group template..." -Level INFO
    $null = Export-AzResourceGroup -ResourceGroupName $WESourceResourceGroupName -Path $WEExportPath
    Write-Log " ✓ Template exported to: $WEExportPath" -Level SUCCESS

    if (-not $WEExportOnly) {
        Write-Log " 🏗️ Creating target resource group..." -Level INFO
       ;  $null = New-AzResourceGroup -Name $WETargetResourceGroupName -Location $WETargetLocation -Tag $sourceRG.Tags
        Write-Log " ✓ Target resource group created: $WETargetResourceGroupName" -Level SUCCESS
        
        Write-Log " 🚀 Deploying resources to target..." -Level INFO
       ;  $deployment = New-AzResourceGroupDeployment -ResourceGroupName $WETargetResourceGroupName -TemplateFile $WEExportPath
        
        if ($deployment.ProvisioningState -eq " Succeeded" ) {
            Write-Log " ✅ Resource group cloned successfully!" -Level SUCCESS
        } else {
            Write-Log " ❌ Deployment failed: $($deployment.ProvisioningState)" -Level ERROR
        }
    }

} catch {
    Write-Log " ❌ Resource group cloning failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================