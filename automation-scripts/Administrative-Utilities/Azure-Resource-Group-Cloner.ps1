<#
.SYNOPSIS
    Manage resource groups

.DESCRIPTION
    Manage resource groups
    Author: Wes Ellis (wes@wesellis.com)#>
# Azure Resource Group Cloner
# Clone entire resource groups with all resources
param(
    [Parameter(Mandatory)]
    [string]$SourceResourceGroupName,
    [Parameter(Mandatory)]
    [string]$TargetResourceGroupName,
    [Parameter()]
    [string]$TargetLocation,
    [Parameter()]
    [switch]$ExportOnly,
    [Parameter()]
    [string]$ExportPath = ".\rg-export-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    if (-not (Get-AzContext)) { Connect-AzAccount }
    $sourceRG = Get-AzResourceGroup -Name $SourceResourceGroupName
    if (-not $TargetLocation) { $TargetLocation = $sourceRG.Location }
    
    $null = Export-AzResourceGroup -ResourceGroupName $SourceResourceGroupName -Path $ExportPath
    
    if (-not $ExportOnly) {
        
        $resourcegroupSplat = @{
    Name = $TargetResourceGroupName
    Location = $TargetLocation
    Tag = $sourceRG.Tags
}
New-AzResourceGroup @resourcegroupSplat
        
        $deployment = New-AzResourceGroupDeployment -ResourceGroupName $TargetResourceGroupName -TemplateFile $ExportPath
        if ($deployment.ProvisioningState -eq "Succeeded") {
            Write-Host "Deployment completed successfully" -ForegroundColor Green
        } else {
            Write-Host "Deployment failed" -ForegroundColor Red
        }
    }
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}

