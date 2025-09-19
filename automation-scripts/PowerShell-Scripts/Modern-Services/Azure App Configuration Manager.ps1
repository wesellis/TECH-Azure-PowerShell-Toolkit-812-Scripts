#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure App Configuration Manager

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
    We Enhanced Azure App Configuration Manager

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
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

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
    [string]$WEConfigStoreName,
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " East US" ,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet(" Create" , " AddKey" , " GetKey" , " DeleteKey" , " ListKeys" , " ImportFromFile" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEKeyName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEKeyValue,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELabel,
    
    [Parameter(Mandatory=$false)]
    [string]$WEContentType = " text/plain" ,
    
    [Parameter(Mandatory=$false)]
    [hashtable]$WETags = @{},
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEImportFilePath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet(" Free" , " Standard" )]
    [string]$WESku = " Standard"
)

#region Functions


# Module import removed - use #Requires instead

Show-Banner -ScriptName " Azure App Configuration Service Manager" -Version " 1.0" -Description " Centralized configuration management for modern applications"

try {
    Write-ProgressStep -StepNumber 1 -TotalSteps 4 -StepName " Connection" -Status " Validating Azure connection"
    if (-not (Test-AzureConnection -RequiredModules @('Az.AppConfiguration'))) {
        throw " Azure connection validation failed"
    }

    Write-ProgressStep -StepNumber 2 -TotalSteps 4 -StepName " Configuration Action" -Status " Executing $WEAction"
    
    switch ($WEAction) {
        " Create" {
            Write-Log "  Creating App Configuration store..." -Level INFO
            
            $params = @{
                ResourceGroupName = $WEResourceGroupName
                Sku = $WESku
                Key = $WEKeyName Write-WELog " Key: $($key.Key)" " INFO
                gt = "0) { $keyParams.Tag = $WETags }  Set-AzAppConfigurationKeyValue"
                Location = $WELocation
                Endpoint = " https://$WEConfigStoreName.azconfig.io" $keys | Format-Table Key, Value, Label, ContentType } }"
                Level = "INFO  ;  $keys = Get-AzAppConfigurationKeyValue"
                Tag = $WETags  Write-Log " [OK] App Configuration store created: $($configStore.Name)
                ForegroundColor = "White }  " ListKeys" { Write-Log " 📋 Listing all configuration keys..."
                ErrorAction = "Stop @keyParams Write-Log " [OK] Configuration key added: $WEKeyName"
                Name = $WEConfigStoreName
            }
            $configStore @params

    Write-ProgressStep -StepNumber 3 -TotalSteps 4 -StepName " Validation" -Status " Validating configuration"
    
    # Validate the configuration store
   ;  $store = Get-AzAppConfigurationStore -ResourceGroupName $WEResourceGroupName -Name $WEConfigStoreName
    
    Write-ProgressStep -StepNumber 4 -TotalSteps 4 -StepName " Summary" -Status " Generating summary"

    Write-WELog "" " INFO"
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "                              APP CONFIGURATION OPERATION COMPLETE" " INFO" -ForegroundColor Green  
    Write-WELog " ════════════════════════════════════════════════════════════════════════════════════════════" " INFO" -ForegroundColor Green
    Write-WELog "" " INFO"
    Write-WELog "  Configuration Store: $WEConfigStoreName" " INFO" -ForegroundColor Cyan
    Write-WELog " 🌍 Endpoint: https://$WEConfigStoreName.azconfig.io" " INFO" -ForegroundColor Yellow
    Write-WELog " 📍 Location: $($store.Location)" " INFO" -ForegroundColor White
    Write-WELog "  SKU: $($store.Sku.Name)" " INFO" -ForegroundColor White
    Write-WELog "" " INFO"

    Write-Log "  App Configuration operation completed successfully!" -Level SUCCESS

} catch {
    Write-Log "  App Configuration operation failed: $($_.Exception.Message)" -Level ERROR -Exception $_.Exception
    exit 1
}

Write-Progress -Activity " App Configuration Management" -Completed


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
