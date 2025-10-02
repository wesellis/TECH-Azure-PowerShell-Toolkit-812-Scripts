#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    create budget alerts
.DESCRIPTION
    create budget alerts operation
    Author: Wes Ellis (wes@wesellis.com)

    Creates and manages budget alerts for cost monitoring and control
    and sends notifications when thresholds are reached. Supports multiple budget types,
    time grains, and notification channels including email, webhooks, and action groups.
.parameter BudgetName
    Name of the budget to create or manage
.parameter Scope
    Scope for the budget (subscription, resource group, or management group)
.parameter Amount
    Budget amount in the specified currency
.parameter Currency
    Currency code (default: USD)
.parameter TimeGrain
    Budget time period: Monthly, Quarterly, Annual, BillingMonth, BillingQuarter, BillingYear
.parameter StartDate
    Start date for the budget period
.parameter EndDate
    End date for the budget period (optional for recurring budgets)
.parameter ThresholdPercentages
    Array of percentage thresholds that trigger alerts (e.g., 80, 90, 100, 110)
.parameter NotificationEmails
    Email addresses to receive budget alerts
.parameter WebhookUrl
    Webhook URL for programmatic notifications
.parameter ActionGroupId
    Resource ID of the Action Group for alert routing
.parameter FilterResourceGroups
    Filter budget to specific resource groups
.parameter FilterTags
    Filter budget by resource tags (hashtable)
.parameter IncludeForecast
    Include forecasted spend in threshold calculations
.parameter Action
    Action to perform: Create, Update, Delete, List, GetAlerts

    .\create-budget-alerts.ps1 -BudgetName "Monthly-Production" -Amount 5000 -TimeGrain Monthly -ThresholdPercentages 80,100 -NotificationEmails "team@example.com"

    Creates monthly budget with alerts at 80% and 100% thresholds

    .\create-budget-alerts.ps1 -Action List -Scope "/subscriptions/xxx-xxx"

    Lists all budgets in the subscription

    .\create-budget-alerts.ps1 -BudgetName "Q1-Budget" -Amount 15000 -TimeGrain Quarterly -FilterResourceGroups "RG-Prod","RG-Dev"

    Creates quarterly budget filtered to specific resource groups

    Author: Azure PowerShell Toolkit

[parameter(Mandatory = $true, ParameterSetName = 'Create')]
    [parameter(Mandatory = $true, ParameterSetName = 'Update')]
    [parameter(Mandatory = $true, ParameterSetName = 'Delete')]
    [parameter(Mandatory = $false, ParameterSetName = 'GetAlerts')]
    [ValidateNotNullOrEmpty()]
    [string]$BudgetName,

    [parameter(Mandatory = $false)]
    [string]$Scope,

    [parameter(Mandatory = $true, ParameterSetName = 'Create')]
    [parameter(Mandatory = $false, ParameterSetName = 'Update')]
    [ValidateRange(1, 999999999)]
    [decimal]$Amount,

    [parameter(Mandatory = $false)]
    [ValidateSet('USD', 'EUR', 'GBP', 'CAD', 'AUD', 'INR', 'JPY', 'CNY')]
    [string]$Currency = 'USD',

    [parameter(Mandatory = $false)]
    [ValidateSet('Monthly', 'Quarterly', 'Annual', 'BillingMonth', 'BillingQuarter', 'BillingYear')]
    [string]$TimeGrain = 'Monthly',

    [parameter(Mandatory = $false)]
    [datetime]$StartDate = (Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0),

    [parameter(Mandatory = $false)]
    [datetime]$EndDate,

    [parameter(Mandatory = $false)]
    [ValidateRange(1, 200)]
    [int[]]$ThresholdPercentages = @(80, 90, 100),

    [parameter(Mandatory = $false)]
    [ValidateScript({$_ -match '^[\w\.\-]+@[\w\.\-]+\.\w+$'})]
    [string[]]$NotificationEmails,

    [parameter(Mandatory = $false)]
    [ValidateScript({$_ -match '^https?://'})]
    [string]$WebhookUrl,

    [parameter(Mandatory = $false)]
    [string]$ActionGroupId,

    [parameter(Mandatory = $false)]
    [string[]]$FilterResourceGroups,

    [parameter(Mandatory = $false)]
    [hashtable]$FilterTags,

    [parameter(Mandatory = $false)]
    [string[]]$FilterMeters,

    [parameter(Mandatory = $false)]
    [switch]$IncludeForecast,

    [parameter(Mandatory = $true, ParameterSetName = 'List')]
    [parameter(Mandatory = $true, ParameterSetName = 'Delete')]
    [parameter(Mandatory = $true, ParameterSetName = 'GetAlerts')]
    [ValidateSet('Create', 'Update', 'Delete', 'List', 'GetAlerts')]
    [string]$Action,

    [parameter(Mandatory = $false)]
    [switch]$ExportReport,

    [parameter(Mandatory = $false)]
    [string]$ExportPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($ExportReport -and -not $ExportPath) {
    $ExportPath = ".\BudgetReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
}

