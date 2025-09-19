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
# Azure App Configuration Service Manager
# Professional configuration management for modern applications
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

#region Functions

# Import common functions
# Module import removed - use #Requires instead

Show-Banner -ScriptName "Azure App Configuration Service Manager" -Version "1.0" -Description "Centralized configuration management for modern applications"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 4 -StepName "Connection" -Status "Validating Azure connection"
    if (-not (Test-AzureConnection -RequiredModules @('Az.AppConfiguration'))) {
        throw "Azure connection validation failed"
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 4 -StepName "Configuration Action" -Status "Executing $Action"
    
    switch ($Action) {
        "Create" {
            Write-Log " Creating App Configuration store..." -Level INFO
            
            $params = @{
                ResourceGroupName = $ResourceGroupName
                Sku = $Sku
                Key = $KeyName Write-Information "Key: $($key.Key)" Write-Information "Value: $($key.Value)" Write-Information "Label: $($key.Label)" }  "ListKeys" { Write-Log "📋 Listing all configuration keys...
                gt = "0) { $keyParams.Tag = $Tags }  Set-AzAppConfigurationKeyValue"
                Location = $Location
                Endpoint = "https://$ConfigStoreName.azconfig.io" $keys | Format-Table Key, Value, Label, ContentType } }"
                Level = "INFO  $keys = Get-AzAppConfigurationKeyValue"
                Tag = $Tags  Write-Log "[OK] App Configuration store created: $($configStore.Name)
                ErrorAction = "Stop @keyParams Write-Log "[OK] Configuration key added: $KeyName"
                Name = $ConfigStoreName
            }
            $configStore @params

    Write-ProgressStep -StepNumber 3 -TotalSteps 4 -StepName "Validation" -Status "Validating configuration"
    
    # Validate the configuration store
    $store = Get-AzAppConfigurationStore -ResourceGroupName $ResourceGroupName -Name $ConfigStoreName
    
    Write-ProgressStep -StepNumber 4 -TotalSteps 4 -StepName "Summary" -Status "Generating summary"

    Write-Information ""
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information "                              APP CONFIGURATION OPERATION COMPLETE"  
    Write-Information "════════════════════════════════════════════════════════════════════════════════════════════"
    Write-Information ""
    Write-Information " Configuration Store: $ConfigStoreName"
    Write-Information "� Endpoint: https://$ConfigStoreName.azconfig.io"
    Write-Information "� Location: $($store.Location)"
    Write-Information " SKU: $($store.Sku.Name)"
    Write-Information ""

    Write-Log " App Configuration operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log " App Configuration operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity "App Configuration Management" -Completed

#endregion
