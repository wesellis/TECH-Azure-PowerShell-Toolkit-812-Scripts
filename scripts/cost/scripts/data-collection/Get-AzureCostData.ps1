<#
.SYNOPSIS
    Get AzureCostData

.DESCRIPTION
    Azure PowerShell automation script

.AUTHOR
    Wesley Ellis (wes@wesellis.com)
#>

#Requires -Version 7.4
#Requires -Modules Az.Resources
    [string]$ErrorActionPreference = 'Stop'

    try {
$context = Get-AzContext -ErrorAction Stop
        if (-not $context) {
            Write-Warning "Not connected to Azure. Please run Connect-AzAccount first."
            return $false
        }

        Write-Verbose "Connected to Azure as: $($context.Account.Id)"
        Write-Verbose "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
        return $true
    }
    catch {
        Write-Warning "Azure connection test failed: $($_.Exception.Message)"
        return $false
    }
}

function Write-Log {
    param(
        [string]$Subscription,
        [string]$ResourceGroup,
        [datetime]$Start,
        [datetime]$End,
        [string]$DataGranularity
    )

    try {
        Write-Progress -Activity "Retrieving Azure Cost Data" -Status "Connecting to Cost Management API..." -PercentComplete 25

        if ($ResourceGroup) {
    [string]$scope = "/subscriptions/$Subscription/resourceGroups/$ResourceGroup"
            Write-Verbose "Analyzing costs for Resource Group: $ResourceGroup"
        }
        else {
    [string]$scope = "/subscriptions/$Subscription"
            Write-Verbose "Analyzing costs for entire subscription: $Subscription"
        }
    [string]$StartDateString = $Start.ToString("yyyy-MM-dd")
    [string]$EndDateString = $End.ToString("yyyy-MM-dd")

        Write-Verbose "Date range: $StartDateString to $EndDateString"
        Write-Verbose "Granularity: $DataGranularity"

        Write-Progress -Activity "Retrieving Azure Cost Data" -Status "Querying cost data..." -PercentComplete 50
    [string]$CostData = Invoke-AzRestMethod -Path "/providers/Microsoft.CostManagement/query" -Method POST -Payload @{
            type = "ActualCost"
            timeframe = "Custom"
            timePeriod = @{
                from = $StartDateString
                to = $EndDateString
            }
            dataset = @{
                granularity = $DataGranularity
                aggregation = @{
                    totalCost = @{
                        name = "PreTaxCost"
                        function = "Sum"
                    }
                }
                grouping = @(
                    @{
                        type = "Dimension"
                        name = "ResourceGroup"
                    },
                    @{
                        type = "Dimension"
                        name = "ServiceName"
                    },
                    @{
                        type = "Dimension"
                        name = "ResourceLocation"
                    }
                )
            }
        } -Scope $scope | ConvertFrom-Json

        Write-Progress -Activity "Retrieving Azure Cost Data" -Status "Processing results..." -PercentComplete 75
    [string]$results = @()
        foreach ($row in $CostData.properties.rows) {
    [string]$results += [PSCustomObject]@{
                Date = $row[0]
                ResourceGroup = $row[1]
                ServiceName = $row[2]
                Location = $row[3]
                Cost = [math]::Round([decimal]$row[4], 2)
                Currency = $CostData.properties.columns[4].name
            }
        }

        Write-Progress -Activity "Retrieving Azure Cost Data" -Completed

        return $results
    }
    catch {
        Write-Error "Failed to retrieve cost data: $($_.Exception.Message)"
        throw
    }
}