$script:LogPath = ".\BudgetManagement_$(Get-Date -Format 'yyyyMMdd').log"


[OutputType([bool])] 
 {
    [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "$timestamp [$Level] $Message"

    Add-Content -Path $script:LogPath -Value $LogEntry -ErrorAction SilentlyContinue

    switch ($Level) {
        'Info'    { write-Verbose $Message }
        'Warning' { write-Warning $Message }
        'Error'   { write-Error $Message }
        'Success' { Write-Output $Message -ForegroundColor Green }
    }
}

function Initialize-RequiredModules {
    $RequiredModules = @('Az.Consumption', 'Az.Resources', 'Az.Monitor')

    foreach ($module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $module)) {
            write-LogEntry "Module $module not found. Installing..." -Level Warning
            try {
                Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
                                write-LogEntry "Successfully installed module: $module" -Level Success
            }
            catch {
                throw "Failed to install required module $module : $_"
            }
        }
        else {
                    }
    }
}

function Get-CurrentContext {
    $context = Get-AzContext
    if (-not $context) {
        write-LogEntry "No context found. Initiating authentication..." -Level Warning
        Connect-AzAccount
        $context = Get-AzContext
    }
    return $context
}

function Resolve-BudgetScope {
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
    [decimal]$Amount,
        [string]$Currency = 'USD'
    )

    $CurrencySymbols = @{
        'USD' = '$'
        'EUR' = ''
        'GBP' = '£'
        'CAD' = 'C$'
        'AUD' = 'A$'
        'INR' = ''
        'JPY' = '�'
        'CNY' = '�'
    }

    $symbol = if ($CurrencySymbols.ContainsKey($Currency)) { $CurrencySymbols[$Currency] } else { $Currency }
    return "$symbol$([Math]::Round($Amount, 2))"
}


function New-BudgetConfiguration {
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
    [int[]]$ThresholdPercentages,
        [string[]]$Emails,
        [string]$Webhook,
        [string]$ActionGroup
    )

    $notifications = @{}

    foreach ($threshold in $ThresholdPercentages) {
        $NotificationName = "Threshold_$($threshold)_Percent"

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

        if ($Webhook) {
            $notification['Locale'] = 'en-us'
        }

        $notifications[$NotificationName] = $notification
    }

    return $notifications
}

function New-AzureBudget {
    [hashtable]$BudgetConfig,
        [hashtable]$Notifications,
        [string]$Scope
    )

    try {
        write-LogEntry "Creating budget: $($BudgetConfig.Name)" -Level Info

        $BudgetParams = @{
            Name = $BudgetConfig.Name
            Amount = $BudgetConfig.Amount
            Category = $BudgetConfig.Category
            TimeGrain = $BudgetConfig.TimeGrain
            StartDate = [DateTime]::Parse($BudgetConfig.TimePeriod.StartDate)
        }

        if ($BudgetConfig.TimePeriod.EndDate) {
            $BudgetParams['EndDate'] = [DateTime]::Parse($BudgetConfig.TimePeriod.EndDate)
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $ResourceGroup = $Scope.Split('/')[-1]
            $BudgetParams['ResourceGroupName'] = $ResourceGroup
        }

        if ($PSCmdlet.ShouldProcess($BudgetConfig.Name, "Create Budget")) {
            $budget = New-AzConsumptionBudget @budgetParams

            foreach ($NotificationKey in $Notifications.Keys) {
                $notif = $Notifications[$NotificationKey]

                $NotifParams = @{
                    Name = $BudgetConfig.Name
                    NotificationKey = $NotificationKey
                    Threshold = $notif.Threshold
                    ContactEmail = $notif.ContactEmails
                    Enabled = $notif.Enabled
                    Operator = $notif.Operator
                }

                if ($notif.ContactGroups -and $notif.ContactGroups.Count -gt 0) {
                    $NotifParams['ContactGroup'] = $notif.ContactGroups
                }

                if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
                    $NotifParams['ResourceGroupName'] = $ResourceGroup
                }

                Set-AzConsumptionBudget @notifParams | Out-Null
            }

            write-LogEntry "Successfully created budget: $($BudgetConfig.Name)" -Level Success
            return $budget

} catch {
        write-LogEntry "Failed to create budget: $_" -Level Error
        throw
    }
}

