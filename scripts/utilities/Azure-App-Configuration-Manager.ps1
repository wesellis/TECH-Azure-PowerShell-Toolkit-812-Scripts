#Requires -Version 7.0
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$ConfigStoreName,
    [Parameter()]
    [string]$Location = "East US",
    [Parameter(Mandatory)]
    [ValidateSet("Create", "AddKey", "GetKey", "DeleteKey", "ListKeys", "ImportFromFile")]
    [string]$Action,
    [Parameter()]
    [string]$KeyName,
    [Parameter()]
    [string]$KeyValue,
    [Parameter()]
    [string]$Label,
    [Parameter()]
    [string]$ContentType = "text/plain",
    [Parameter()]
    [hashtable]$Tags = @{},
    [Parameter()]
    [string]$ImportFilePath,
    [ValidateSet("Free", "Standard")]
    [string]$Sku = "Standard"
)
riptName "Azure App Configuration Service Manager" -Version "1.0" -Description "Centralized configuration management for modern applications"
try {
    Write-HostNumber 1 -TotalSteps 4 -StepName "Connection" -Status "Validating Azure connection"
    if (-not ((Get-AzContext) -RequiredModules @('Az.AppConfiguration'))) {
        throw "Azure connection validation failed"
    }
    Write-HostNumber 2 -TotalSteps 4 -StepName "Configuration Action" -Status "Executing $Action"
    switch ($Action) {
        "Create" {
            
            $params = @{
                ResourceGroupName = $ResourceGroupName
                Sku = $Sku
                Key = $KeyName Write-Host "Key: $($key.Key)"Write-Host "Value: $($key.Value)"Write-Host "Label: $($key.Label)" }  "ListKeys" { Write-Log " Listing all configuration keys...
                gt = "0) { $keyParams.Tag = $Tags }  Set-AzAppConfigurationKeyValue"
                Location = $Location
                Endpoint = "https://$ConfigStoreName.azconfig.io" $keys | Format-Table Key, Value, Label, ContentType } }"
                Level = "INFO  $keys = Get-AzAppConfigurationKeyValue"
                Tag = $Tags  Write-Log "[OK] App Configuration store created: $($configStore.Name)
                ErrorAction = "Stop @keyParams Write-Log "[OK] Configuration key added: $KeyName"
                Name = $ConfigStoreName
            }
            $configStore @params
    Write-HostNumber 3 -TotalSteps 4 -StepName "Validation" -Status "Validating configuration"
    # Validate the configuration store
    $store = Get-AzAppConfigurationStore -ResourceGroupName $ResourceGroupName -Name $ConfigStoreName
    Write-HostNumber 4 -TotalSteps 4 -StepName "Summary" -Status "Generating summary"
    Write-Host ""
    Write-Host "                              APP CONFIGURATION OPERATION COMPLETE"
    Write-Host ""
    Write-Host "Configuration Store: $ConfigStoreName"
    Write-Host "SKU: $($store.Sku.Name)"
    Write-Host ""
    
} catch { throw }

