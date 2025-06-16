# Azure App Configuration Service Manager
# Professional configuration management for modern applications
# Author: Wesley Ellis | wes@wesellis.com
# Version: 1.0 | Centralized application configuration

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ConfigStoreName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Create", "AddKey", "GetKey", "DeleteKey", "ListKeys", "ImportFromFile")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$KeyName,
    
    [Parameter(Mandatory=$false)]
    [string]$KeyValue,
    
    [Parameter(Mandatory=$false)]
    [string]$Label,
    
    [Parameter(Mandatory=$false)]
    [string]$ContentType = "text/plain",
    
    [Parameter(Mandatory=$false)]
    [hashtable]$Tags = @{},
    
    [Parameter(Mandatory=$false)]
    [string]$ImportFilePath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Free", "Standard")]
    [string]$Sku = "Standard"
)

# Import common functions
Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force

Show-Banner -ScriptName "Azure App Configuration Service Manager" -Version "1.0" -Description "Centralized configuration management for modern applications"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 4 -StepName "Connection" -Status "Validating Azure connection"
    if (-not (Test-AzureConnection -RequiredModules @('Az.AppConfiguration'))) {
        throw "Azure connection validation failed"
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 4 -StepName "Configuration Action" -Status "Executing $Action"
    
    switch ($Action) {
        "Create" {
            Write-Log "🏗️ Creating App Configuration store..." -Level INFO
            
            $configStore = New-AzAppConfigurationStore `
                -ResourceGroupName $ResourceGroupName `
                -Name $ConfigStoreName `
                -Location $Location `
                -Sku $Sku `
                -Tag $Tags
            
            Write-Log "✓ App Configuration store created: $ConfigStoreName" -Level SUCCESS
        }
        
        "AddKey" {
            Write-Log "🔑 Adding configuration key..." -Level INFO
            
            $keyParams = @{
                Endpoint = "https://$ConfigStoreName.azconfig.io"
                Key = $KeyName
                Value = $KeyValue
            }
            
            if ($Label) { $keyParams.Label = $Label }
            if ($ContentType) { $keyParams.ContentType = $ContentType }
            if ($Tags.Count -gt 0) { $keyParams.Tag = $Tags }
            
            Set-AzAppConfigurationKeyValue @keyParams
            Write-Log "✓ Configuration key added: $KeyName" -Level SUCCESS
        }
        
        "GetKey" {
            Write-Log "📖 Retrieving configuration key..." -Level INFO
            
            $key = Get-AzAppConfigurationKeyValue -Endpoint "https://$ConfigStoreName.azconfig.io" -Key $KeyName
            Write-Host "Key: $($key.Key)" -ForegroundColor Cyan
            Write-Host "Value: $($key.Value)" -ForegroundColor Green
            Write-Host "Label: $($key.Label)" -ForegroundColor White
        }
        
        "ListKeys" {
            Write-Log "📋 Listing all configuration keys..." -Level INFO
            
            $keys = Get-AzAppConfigurationKeyValue -Endpoint "https://$ConfigStoreName.azconfig.io"
            $keys | Format-Table Key, Value, Label, ContentType
        }
    }

    Write-ProgressStep -StepNumber 3 -TotalSteps 4 -StepName "Validation" -Status "Validating configuration"
    
    # Validate the configuration store
    $store = Get-AzAppConfigurationStore -ResourceGroupName $ResourceGroupName -Name $ConfigStoreName
    
    Write-ProgressStep -StepNumber 4 -TotalSteps 4 -StepName "Summary" -Status "Generating summary"

    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                              APP CONFIGURATION OPERATION COMPLETE" -ForegroundColor Green  
    Write-Host "════════════════════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "⚙️ Configuration Store: $ConfigStoreName" -ForegroundColor Cyan
    Write-Host "🌍 Endpoint: https://$ConfigStoreName.azconfig.io" -ForegroundColor Yellow
    Write-Host "📍 Location: $($store.Location)" -ForegroundColor White
    Write-Host "💰 SKU: $($store.Sku.Name)" -ForegroundColor White
    Write-Host ""

    Write-Log "✅ App Configuration operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log "❌ App Configuration operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity "App Configuration Management" -Completed