function Update-AzureBudget {
    [string]$Name,
        [hashtable]$Updates,
        [string]$Scope
    )

    try {
        write-LogEntry "Updating budget: $Name" -Level Info

        $UpdateParams = @{
            Name = $Name
        }

        if ($Updates.ContainsKey('Amount')) {
            $UpdateParams['Amount'] = $Updates.Amount
        }

        if ($Updates.ContainsKey('TimeGrain')) {
            $UpdateParams['TimeGrain'] = $Updates.TimeGrain
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $UpdateParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        if ($PSCmdlet.ShouldProcess($Name, "Update Budget")) {
            $budget = Set-AzConsumptionBudget @updateParams
            write-LogEntry "Successfully updated budget: $Name" -Level Success
            return $budget

} catch {
        write-LogEntry "Failed to update budget: $_" -Level Error
        throw
    }
}

function Remove-AzureBudget {
    [string]$Name,
        [string]$Scope
    )

    try {
        write-LogEntry "Removing budget: $Name" -Level Info

        $RemoveParams = @{
            Name = $Name
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $RemoveParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        if ($PSCmdlet.ShouldProcess($Name, "Remove Budget")) {
            Remove-AzConsumptionBudget @removeParams
            write-LogEntry "Successfully removed budget: $Name" -Level Success

} catch {
        write-LogEntry "Failed to remove budget: $_" -Level Error
        throw
    }
}

function Get-BudgetAlerts {
    [string]$BudgetName,
        [string]$Scope,
        [int]$DaysBack = 30
    )

    try {
        write-LogEntry "Retrieving alerts for budget: $BudgetName" -Level Info

        $StartDate = (Get-Date).AddDays(-$DaysBack)
        $EndDate = Get-Date

        $BudgetParams = @{}
        if ($BudgetName) {
            $BudgetParams['Name'] = $BudgetName
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $BudgetParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        $budget = Get-AzConsumptionBudget @budgetParams

        $UsageParams = @{
            StartDate = $StartDate
            EndDate = $EndDate
            Granularity = 'Daily'
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $UsageParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        $usage = Get-AzConsumptionUsageDetail @usageParams

        $TotalSpend = ($usage | Measure-Object -Property PretaxCost -Sum).Sum

        $alerts = @()
        $BudgetAmount = $budget.Amount

        foreach ($notification in $budget.Notification.PSObject.Properties) {
            $threshold = $notification.Value.Threshold
            $ThresholdAmount = ($BudgetAmount * $threshold) / 100

            if ($TotalSpend -ge $ThresholdAmount) {
                $alerts += [PSCustomObject]@{
                    BudgetName = $budget.Name
                    Threshold = $threshold
                    ThresholdAmount = Format-CurrencyAmount -Amount $ThresholdAmount -Currency $Currency
                    CurrentSpend = Format-CurrencyAmount -Amount $TotalSpend -Currency $Currency
                    PercentUsed = [Math]::Round(($TotalSpend / $BudgetAmount) * 100, 2)
                    Status = 'Triggered'
                    Notification = $notification.Name
                }
            }
        }

        write-LogEntry "Found $($alerts.Count) triggered alerts" -Level Info
        return $alerts
    }
    catch {
        write-LogEntry "Failed to retrieve budget alerts: $_" -Level Error
        throw
    }
}

function Get-BudgetUsageReport {
    [string]$Scope,
        [int]$DaysBack = 30
    )

    try {
        write-LogEntry "Generating budget usage report" -Level Info

        $StartDate = (Get-Date).AddDays(-$DaysBack)
        $EndDate = Get-Date

        $BudgetParams = @{}
        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $BudgetParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        $budgets = Get-AzConsumptionBudget @budgetParams

        $UsageParams = @{
            StartDate = $StartDate
            EndDate = $EndDate
            Granularity = 'Monthly'
        }

        if ($Scope -match '^/subscriptions/[^/]+/resourceGroups/') {
            $UsageParams['ResourceGroupName'] = $Scope.Split('/')[-1]
        }

        $usage = Get-AzConsumptionUsageDetail @usageParams
        $TotalSpend = ($usage | Measure-Object -Property PretaxCost -Sum).Sum

        $report = @()
        foreach ($budget in $budgets) {
            $PercentUsed = if ($budget.Amount -gt 0) {
                [Math]::Round(($TotalSpend / $budget.Amount) * 100, 2)
            } else { 0 }

            $report += [PSCustomObject]@{
                BudgetName = $budget.Name
                Amount = Format-CurrencyAmount -Amount $budget.Amount -Currency $Currency
                TimeGrain = $budget.TimeGrain
                StartDate = $budget.TimePeriod.StartDate
                EndDate = if ($budget.TimePeriod.EndDate) { $budget.TimePeriod.EndDate } else { 'Ongoing' }
                CurrentSpend = Format-CurrencyAmount -Amount $TotalSpend -Currency $Currency
                PercentUsed = $PercentUsed
                Status = if ($PercentUsed -ge 100) { 'Exceeded' }
                        elseif ($PercentUsed -ge 80) { 'Warning' }
                        else { 'Normal' }
                NotificationCount = $budget.Notification.PSObject.Properties.Count
            }
        }

        write-LogEntry "Generated report for $($report.Count) budgets" -Level Info
        return $report
    }
    catch {
        write-LogEntry "Failed to generate usage report: $_" -Level Error
        throw
    }
}


try {
    Write-Host "`nBudget Alert Management Tool" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green

    Initialize-RequiredModules
    $context = Get-CurrentContext

    $TargetScope = Resolve-BudgetScope -ExplicitScope $Scope

    write-LogEntry "Operating at scope: $TargetScope" -Level Info
    Write-Host "Target scope: $TargetScope" -ForegroundColor Green

    if (-not $Action) {
        $Action = 'Create'
    }

    switch ($Action) {
        'Create' {
            if (-not $BudgetName -or -not $Amount) {
                throw "BudgetName and Amount are required for Create action"
            }

            $params = @{
                Currency = $Currency
                Name = $BudgetName
                Amount = $Amount
                Scope = $TargetScope
                TimeGrain = $TimeGrain
                EndDate = $EndDate
                StartDate = $StartDate
            }
            $BudgetConfig = New-BudgetConfiguration @params

            $params = @{
                Emails = $NotificationEmails
                Webhook = $WebhookUrl
                ActionGroup = $ActionGroupId
                ThresholdPercentages = $ThresholdPercentages
            }
            $notifications = New-BudgetNotifications @params

            $params = @{
                Scope = $TargetScope
                Notifications = $notifications
                BudgetConfig = $BudgetConfig
            }
            $budget = New-AzureBudget @params

            Write-Host "`nBudget created successfully!" -ForegroundColor Green
            Write-Host "Name: $($budget.Name)" -ForegroundColor Green
            Write-Host "Amount: $(Format-CurrencyAmount -Amount $Amount -Currency $Currency)" -ForegroundColor Green
            Write-Host "Time Grain: $TimeGrain" -ForegroundColor Green
            Write-Host "Alerts: $($ThresholdPercentages -join '%, ')%" -ForegroundColor Green
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
                Scope = $TargetScope
                Name = $BudgetName
            }
            $budget = Update-AzureBudget @params

            Write-Host "`nBudget updated successfully!" -ForegroundColor Green
        }

        'Delete' {
            if (-not $BudgetName) {
                throw "BudgetName is required for Delete action"
            }

            Remove-AzureBudget -Name $BudgetName -Scope $TargetScope
            Write-Host "`nBudget removed successfully!" -ForegroundColor Green
        }

        'List' {
            $report = Get-BudgetUsageReport -Scope $TargetScope -DaysBack 30

            if ($report.Count -eq 0) {
                Write-Host "`nNo budgets found" -ForegroundColor Green
            }
            else {
                Write-Host "`nBudgets Summary:" -ForegroundColor Green
                $report | Format-Table -AutoSize

                if ($ExportReport) {
                    $report | Export-Csv -Path $ExportPath -NoTypeInformation
                    Write-Host "`nReport exported to: $ExportPath" -ForegroundColor Green
                }
            }
        }

        'GetAlerts' {
            $alerts = if ($BudgetName) {
                Get-BudgetAlerts -BudgetName $BudgetName -Scope $TargetScope
            }
            else {
                $AllAlerts = @()
                $BudgetParams = @{}
                if ($TargetScope -match '^/subscriptions/[^/]+/resourceGroups/') {
                    $BudgetParams['ResourceGroupName'] = $TargetScope.Split('/')[-1]
                }

                $budgets = Get-AzConsumptionBudget @budgetParams
                foreach ($budget in $budgets) {
                    $BudgetAlerts = Get-BudgetAlerts -BudgetName $budget.Name -Scope $TargetScope
                    $AllAlerts += $BudgetAlerts
                }
                $AllAlerts
            }

            if ($alerts.Count -eq 0) {
                Write-Host "`nNo triggered alerts found" -ForegroundColor Green
            }
            else {
                Write-Host "`nTriggered Alerts:" -ForegroundColor Green
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
    write-LogEntry "Operation failed: $_" -Level Error
    write-Error $_
    throw
}
finally {
    $ProgressPreference = 'Continue'}