function Export-CostData {
    param(
        [object[]]$Data,
        [string]$Path,
        [string]$Format
    )

    try {
        Write-Verbose "Exporting $($Data.Count) records to $Format format"

        switch ($Format) {
            'CSV' {
    [string]$Data | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
                Write-Host "Cost data exported to: $Path" -ForegroundColor Green
            }
            'JSON' {
    [string]$Data | ConvertTo-Json -Depth 5 | Out-File -FilePath $Path -Encoding UTF8
                Write-Host "Cost data exported to: $Path" -ForegroundColor Green
            }
            'Excel' {
    [string]$Data | Export-Excel -Path $Path -WorksheetName 'Azure Costs' -AutoSize -FreezeTopRow -BoldTopRow
                Write-Host "Cost data exported to: $Path" -ForegroundColor Green
            }
            'Console' {
    [string]$Data | Format-Table -AutoSize
            }

} catch {
        Write-Error "Failed to export data: $($_.Exception.Message)"
        throw
    }
}

function Show-CostSummary {
    param([object[]]$Data)

    if ($Data.Count -eq 0) {
        Write-Warning "No cost data found for the specified criteria."
        return
    }
    [string]$TotalCost = ($Data | Measure-Object -Property Cost -Sum).Sum
    [string]$AvgDailyCost = $TotalCost / (($EndDate - $StartDate).Days + 1)
    [string]$TopServices = $Data | Group-Object ServiceName | Sort-Object { ($_.Group | Measure-Object Cost -Sum).Sum } -Descending | Select-Object -First 5
    [string]$TopResourceGroups = $Data | Group-Object ResourceGroup | Sort-Object { ($_.Group | Measure-Object Cost -Sum).Sum } -Descending | Select-Object -First 5

    Write-Host "`n$('=' * 60)" -ForegroundColor Green
    Write-Host "COST ANALYSIS SUMMARY" -ForegroundColor Green
    Write-Host "$('=' * 60)" -ForegroundColor Green
    Write-Host "Analysis Period: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor Green
    Write-Host "Total Cost: $($TotalCost.ToString('C'))" -ForegroundColor Green
    Write-Host "Average Daily Cost: $($AvgDailyCost.ToString('C'))" -ForegroundColor Green
    Write-Host "Number of Records: $($Data.Count)" -ForegroundColor Green

    Write-Host "`nTop 5 Services by Cost:" -ForegroundColor Green
    foreach ($service in $TopServices) {
    [string]$ServiceCost = ($service.Group | Measure-Object Cost -Sum).Sum
        Write-Host "  - $($service.Name): $($ServiceCost.ToString('C'))" -ForegroundColor Green
    }

    Write-Host "`nTop 5 Resource Groups by Cost:" -ForegroundColor Green
    foreach ($rg in $TopResourceGroups) {
    [string]$RgCost = ($rg.Group | Measure-Object Cost -Sum).Sum
        Write-Host "  - $($rg.Name): $($RgCost.ToString('C'))" -ForegroundColor Green
    }

    Write-Host "$('=' * 60)`n" -ForegroundColor Green
}

try {
    Write-Host "Azure Cost Management Data Retrieval Tool" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green

    if (-not (Test-AzureConnection)) {
        Write-Host "Please authenticate to Azure first using Connect-AzAccount" -ForegroundColor Green
        throw "Azure authentication required"
    }

    if (-not $SubscriptionId) {
$context = Get-AzContext -ErrorAction Stop
    [string]$SubscriptionId = $context.Subscription.Id
        Write-Verbose "Using default subscription: $SubscriptionId"
    }

    try {
$subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Verbose "Subscription validated: $($subscription.Name)"
    }
    catch {
        Write-Error "Cannot access subscription $SubscriptionId. Please check your permissions."
        throw
    }

    if ($StartDate -gt $EndDate) {
        Write-Error "Start date cannot be after end date."
        throw "Invalid date range"
    }

    if ($EndDate -gt (Get-Date)) {
        Write-Warning "End date is in the future. Setting to current date."
$EndDate = Get-Date -ErrorAction Stop
    }

    Write-Host "Retrieving cost data..." -ForegroundColor Green
$CostData = Get-CostManagementData -Subscription $SubscriptionId -ResourceGroup $ResourceGroupName -Start $StartDate -End $EndDate -DataGranularity $Granularity

    Show-CostSummary -Data $CostData

    if ($ExportPath) {
        if ($OutputFormat -eq 'Console') {
    [string]$extension = [System.IO.Path]::GetExtension($ExportPath).ToLower()
            switch ($extension) {
                '.csv' { $OutputFormat = 'CSV' }
                '.json' { $OutputFormat = 'JSON' }
                '.xlsx' { $OutputFormat = 'Excel' }
                default {
                    Write-Warning "Unknown file extension. Defaulting to CSV format."
    [string]$OutputFormat = 'CSV'
    [string]$ExportPath = [System.IO.Path]::ChangeExtension($ExportPath, '.csv')
                }
            }
        }

        Export-CostData -Data $CostData -Path $ExportPath -Format $OutputFormat
    }

    return $CostData
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Error "Stack Trace: $($_.ScriptStackTrace)"
    throw
}
finally {
    Write-Verbose "Script execution completed."`n}
