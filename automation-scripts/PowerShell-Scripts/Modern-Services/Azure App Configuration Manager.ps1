<#
.SYNOPSIS
    Azure App Configuration Manager

.DESCRIPTION
    Azure automation
.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigStoreName,
    [Parameter()]
    [string]$Location = "East US",
    [Parameter(Mandatory)]
    [ValidateSet("Create", "AddKey", "GetKey", "DeleteKey", "ListKeys", "ImportFromFile")]
    [ValidateNotNullOrEmpty()]
    [string]$Action,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$KeyName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$KeyValue,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Label,
    [Parameter()]
    [string]$ContentType = "text/plain",
    [Parameter()]
    [hashtable]$Tags = @{},
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ImportFilePath,
    [Parameter()]
    [ValidateSet("Free", "Standard")]
    [string]$Sku = "Standard"
)
Write-Host "Script Started" -ForegroundColor Green
try {
    # Progress stepNumber 1 -TotalSteps 4 -StepName "Connection" -Status "Validating Azure connection"
    if (-not (Get-AzContext)) {
        Connect-AzAccount
        if (-not (Get-AzContext)) {
            throw "Azure connection validation failed"
        }
    }
    }
    # Progress stepNumber 2 -TotalSteps 4 -StepName "Configuration Action" -Status "Executing $Action"
    switch ($Action) {
        "Create" {

            $params = @{
                ResourceGroupName = $ResourceGroupName
                Sku = $Sku
                Key = $KeyName Write-Host "Key: $($key.Key)" " INFO
                gt = "0) { $keyParams.Tag = $Tags }  Set-AzAppConfigurationKeyValue"
                Location = $Location
                Endpoint = "https://$ConfigStoreName.azconfig.io" $keys | Format-Table Key, Value, Label, ContentType } }"
                Level = "INFO  ;  $keys = Get-AzAppConfigurationKeyValue"
                Tag = $Tags  Write-Log "[OK] App Configuration store created: $($configStore.Name)
                ForegroundColor = "White }  "ListKeys" { Write-Log "  Listing all configuration keys..."
                ErrorAction = "Stop @keyParams Write-Log "[OK] Configuration key added: $KeyName"
                Name = $ConfigStoreName
            }
            $configStore @params
    # Progress stepNumber 3 -TotalSteps 4 -StepName "Validation" -Status "Validating configuration"
    # Validate the configuration store
$store = Get-AzAppConfigurationStore -ResourceGroupName $ResourceGroupName -Name $ConfigStoreName
    # Progress stepNumber 4 -TotalSteps 4 -StepName "Summary" -Status "Generating summary"
    Write-Host ""
    Write-Host "                              APP CONFIGURATION OPERATION COMPLETE" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuration Store: $ConfigStoreName" -ForegroundColor Cyan
    Write-Host "Endpoint: https://$ConfigStoreName.azconfig.io" -ForegroundColor Yellow
    Write-Host "Location: $($store.Location)" -ForegroundColor White
    Write-Host "SKU: $($store.Sku.Name)" -ForegroundColor White
    Write-Host ""

} catch { throw }

