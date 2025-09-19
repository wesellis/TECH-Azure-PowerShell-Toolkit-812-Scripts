#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Retrieves Azure cost and usage data for analysis and reporting.

.DESCRIPTION
    This script connects to Azure Cost Management API to extract cost and usage data
    for specified subscriptions, resource groups, or time periods. Data can be exported
    in various formats for analysis and dashboard consumption.

.PARAMETER SubscriptionId
    Azure subscription ID to analyze. If not specified, uses default subscription.

.PARAMETER ResourceGroupName
    Optional resource group name to filter costs. If not specified, retrieves all costs.

.PARAMETER StartDate
    Start date for cost analysis. Defaults to 30 days ago.

.PARAMETER EndDate
    End date for cost analysis. Defaults to current date.

.PARAMETER Granularity
    Data granularity: Daily, Monthly. Default is Daily.

.PARAMETER ExportPath
    Path to export the cost data. Supports CSV, JSON, and Excel formats.

.PARAMETER OutputFormat
    Output format: CSV, JSON, Excel, Console. Default is Console.

.EXAMPLE
    .\Get-AzureCostData.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -Days 30

.EXAMPLE
    .\Get-AzureCostData.ps1 -ResourceGroupName "Production-RG" -ExportPath "costs.csv"

.EXAMPLE
    .\Get-AzureCostData.ps1 -StartDate "2025-04-01" -EndDate "2025-04-30" -OutputFormat "Excel" -ExportPath "april-costs.xlsx"

.NOTES
    Author: Wesley Ellis
    Email: wes@wesellis.com
    Website: wesellis.com
    Created: May 23, 2025
    Updated: May 23, 2025
    Version: 1.0

    Prerequisites:
    - Az PowerShell module installed
    - Azure Cost Management Reader role or higher
    - Valid Azure authentication (Connect-AzAccount)

.LINK
    https://docs.microsoft.com/en-us/azure/cost-management-billing/costs/quick-acm-cost-analysis
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [datetime]$StartDate = (Get-Date).AddDays(-30),
    
    [Parameter(Mandatory = $false)]
    [datetime]$EndDate = (Get-Date),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Monthly")]
    [string]$Granularity = "Daily",
    
    [Parameter(Mandatory = $false)]
    [string]$ExportPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("CSV", "JSON", "Excel", "Console")]
    [string]$OutputFormat = "Console"
)

#region Functions

# Script variables
$ErrorActionPreference = "Stop"
$ProgressPreference = "Continue"

# Import required modules
try {
    Write-Verbose "Importing required Azure modules..."
    Import-Module Az.Accounts -Force
    Import-Module Az.CostManagement -Force
    Import-Module Az.Resources -Force
    
    if ($OutputFormat -eq "Excel") {
        Import-Module ImportExcel -Force
    }
}
catch {
    Write-Error "Failed to import required modules. Please install Az and ImportExcel modules: Install-Module Az, ImportExcel"
    exit 1
}

[CmdletBinding()]
function Test-AzureConnection {
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

[CmdletBinding()]
function Get-CostManagementData -ErrorAction Stop {
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

[CmdletBinding()]
function Export-CostData {
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
            "CSV" {
                $Data | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
                Write-Information "Cost data exported to: $Path"
            }
            "JSON" {
                $Data | ConvertTo-Json -Depth 5 | Out-File -FilePath $Path -Encoding UTF8
                Write-Information "Cost data exported to: $Path"
            }
            "Excel" {
                $Data | Export-Excel -Path $Path -WorksheetName "Azure Costs" -AutoSize -FreezeTopRow -BoldTopRow
                Write-Information "Cost data exported to: $Path"
            }
            "Console" {
                $Data | Format-Table -AutoSize
            }
        }
    }
    catch {
        Write-Error "Failed to export data: $($_.Exception.Message)"
        throw
    }
}

[CmdletBinding()]
function Show-CostSummary {
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
    
    Write-Information "`n==================== COST ANALYSIS SUMMARY ===================="
    Write-Information "Analysis Period: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))"
    Write-Information "Total Cost: $($totalCost.ToString('C'))"
    Write-Information "Average Daily Cost: $($avgDailyCost.ToString('C'))"
    Write-Information "Number of Records: $($Data.Count)"
    
    Write-Information "`nTop 5 Services by Cost:"
    foreach ($service in $topServices) {
        $serviceCost = ($service.Group | Measure-Object Cost -Sum).Sum
        Write-Information "  • $($service.Name): $($serviceCost.ToString('C'))"
    }
    
    Write-Information "`nTop 5 Resource Groups by Cost:"
    foreach ($rg in $topResourceGroups) {
        $rgCost = ($rg.Group | Measure-Object Cost -Sum).Sum
        Write-Information "  • $($rg.Name): $($rgCost.ToString('C'))"
    }
    
    Write-Information "===============================================================`n"
}

# Main execution
try {
    Write-Information "Azure Cost Management Data Retrieval Tool"
    Write-Information "=========================================="
    
    # Test Azure connection
    if (-not (Test-AzureConnection)) {
        Write-Information "Please authenticate to Azure first using Connect-AzAccount"
        exit 1
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
        exit 1
    }
    
    # Validate date range
    if ($StartDate -gt $EndDate) {
        Write-Error "Start date cannot be after end date."
        exit 1
    }
    
    if ($EndDate -gt (Get-Date)) {
        Write-Warning "End date is in the future. Setting to current date."
        $EndDate = Get-Date -ErrorAction Stop
    }
    
    # Retrieve cost data
    Write-Information "Retrieving cost data..."
    $costData = Get-CostManagementData -Subscription $SubscriptionId -ResourceGroup $ResourceGroupName -Start $StartDate -End $EndDate -DataGranularity $Granularity
    
    # Display summary
    Show-CostSummary -Data $costData
    
    # Export data if path provided
    if ($ExportPath) {
        # Determine format from file extension if not specified
        if ($OutputFormat -eq "Console") {
            $extension = [System.IO.Path]::GetExtension($ExportPath).ToLower()
            switch ($extension) {
                ".csv" { $OutputFormat = "CSV" }
                ".json" { $OutputFormat = "JSON" }
                ".xlsx" { $OutputFormat = "Excel" }
                default { 
                    Write-Warning "Unknown file extension. Defaulting to CSV format."
                    $OutputFormat = "CSV"
                    $ExportPath = [System.IO.Path]::ChangeExtension($ExportPath, ".csv")
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
    exit 1
}
finally {
    Write-Verbose "Script execution completed."
}


#endregion
