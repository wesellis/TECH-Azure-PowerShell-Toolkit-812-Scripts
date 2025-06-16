# Azure Resource Group Cloner
# Clone entire resource groups with all resources
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0

param(
    [Parameter(Mandatory=$true)]
    [string]$SourceResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$TargetLocation,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportOnly,
    
    [Parameter(Mandatory=$false)]
    [string]$ExportPath = ".\rg-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Resource Group Cloner" -Version "1.0" -Description "Clone resource groups and their contents"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection validation failed" }

    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    if (-not $TargetLocation) { $TargetLocation = $sourceRG.Location }

    Write-Log "📤 Exporting resource group template..." -Level INFO
    $null = Export-AzResourceGroup -ResourceGroupName $SourceResourceGroupName -Path $ExportPath
    Write-Log "✓ Template exported to: $ExportPath" -Level SUCCESS

    if (-not $ExportOnly) {
        Write-Log "🏗️ Creating target resource group..." -Level INFO
        $null = New-AzResourceGroup -Name $TargetResourceGroupName -Location $TargetLocation -Tag $sourceRG.Tags
        Write-Log "✓ Target resource group created: $TargetResourceGroupName" -Level SUCCESS
        
        Write-Log "🚀 Deploying resources to target..." -Level INFO
        $deployment = New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroupName -TemplateFile $ExportPath
        
        if ($deployment.ProvisioningState -eq "Succeeded") {
            Write-Log "✅ Resource group cloned successfully!" -Level SUCCESS
        } else {
            Write-Log "❌ Deployment failed: $($deployment.ProvisioningState)" -Level ERROR
        }
    }

} catch {
    Write-Log "❌ Resource group cloning failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
