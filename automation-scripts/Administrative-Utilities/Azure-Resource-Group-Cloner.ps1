#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
# Azure Resource Group Cloner
# Clone entire resource groups with all resources
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

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName "Azure Resource Group Cloner" -Version "1.0" -Description "Clone resource groups and their contents"

try {
    if (-not (Test-AzureConnection)) { throw "Azure connection validation failed" }

    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    if (-not $TargetLocation) { $TargetLocation = $sourceRG.Location }

    Write-Log "📤 Exporting resource group template..." -Level INFO
    $null = Export-AzResourceGroup -ResourceGroupName $SourceResourceGroupName -Path $ExportPath
    Write-Log "[OK] Template exported to: $ExportPath" -Level SUCCESS

    if (-not $ExportOnly) {
        Write-Log " Creating target resource group..." -Level INFO
        $null = New-AzResourceGroup -Name $TargetResourceGroupName -Location $TargetLocation -Tag $sourceRG.Tags
        Write-Log "[OK] Target resource group created: $TargetResourceGroupName" -Level SUCCESS
        
        Write-Log " Deploying resources to target..." -Level INFO
        $deployment = New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroupName -TemplateFile $ExportPath
        
        if ($deployment.ProvisioningState -eq "Succeeded") {
            Write-Log " Resource group cloned successfully!" -Level SUCCESS
        } else {
            Write-Log " Deployment failed: $($deployment.ProvisioningState)" -Level ERROR
        }
    }

} catch {
    Write-Log " Resource group cloning failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}


#endregion
