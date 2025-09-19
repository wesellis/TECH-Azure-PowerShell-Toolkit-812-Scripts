#Requires -Module Az.Consumption
#Requires -Module Az.Resources
#Requires -Version 5.1

<#
.SYNOPSIS
    Creates and manages budget alerts for cost monitoring and control

.DESCRIPTION
    Comprehensive budget management tool that creates spending alerts, monitors consumption,
    and sends notifications when thresholds are reached. Supports multiple budget types,
    time grains, and notification channels including email, webhooks, and action groups.

.PARAMETER BudgetName
    Name of the budget to create or manage

.PARAMETER Scope
    Scope for the budget (subscription, resource group, or management group)

.PARAMETER Amount
    Budget amount in the specified currency

.PARAMETER Currency
    Currency code (default: USD)

.PARAMETER TimeGrain
    Budget time period: Monthly, Quarterly, Annual, BillingMonth, BillingQuarter, BillingYear

.PARAMETER StartDate
    Start date for the budget period

.PARAMETER EndDate
    End date for the budget period (optional for recurring budgets)

.PARAMETER ThresholdPercentages
    Array of percentage thresholds that trigger alerts (e.g., 80, 90, 100, 110)

.PARAMETER NotificationEmails
    Email addresses to receive budget alerts

.PARAMETER WebhookUrl
    Webhook URL for programmatic notifications

.PARAMETER ActionGroupId
    Resource ID of the Action Group for alert routing

.PARAMETER FilterResourceGroups
    Filter budget to specific resource groups

.PARAMETER FilterTags
    Filter budget by resource tags (hashtable)

.PARAMETER IncludeForecast
    Include forecasted spend in threshold calculations

.PARAMETER Action
    Action to perform: Create, Update, Delete, List, GetAlerts

.EXAMPLE
    .\create-budget-alerts.ps1 -BudgetName "Monthly-Production" -Amount 5000 -TimeGrain Monthly -ThresholdPercentages 80,100 -NotificationEmails "team@company.com"

    Creates monthly budget with alerts at 80% and 100% thresholds

.EXAMPLE
    .\create-budget-alerts.ps1 -Action List -Scope "/subscriptions/xxx-xxx"

    Lists all budgets in the subscription

.EXAMPLE
    .\create-budget-alerts.ps1 -BudgetName "Q1-Budget" -Amount 15000 -TimeGrain Quarterly -FilterResourceGroups "RG-Prod","RG-Dev"

    Creates quarterly budget filtered to specific resource groups

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 2.0.0
    Created: 2024-11-15
    LastModified: 2025-09-19
#>

[CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'Create')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Create')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Update')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Delete')]
    [Parameter(Mandatory = $false, ParameterSetName = 'GetAlerts')]
    [ValidateNotNullOrEmpty()]
    [string]$BudgetName,

    [Parameter(Mandatory = $false)]
    [string]$Scope,

    [Parameter(Mandatory = $true, ParameterSetName = 'Create')]
    [Parameter(Mandatory = $false, ParameterSetName = 'Update')]
    [ValidateRange(1, 999999999)]
    [decimal]$Amount,

    [Parameter(Mandatory = $false)]
    [ValidateSet('USD', 'EUR', 'GBP', 'CAD', 'AUD', 'INR', 'JPY', 'CNY')]
    [string]$Currency = 'USD',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Monthly', 'Quarterly', 'Annual', 'BillingMonth', 'BillingQuarter', 'BillingYear')]
    [string]$TimeGrain = 'Monthly',

    [Parameter(Mandatory = $false)]
    [datetime]$StartDate = (Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0),

    [Parameter(Mandatory = $false)]
    [datetime]$EndDate,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 200)]
    [int[]]$ThresholdPercentages = @(80, 90, 100),

    [Parameter(Mandatory = $false)]
    [ValidateScript({$_ -match '^[\w\.\-]+@[\w\.\-]+\.\w+$'})]
    [string[]]$NotificationEmails,

    [Parameter(Mandatory = $false)]
    [ValidateScript({$_ -match '^https?://'})]
    [string]$WebhookUrl,

    [Parameter(Mandatory = $false)]
    [string]$ActionGroupId,

    [Parameter(Mandatory = $false)]
    [string[]]$FilterResourceGroups,

    [Parameter(Mandatory = $false)]
    [hashtable]$FilterTags,

    [Parameter(Mandatory = $false)]
    [string[]]$FilterMeters,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeForecast,

    [Parameter(Mandatory = $true, ParameterSetName = 'List')]
    [Parameter(Mandatory = $true, ParameterSetName = 'Delete')]
    [Parameter(Mandatory = $true, ParameterSetName = 'GetAlerts')]
    [ValidateSet('Create', 'Update', 'Delete', 'List', 'GetAlerts')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [switch]$ExportReport,

    [Parameter(Mandatory = $false)]
    [string]$ExportPath
)

