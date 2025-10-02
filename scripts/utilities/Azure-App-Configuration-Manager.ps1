#Requires -Version 7.4
#Requires -Modules Az.AppConfiguration

<#
.SYNOPSIS
    Azure App Configuration Manager

.DESCRIPTION
    Manages Azure App Configuration service for centralized configuration management
    of modern applications. Supports creating stores, adding/getting/deleting keys,
    and importing configuration from files.

.PARAMETER ResourceGroupName
    Name of the resource group

.PARAMETER ConfigStoreName
    Name of the App Configuration store

.PARAMETER Location
    Azure region location (default: East US)

.PARAMETER Action
    Action to perform: Create, AddKey, GetKey, DeleteKey, ListKeys, ImportFromFile

.PARAMETER KeyName
    Name of the configuration key

.PARAMETER KeyValue
    Value of the configuration key

.PARAMETER Label
    Label for the configuration key

.PARAMETER ContentType
    Content type of the key value (default: text/plain)

.PARAMETER Tags
    Tags to apply to resources

.PARAMETER ImportFilePath
    Path to file for importing configuration

.PARAMETER Sku
    SKU tier: Free or Standard (default: Standard)

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0
    Requires appropriate permissions and modules
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigStoreName,

    [Parameter()]
    [string]$Location = "East US",

    [Parameter(Mandatory = $true)]
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

    [Parameter()]
    [ValidateSet("Free", "Standard")]
    [string]$Sku = "Standard"
)

$ErrorActionPreference = 'Stop'

function Write-ColorOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        "INFO" = "Cyan"
        "WARN" = "Yellow"
        "ERROR" = "Red"
        "SUCCESS" = "Green"
    }

    Write-Host "$timestamp [$Level] $Message" -ForegroundColor $colorMap[$Level]
}

try {
    Write-ColorOutput "Azure App Configuration Manager - Starting operation: $Action" -Level INFO

    # Validate Azure connection
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Write-ColorOutput "Not connected to Azure. Please run Connect-AzAccount first." -Level ERROR
        throw "Azure connection required"
    }

    Write-ColorOutput "Connected to subscription: $($context.Subscription.Name)" -Level INFO

    switch ($Action) {
        "Create" {
            Write-ColorOutput "Creating App Configuration store: $ConfigStoreName" -Level INFO

            # Check if resource group exists
            $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
            if (-not $rg) {
                Write-ColorOutput "Creating resource group: $ResourceGroupName" -Level INFO
                $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tags $Tags
            }

            # Create App Configuration store
            $storeParams = @{
                ResourceGroupName = $ResourceGroupName
                Name = $ConfigStoreName
                Location = $Location
                Sku = $Sku
            }

            if ($Tags.Count -gt 0) {
                $storeParams['Tag'] = $Tags
            }

            $configStore = New-AzAppConfigurationStore @storeParams
            Write-ColorOutput "App Configuration store created successfully" -Level SUCCESS
            Write-Output $configStore
        }

        "AddKey" {
            if (-not $KeyName -or -not $KeyValue) {
                throw "KeyName and KeyValue are required for AddKey action"
            }

            Write-ColorOutput "Adding key: $KeyName" -Level INFO

            $keyParams = @{
                Name = $ConfigStoreName
                Key = $KeyName
                Value = $KeyValue
                ContentType = $ContentType
            }

            if ($Label) {
                $keyParams['Label'] = $Label
            }

            if ($Tags.Count -gt 0) {
                $keyParams['Tag'] = $Tags
            }

            $key = Set-AzAppConfigurationKeyValue @keyParams
            Write-ColorOutput "Configuration key added successfully" -Level SUCCESS
            Write-Output $key
        }

        "GetKey" {
            if (-not $KeyName) {
                throw "KeyName is required for GetKey action"
            }

            Write-ColorOutput "Retrieving key: $KeyName" -Level INFO

            $keyParams = @{
                Name = $ConfigStoreName
                Key = $KeyName
            }

            if ($Label) {
                $keyParams['Label'] = $Label
            }

            $key = Get-AzAppConfigurationKeyValue @keyParams
            Write-ColorOutput "Configuration key retrieved" -Level SUCCESS
            Write-Output $key
        }

        "DeleteKey" {
            if (-not $KeyName) {
                throw "KeyName is required for DeleteKey action"
            }

            Write-ColorOutput "Deleting key: $KeyName" -Level INFO

            $keyParams = @{
                Name = $ConfigStoreName
                Key = $KeyName
            }

            if ($Label) {
                $keyParams['Label'] = $Label
            }

            Remove-AzAppConfigurationKeyValue @keyParams -Confirm:$false
            Write-ColorOutput "Configuration key deleted successfully" -Level SUCCESS
        }

        "ListKeys" {
            Write-ColorOutput "Listing all configuration keys" -Level INFO

            $keys = Get-AzAppConfigurationKeyValue -Name $ConfigStoreName

            if ($keys) {
                Write-ColorOutput "Found $($keys.Count) keys" -Level SUCCESS
                $keys | Format-Table Key, Value, Label, ContentType, LastModified -AutoSize
            }
            else {
                Write-ColorOutput "No keys found in configuration store" -Level WARN
            }
        }

        "ImportFromFile" {
            if (-not $ImportFilePath -or -not (Test-Path $ImportFilePath)) {
                throw "Valid ImportFilePath is required for ImportFromFile action"
            }

            Write-ColorOutput "Importing configuration from: $ImportFilePath" -Level INFO

            # Read and parse file (assuming JSON format)
            $configData = Get-Content $ImportFilePath -Raw | ConvertFrom-Json

            $importedCount = 0
            foreach ($item in $configData) {
                $keyParams = @{
                    Name = $ConfigStoreName
                    Key = $item.Key
                    Value = $item.Value
                    ContentType = if ($item.ContentType) { $item.ContentType } else { "text/plain" }
                }

                if ($item.Label) {
                    $keyParams['Label'] = $item.Label
                }

                Set-AzAppConfigurationKeyValue @keyParams | Out-Null
                $importedCount++
                Write-Verbose "Imported key: $($item.Key)"
            }

            Write-ColorOutput "Successfully imported $importedCount configuration keys" -Level SUCCESS
        }
    }

    # Display summary
    Write-ColorOutput "`nOperation Summary:" -Level INFO
    Write-Host "===================="
    Write-Host "Configuration Store: $ConfigStoreName"
    Write-Host "Resource Group: $ResourceGroupName"
    Write-Host "Action Performed: $Action"
    Write-Host "Status: Completed Successfully"
}
catch {
    Write-ColorOutput "Operation failed: $($_.Exception.Message)" -Level ERROR
    throw
}