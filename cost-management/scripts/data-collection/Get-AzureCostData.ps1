#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
        Tests if user is connected to Azure
    #>
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

[OutputType([bool])]
 {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Retrieves cost data from Azure Cost Management API
    #>
    param(
        [string]$Subscription,
        [string]$ResourceGroup,
        [datetime]$Start,
        [datetime]$End,
        [string]$DataGranularity
    )
    
    try {
        Write-Progress -Activity "Retrieving Azure Cost Data" -Status "Connecting to Cost Management API..." -PercentComplete 25
        
        # Set scope based on parameters
        if ($ResourceGroup) {
            $scope = "/subscriptions/$Subscription/resourceGroups/$ResourceGroup"
            Write-Verbose "Analyzing costs for Resource Group: $ResourceGroup"
        }
        else {
            $scope = "/subscriptions/$Subscription"
            Write-Verbose "Analyzing costs for entire subscription: $Subscription"
        }
        
        # Format dates for API
        $startDateString = $Start.ToString("yyyy-MM-dd")
        $endDateString = $End.ToString("yyyy-MM-dd")
        
        Write-Verbose "Date range: $startDateString to $endDateString"
        Write-Verbose "Granularity: $DataGranularity"
        
        Write-Progress -Activity "Retrieving Azure Cost Data" -Status "Querying cost data..." -PercentComplete 50
        
        # Query cost data using Cost Management API
        $costData = Invoke-AzRestMethod -Path "/providers/Microsoft.CostManagement/query" -Method POST -Payload @{
            type = "ActualCost"
            timeframe = "Custom"
            timePeriod = @{
                from = $startDateString
                to = $endDateString
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
        
        # Process and format the results
        $results = @()
        foreach ($row in $costData.properties.rows) {
            $results += [PSCustomObject]@{
                Date = $row[0]
                ResourceGroup = $row[1]
                ServiceName = $row[2]
                Location = $row[3]
                Cost = [math]::Round([decimal]$row[4], 2)
                Currency = $costData.properties.columns[4].name
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
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Exports cost data to specified format and location
    #>
    param(
        [object[]]$Data,
        [string]$Path,
        [string]$Format
    )
    
    try {
        Write-Verbose "Exporting $($Data.Count) records to $Format format"
        
        switch ($Format) {
            'CSV' {
                $Data | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
                Write-Host "Cost data exported to: $Path" -ForegroundColor Green
            }
            'JSON' {
                $Data | ConvertTo-Json -Depth 5 | Out-File -FilePath $Path -Encoding UTF8
                Write-Host "Cost data exported to: $Path" -ForegroundColor Green
            }
            'Excel' {
                $Data | Export-Excel -Path $Path -WorksheetName 'Azure Costs' -AutoSize -FreezeTopRow -BoldTopRow
                Write-Host "Cost data exported to: $Path" -ForegroundColor Green
            }
            'Console' {
                $Data | Format-Table -AutoSize
            }
        
} catch {
        Write-Error "Failed to export data: $($_.Exception.Message)"
        throw
    }
}

function Show-CostSummary {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Displays a summary of cost data
    #>
    param([object[]]$Data)
    
    if ($Data.Count -eq 0) {
        Write-Warning "No cost data found for the specified criteria."
        return
    }
    
    $totalCost = ($Data | Measure-Object -Property Cost -Sum).Sum
    $avgDailyCost = $totalCost / (($EndDate - $StartDate).Days + 1)
    $topServices = $Data | Group-Object ServiceName | Sort-Object { ($_.Group | Measure-Object Cost -Sum).Sum } -Descending | Select-Object -First 5
    $topResourceGroups = $Data | Group-Object ResourceGroup | Sort-Object { ($_.Group | Measure-Object Cost -Sum).Sum } -Descending | Select-Object -First 5
    
    Write-Host "`n$('=' * 60)" -ForegroundColor Cyan
    Write-Host "COST ANALYSIS SUMMARY" -ForegroundColor White
    Write-Host "$('=' * 60)" -ForegroundColor Cyan
    Write-Host "Analysis Period: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
    Write-Host "Total Cost: $($totalCost.ToString('C'))" -ForegroundColor Green
    Write-Host "Average Daily Cost: $($avgDailyCost.ToString('C'))" -ForegroundColor Yellow
    Write-Host "Number of Records: $($Data.Count)" -ForegroundColor White
    
    Write-Host "`nTop 5 Services by Cost:" -ForegroundColor White
    foreach ($service in $topServices) {
        $serviceCost = ($service.Group | Measure-Object Cost -Sum).Sum
        Write-Host "  - $($service.Name): $($serviceCost.ToString('C'))" -ForegroundColor Gray
    }
    
    Write-Host "`nTop 5 Resource Groups by Cost:" -ForegroundColor White
    foreach ($rg in $topResourceGroups) {
        $rgCost = ($rg.Group | Measure-Object Cost -Sum).Sum
        Write-Host "  - $($rg.Name): $($rgCost.ToString('C'))" -ForegroundColor Gray
    }
    
    Write-Host "$('=' * 60)`n" -ForegroundColor Cyan
}

#region Main-Execution
try {
    Write-Host "Azure Cost Management Data Retrieval Tool" -ForegroundColor White
    Write-Host "==========================================" -ForegroundColor White

    # Test Azure connection
    if (-not (Test-AzureConnection)) {
        Write-Host "Please authenticate to Azure first using Connect-AzAccount" -ForegroundColor Red
        throw "Azure authentication required"
    }
    
    # Set default subscription if not provided
    if (-not $SubscriptionId) {
        $context = Get-AzContext -ErrorAction Stop
        $SubscriptionId = $context.Subscription.Id
        Write-Verbose "Using default subscription: $SubscriptionId"
    }
    
    # Validate subscription access
    try {
        $subscription = Get-AzSubscription -SubscriptionId $SubscriptionId
        Write-Verbose "Subscription validated: $($subscription.Name)"
    }
    catch {
        Write-Error "Cannot access subscription $SubscriptionId. Please check your permissions."
        throw
    }
    
    # Validate date range
    if ($StartDate -gt $EndDate) {
        Write-Error "Start date cannot be after end date."
        throw "Invalid date range"
    }
    
    if ($EndDate -gt (Get-Date)) {
        Write-Warning "End date is in the future. Setting to current date."
        $EndDate = Get-Date -ErrorAction Stop
    }
    
    # Retrieve cost data
    Write-Host "Retrieving cost data..." -ForegroundColor Cyan
    $costData = Get-CostManagementData -Subscription $SubscriptionId -ResourceGroup $ResourceGroupName -Start $StartDate -End $EndDate -DataGranularity $Granularity
    
    # Display summary
    Show-CostSummary -Data $costData
    
    # Export data if path provided
    if ($ExportPath) {
        # Determine format from file extension if not specified
        if ($OutputFormat -eq 'Console') {
            $extension = [System.IO.Path]::GetExtension($ExportPath).ToLower()
            switch ($extension) {
                '.csv' { $OutputFormat = 'CSV' }
                '.json' { $OutputFormat = 'JSON' }
                '.xlsx' { $OutputFormat = 'Excel' }
                default {
                    Write-Warning "Unknown file extension. Defaulting to CSV format."
                    $OutputFormat = 'CSV'
                    $ExportPath = [System.IO.Path]::ChangeExtension($ExportPath, '.csv')
                }
            }
        }
        
        Export-CostData -Data $costData -Path $ExportPath -Format $OutputFormat
    }
    
    # Return data for pipeline usage
    return $costData
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Error "Stack Trace: $($_.ScriptStackTrace)"
    throw
}
finally {
    Write-Verbose "Script execution completed."
}

#endregion