#region Initialize-Configuration
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Set default export path if not provided
if ($ExportReport -and -not $ExportPath) {
    $ExportPath = ".\BudgetReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
}

# Initialize logging
$script:LogPath = ".\BudgetManagement_$(Get-Date -Format 'yyyyMMdd').log"
#endregion

#region Helper-Functions
function Write-LogEntry {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp [$Level] $Message"

    Add-Content -Path $script:LogPath -Value $logEntry -ErrorAction SilentlyContinue

    switch ($Level) {
        'Info'    { Write-Verbose $Message }
        'Warning' { Write-Warning $Message }
        'Error'   { Write-Error $Message }
        'Success' { Write-Host $Message -ForegroundColor Green }
    }
}

function Initialize-RequiredModules {
    $requiredModules = @('Az.Consumption', 'Az.Resources', 'Az.Monitor')

    foreach ($module in $requiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            Write-LogEntry "Module $module not found. Installing..." -Level Warning
            try {
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                Import-Module $module -Force
                Write-LogEntry "Successfully installed module: $module" -Level Success
            }
            catch {
                throw "Failed to install required module $module : $_"
            }
        }
        else {
            Import-Module $module -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-CurrentContext {
    $context = Get-AzContext
    if (-not $context) {
        Write-LogEntry "No context found. Initiating authentication..." -Level Warning
        Connect-AzAccount
        $context = Get-AzContext
    }
    return $context
}

function Resolve-BudgetScope {
    param(
        [string]$ExplicitScope,
        [string]$ResourceGroup
    )

    if ($ExplicitScope) {
        return $ExplicitScope
    }

    $context = Get-CurrentContext

    if ($ResourceGroup) {
        return "/subscriptions/$($context.Subscription.Id)/resourceGroups/$ResourceGroup"
    }
    else {
        return "/subscriptions/$($context.Subscription.Id)"
    }
}

function Format-CurrencyAmount {
    param(
        [decimal]$Amount,
        [string]$Currency = 'USD'
    )

    $currencySymbols = @{
        'USD' = '$'
        'EUR' = '€'
        'GBP' = '£'
        'CAD' = 'C$'
        'AUD' = 'A$'
        'INR' = '₹'
        'JPY' = '¥'
        'CNY' = '¥'
    }

    $symbol = if ($currencySymbols.ContainsKey($Currency)) { $currencySymbols[$Currency] } else { $Currency }
    return "$symbol$([Math]::Round($Amount, 2))"
}
#endregion

#region Core-Functions
function New-BudgetConfiguration {
    param(
        [string]$Name,
        [decimal]$Amount,
        [string]$Currency,
        [string]$TimeGrain,
        [datetime]$StartDate,
        [datetime]$EndDate,
        [string]$Scope
    )

    $config = @{
        Name = $Name
        Category = 'Cost'
        Amount = $Amount
        TimeGrain = $TimeGrain
        TimePeriod = @{
            StartDate = $StartDate.ToString('yyyy-MM-dd')
        }
    }

    if ($EndDate) {
        $config.TimePeriod['EndDate'] = $EndDate.ToString('yyyy-MM-dd')
    }

    # Add filters if specified
    $filters = @{}

    if ($FilterResourceGroups -and $FilterResourceGroups.Count -gt 0) {
        $filters['ResourceGroups'] = $FilterResourceGroups
    }

    if ($FilterTags -and $FilterTags.Count -gt 0) {
        $filters['Tags'] = $FilterTags
    }

    if ($FilterMeters -and $FilterMeters.Count -gt 0) {
        $filters['Meters'] = $FilterMeters
    }

    if ($filters.Count -gt 0) {
        $config['Filter'] = $filters
    }

    return $config
}

function New-BudgetNotifications {
    param(
        [int[]]$ThresholdPercentages,
        [string[]]$Emails,
        [string]$Webhook,
        [string]$ActionGroup
    )

    $notifications = @{}

    foreach ($threshold in $ThresholdPercentages) {
        $notificationName = "Threshold_$($threshold)_Percent"

        $notification = @{
            Enabled = $true
            Operator = 'GreaterThan'
            Threshold = $threshold
            ContactEmails = @()
            ContactRoles = @()
            ContactGroups = @()
            ThresholdType = if ($IncludeForecast) { 'Forecasted' } else { 'Actual' }
        }

        if ($Emails) {
            $notification.ContactEmails = $Emails
        }

        if ($ActionGroup) {
            $notification.ContactGroups = @($ActionGroup)
        }

        # Add webhook as custom notification
        if ($Webhook) {
            $notification['Locale'] = 'en-us'
        }

        $notifications[$notificationName] = $notification
    }

    return $notifications
}

function New-AzureBudget {
    param(
        [hashtable]$BudgetConfig,
        [hashtable]$Notifications,
        [string]$Scope
    )

    try {
        Write-LogEntry "Creating budget: $($BudgetConfig.Name)" -Level Info

        $budgetParams = @{
            Name = $BudgetConfig.Name
            Amount = $BudgetConfig.Amount
            Category = $BudgetConfig.Category
            TimeGrain = $BudgetConfig.TimeGrain
            StartDate = [DateTime]::Parse($BudgetConfig.TimePeriod.StartDate)
        }

        if ($BudgetConfig.TimePeriod.EndDate) {
            $budgetParams['EndDate'] = [DateTime]::Parse($BudgetConfig.TimePeriod.EndDate)
        }

        # Handle scope parameter
        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $resourceGroup = $Scope.Split('/')[-1]
            $budgetParams['ResourceGroupName'] = $resourceGroup
        }

        # Create budget
        if ($PSCmdlet.ShouldProcess($BudgetConfig.Name, "Create Budget")) {
            $budget = New-AzConsumptionBudget @budgetParams

            # Add notifications
            foreach ($notificationKey in $Notifications.Keys) {
                $notif = $Notifications[$notificationKey]

                $notifParams = @{
                    Name = $BudgetConfig.Name
                    NotificationKey = $notificationKey
                    Threshold = $notif.Threshold
                    ContactEmail = $notif.ContactEmails
                    Enabled = $notif.Enabled
                    Operator = $notif.Operator
                }

                if ($notif.ContactGroups -and $notif.ContactGroups.Count -gt 0) {
                    $notifParams['ContactGroup'] = $notif.ContactGroups
                }

                if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
                    $notifParams['ResourceGroupName'] = $resourceGroup
                }

                Set-AzConsumptionBudget @notifParams | Out-Null
            }

            Write-LogEntry "Successfully created budget: $($BudgetConfig.Name)" -Level Success
            return $budget
        }
    }
    catch {
        Write-LogEntry "Failed to create budget: $_" -Level Error
        throw
    }
}

function Update-AzureBudget {
    param(
        [string]$Name,
        [hashtable]$Updates,
        [string]$Scope
    )

    try {
        Write-LogEntry "Updating budget: $Name" -Level Info

        $updateParams = @{
            Name = $Name
        }

        if ($Updates.ContainsKey('Amount')) {
            $updateParams['Amount'] = $Updates.Amount
        }

        if ($Updates.ContainsKey('TimeGrain')) {
            $updateParams['TimeGrain'] = $Updates.TimeGrain
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $updateParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        if ($PSCmdlet.ShouldProcess($Name, "Update Budget")) {
            $budget = Set-AzConsumptionBudget @updateParams
            Write-LogEntry "Successfully updated budget: $Name" -Level Success
            return $budget
        }
    }
    catch {
        Write-LogEntry "Failed to update budget: $_" -Level Error
        throw
    }
}

function Remove-AzureBudget {
    param(
        [string]$Name,
        [string]$Scope
    )

    try {
        Write-LogEntry "Removing budget: $Name" -Level Info

        $removeParams = @{
            Name = $Name
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $removeParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        if ($PSCmdlet.ShouldProcess($Name, "Remove Budget")) {
            Remove-AzConsumptionBudget @removeParams
            Write-LogEntry "Successfully removed budget: $Name" -Level Success
        }
    }
    catch {
        Write-LogEntry "Failed to remove budget: $_" -Level Error
        throw
    }
}

function Get-BudgetAlerts {
    param(
        [string]$BudgetName,
        [string]$Scope,
        [int]$DaysBack = 30
    )

    try {
        Write-LogEntry "Retrieving alerts for budget: $BudgetName" -Level Info

        $startDate = (Get-Date).AddDays(-$DaysBack)
        $endDate = Get-Date

        # Get budget details
        $budgetParams = @{}
        if ($BudgetName) {
            $budgetParams['Name'] = $BudgetName
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $budgetParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        $budget = Get-AzConsumptionBudget @budgetParams

        # Get current usage
        $usageParams = @{
            StartDate = $startDate
            EndDate = $endDate
            Granularity = 'Daily'
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $usageParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        $usage = Get-AzConsumptionUsageDetail @usageParams

        # Calculate total spend
        $totalSpend = ($usage | Measure-Object -Property PretaxCost -Sum).Sum

        # Check against thresholds
        $alerts = @()
        $budgetAmount = $budget.Amount

        foreach ($notification in $budget.Notification.PSObject.Properties) {
            $threshold = $notification.Value.Threshold
            $thresholdAmount = ($budgetAmount * $threshold) / 100

            if ($totalSpend -ge $thresholdAmount) {
                $alerts += [PSCustomObject]@{
                    BudgetName = $budget.Name
                    Threshold = $threshold
                    ThresholdAmount = Format-CurrencyAmount -Amount $thresholdAmount -Currency $Currency
                    CurrentSpend = Format-CurrencyAmount -Amount $totalSpend -Currency $Currency
                    PercentUsed = [Math]::Round(($totalSpend / $budgetAmount) * 100, 2)
                    Status = 'Triggered'
                    Notification = $notification.Name
                }
            }
        }

        Write-LogEntry "Found $($alerts.Count) triggered alerts" -Level Info
        return $alerts
    }
    catch {
        Write-LogEntry "Failed to retrieve budget alerts: $_" -Level Error
        throw
    }
}

function Get-BudgetUsageReport {
    param(
        [string]$Scope,
        [int]$DaysBack = 30
    )

    try {
        Write-LogEntry "Generating budget usage report" -Level Info

        $startDate = (Get-Date).AddDays(-$DaysBack)
        $endDate = Get-Date

        # Get all budgets
        $budgetParams = @{}
        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $budgetParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        $budgets = Get-AzConsumptionBudget @budgetParams

        # Get usage details
        $usageParams = @{
            StartDate = $startDate
            EndDate = $endDate
            Granularity = 'Monthly'
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $usageParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        $usage = Get-AzConsumptionUsageDetail @usageParams
        $totalSpend = ($usage | Measure-Object -Property PretaxCost -Sum).Sum

        $report = @()
        foreach ($budget in $budgets) {
            $percentUsed = if ($budget.Amount -gt 0) {
                [Math]::Round(($totalSpend / $budget.Amount) * 100, 2)
            } else { 0 }

            $report += [PSCustomObject]@{
                BudgetName = $budget.Name
                Amount = Format-CurrencyAmount -Amount $budget.Amount -Currency $Currency
                TimeGrain = $budget.TimeGrain
                StartDate = $budget.TimePeriod.StartDate
                EndDate = if ($budget.TimePeriod.EndDate) { $budget.TimePeriod.EndDate } else { 'Ongoing' }
                CurrentSpend = Format-CurrencyAmount -Amount $totalSpend -Currency $Currency
                PercentUsed = $percentUsed
                Status = if ($percentUsed -ge 100) { 'Exceeded' }
                        elseif ($percentUsed -ge 80) { 'Warning' }
                        else { 'Normal' }
                NotificationCount = $budget.Notification.PSObject.Properties.Count
            }
        }

        Write-LogEntry "Generated report for $($report.Count) budgets" -Level Info
        return $report
    }
    catch {
        Write-LogEntry "Failed to generate usage report: $_" -Level Error
        throw
    }
}
#endregion

#region Main-Execution
try {
    Write-Host "`nBudget Alert Management Tool" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan

    # Initialize modules and context
    Initialize-RequiredModules
    $context = Get-CurrentContext

    # Resolve scope
    $targetScope = Resolve-BudgetScope -ExplicitScope $Scope

    Write-LogEntry "Operating at scope: $targetScope" -Level Info
    Write-Host "Target scope: $targetScope" -ForegroundColor Yellow

    # Handle parameter set determination
    if (-not $Action) {
        $Action = 'Create'
    }

    # Execute requested action
    switch ($Action) {
        'Create' {
            if (-not $BudgetName -or -not $Amount) {
                throw "BudgetName and Amount are required for Create action"
            }

            # Create budget configuration
            $params = @{
                Currency = $Currency
                Name = $BudgetName
                Amount = $Amount
                Scope = $targetScope
                TimeGrain = $TimeGrain
                EndDate = $EndDate
                StartDate = $StartDate
            }
            $budgetConfig = New-BudgetConfiguration @params

            # Create notifications
            $params = @{
                Emails = $NotificationEmails
                Webhook = $WebhookUrl
                ActionGroup = $ActionGroupId
                ThresholdPercentages = $ThresholdPercentages
            }
            $notifications = New-BudgetNotifications @params

            # Create the budget
            $params = @{
                Scope = $targetScope
                Notifications = $notifications
                BudgetConfig = $budgetConfig
            }
            $budget = New-AzureBudget @params

            Write-Host "`nBudget created successfully!" -ForegroundColor Green
            Write-Host "  Name: $($budget.Name)" -ForegroundColor White
            Write-Host "  Amount: $(Format-CurrencyAmount -Amount $Amount -Currency $Currency)" -ForegroundColor White
            Write-Host "  Time Grain: $TimeGrain" -ForegroundColor White
            Write-Host "  Alerts: $($ThresholdPercentages -join '%, ')%" -ForegroundColor White
        }

        'Update' {
            if (-not $BudgetName) {
                throw "BudgetName is required for Update action"
            }

            $updates = @{}
            if ($PSBoundParameters.ContainsKey('Amount')) {
                $updates['Amount'] = $Amount
            }
            if ($PSBoundParameters.ContainsKey('TimeGrain')) {
                $updates['TimeGrain'] = $TimeGrain
            }

            $params = @{
                Updates = $updates
                Scope = $targetScope
                Name = $BudgetName
            }
            $budget = Update-AzureBudget @params

            Write-Host "`nBudget updated successfully!" -ForegroundColor Green
        }

        'Delete' {
            if (-not $BudgetName) {
                throw "BudgetName is required for Delete action"
            }

            Remove-AzureBudget -Name $BudgetName -Scope $targetScope
            Write-Host "`nBudget removed successfully!" -ForegroundColor Green
        }

        'List' {
            $report = Get-BudgetUsageReport -Scope $targetScope -DaysBack 30

            if ($report.Count -eq 0) {
                Write-Host "`nNo budgets found" -ForegroundColor Yellow
            }
            else {
                Write-Host "`nBudgets Summary:" -ForegroundColor Cyan
                $report | Format-Table -AutoSize

                if ($ExportReport) {
                    $report | Export-Csv -Path $ExportPath -NoTypeInformation
                    Write-Host "`nReport exported to: $ExportPath" -ForegroundColor Green
                }
            }
        }

        'GetAlerts' {
            $alerts = if ($BudgetName) {
                Get-BudgetAlerts -BudgetName $BudgetName -Scope $targetScope
            }
            else {
                # Get alerts for all budgets
                $allAlerts = @()
                $budgetParams = @{}
                if ($targetScope -match '^/subscriptions/[^/]+/resourceGroups/') {
                    $budgetParams['ResourceGroupName'] = $targetScope.Split('/')[-1]
                }

                $budgets = Get-AzConsumptionBudget @budgetParams
                foreach ($budget in $budgets) {
                    $budgetAlerts = Get-BudgetAlerts -BudgetName $budget.Name -Scope $targetScope
                    $allAlerts += $budgetAlerts
                }
                $allAlerts
            }

            if ($alerts.Count -eq 0) {
                Write-Host "`nNo triggered alerts found" -ForegroundColor Green
            }
            else {
                Write-Host "`nTriggered Alerts:" -ForegroundColor Yellow
                $alerts | Format-Table -AutoSize

                if ($ExportReport) {
                    $alerts | Export-Csv -Path $ExportPath -NoTypeInformation
                    Write-Host "`nAlerts exported to: $ExportPath" -ForegroundColor Green
                }
            }
        }
    }

    Write-Host "`nOperation completed successfully!" -ForegroundColor Green
}
catch {
    Write-LogEntry "Operation failed: $_" -Level Error
    Write-Error $_
    throw
}
finally {
    # Cleanup
    $ProgressPreference = 'Continue'
}
#endregion

