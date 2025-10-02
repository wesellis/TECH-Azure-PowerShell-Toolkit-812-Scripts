<#
.SYNOPSIS
    Setup BudgetAlerts

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
            throw "Not connected to Azure. Please run Connect-AzAccount first."
        }

        Write-Log "Connected to Azure as: $($context.Account.Id)"
        Write-Log "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
        return $context
    }
    catch {
        Write-Log "Azure connection test failed: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Write-Log {
    param(
        [string]$Subscription,
        [string]$ResourceGroupName
    )

    if ($ResourceGroupName) {
    [string]$scope = "/subscriptions/$Subscription/resourceGroups/$ResourceGroupName"
        Write-Log "Budget scope: Resource Group ($ResourceGroupName)"
    }
    else {
    [string]$scope = "/subscriptions/$Subscription"
        Write-Log "Budget scope: Subscription ($Subscription)"
    }

    return $scope
}

function New-BudgetAlerts {
    param(
        [int[]]$Thresholds,
        [string[]]$EmailAddresses
    )
$notifications = @{}

    foreach ($threshold in $Thresholds) {
    [string]$NotificationKey = "Alert$threshold"
    [string]$notifications[$NotificationKey] = @{
            enabled = $true
            operator = "GreaterThan"
            threshold = $threshold
            contactEmails = $EmailAddresses
            contactRoles = @("Owner", "Contributor")
            thresholdType = "Actual"
        }

        Write-Log "Created alert notification for $threshold% threshold"
    }

    return $notifications
}

function New-AzureBudget {
    param(
        [string]$Name,
        [string]$Scope,
        [decimal]$Amount,
        [datetime]$Start,
        [datetime]$End,
        [hashtable]$Notifications,
        [string]$DepartmentTag,
        [string]$CostCenterTag
    )

    Write-Log "Creating Azure budget: $Name"
    Write-Log "Amount: $($Amount.ToString('C')) | Period: $($Start.ToString('yyyy-MM-dd')) to $($End.ToString('yyyy-MM-dd'))"
$BudgetParams = @{
        Name = $Name
        Scope = $Scope
        Amount = $Amount
        TimeGrain = "Monthly"
        TimePeriod = @{
            StartDate = $Start.ToString("yyyy-MM-ddTHH:mm:ssZ")
            EndDate = $End.ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
        Notification = $Notifications
    }

    if ($DepartmentTag -or $CostCenterTag) {
$filters = @{
            Tags = @{}
        }

        if ($DepartmentTag) {
    [string]$filters.Tags["Department"] = @($DepartmentTag)
            Write-Log "Added department filter: $DepartmentTag"
        }

        if ($CostCenterTag) {
    [string]$filters.Tags["CostCenter"] = @($CostCenterTag)
            Write-Log "Added cost center filter: $CostCenterTag"
        }
    [string]$BudgetParams.Filter = $filters
    }

    try {
$ExistingBudget = Get-AzConsumptionBudget -Name $Name -Scope $Scope -ErrorAction SilentlyContinue

        if ($ExistingBudget) {
            Write-Log "Budget '$Name' already exists. Updating with new configuration."
    [string]$budget = Set-AzConsumptionBudget -ErrorAction Stop @budgetParams
            Write-Log "Budget updated successfully"
        }
        else {
$budget = New-AzConsumptionBudget -ErrorAction Stop @budgetParams
            Write-Log "Budget created successfully"
        }

        return $budget
    }
    catch {
        Write-Log "Failed to create/update budget: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Test-BudgetConfiguration {
    param(
        [object]$Budget,
        [string[]]$TestRecipients
    )

    Write-Log "Testing budget configuration and notifications"

    try {
$CurrentSpend = Get-AzConsumptionUsageDetail -StartDate $StartDate -EndDate (Get-Date) -Scope $Budget.Scope |
            Measure-Object -Property PretaxCost -Sum | Select-Object -ExpandProperty Sum

        if (-not $CurrentSpend) { $CurrentSpend = 0 }
    [string]$UtilizationPercent = [math]::Round(($CurrentSpend / $BudgetAmount) * 100, 2)

        Write-Log "Current spending: $($CurrentSpend.ToString('C')) (${utilizationPercent}% of budget)"
    [string]$AlertStatus = "Good"
    [string]$MaxThreshold = ($AlertThreshold | Measure-Object -Maximum).Maximum

        if ($UtilizationPercent -ge $MaxThreshold) {
    [string]$AlertStatus = "Critical"
        }
        elseif ($UtilizationPercent -ge ($AlertThreshold | Sort-Object -Descending | Select-Object -First 2 | Select-Object -Last 1)) {
    [string]$AlertStatus = "Warning"
        }
    [string]$subject = "Azure Budget Alert Test - $($Budget.Name)"
    [string]$body = @"
Azure Budget Configuration Test

Budget Name: $($Budget.Name)
Budget Amount: $($BudgetAmount.ToString('C'))
Current Spending: $($CurrentSpend.ToString('C'))
Utilization: ${utilizationPercent}%
Status: $AlertStatus

Alert Thresholds: $($AlertThreshold -join '%, ')%
Recipients: $($TestRecipients -join ', ')

This is a test notification to verify your budget alert configuration is working correctly.

Budget Details:
- Scope: $($Budget.Scope)
- Time Period: $($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))
- Time Grain: Monthly
- Notifications: $($Budget.Notifications.Count) alert(s) configured

Next Steps:
1. Verify you received this email at all specified addresses
2. Monitor budget utilization in the Azure portal
3. Check budget status regularly in Cost Management

For questions or issues, please contact the IT team.

Best regards,
Azure Cost Management System
"@

        Write-Log "Budget test completed. Current utilization: ${utilizationPercent}%"

        return @{
            CurrentSpend = $CurrentSpend
            UtilizationPercent = $UtilizationPercent
            AlertStatus = $AlertStatus

} catch {
        Write-Log "Budget test failed: $($_.Exception.Message)" -Level "WARNING"
        return $null
    }
}

function Show-BudgetSummary {
    param(
        [object]$Budget,
        [hashtable]$TestResults
    )

    Write-Host "`n$('=' * 60)" -ForegroundColor Green
    Write-Host "BUDGET ALERT SETUP SUMMARY" -ForegroundColor Green
    Write-Host "$('=' * 60)" -ForegroundColor Green

    Write-Output "Budget Name: " -NoNewline -ForegroundColor White
    Write-Output $Budget.Name -ForegroundColor Green

    Write-Output "Budget Amount: " -NoNewline -ForegroundColor White
    Write-Output $BudgetAmount.ToString('C') -ForegroundColor Green

    Write-Output "Scope: " -NoNewline -ForegroundColor White
    Write-Output $Budget.Scope -ForegroundColor Gray

    Write-Output "Time Period: " -NoNewline -ForegroundColor White
    Write-Host "$($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor Green

    Write-Output "Alert Thresholds: " -NoNewline -ForegroundColor White
    Write-Host "$(($AlertThreshold -join '%, '))%" -ForegroundColor Green

    Write-Output "Recipients: " -NoNewline -ForegroundColor White
    Write-Host ($Recipients -join ", ") -ForegroundColor Gray

    if ($TestResults) {
        Write-Host "`nCurrent Status:" -ForegroundColor Green
        Write-Output "Current Spending: " -NoNewline -ForegroundColor White
        Write-Output $TestResults.CurrentSpend.ToString('C') -ForegroundColor $(if ($TestResults.AlertStatus -eq "Critical") { "Red" } elseif ($TestResults.AlertStatus -eq "Warning") { "Yellow" } else { "Green" })

        Write-Output "Budget Utilization: " -NoNewline -ForegroundColor White
        Write-Output "$($TestResults.UtilizationPercent)%" -ForegroundColor $(if ($TestResults.AlertStatus -eq "Critical") { "Red" } elseif ($TestResults.AlertStatus -eq "Warning") { "Yellow" } else { "Green" })

        Write-Output "Alert Status: " -NoNewline -ForegroundColor White
        Write-Output $TestResults.AlertStatus -ForegroundColor $(if ($TestResults.AlertStatus -eq "Critical") { "Red" } elseif ($TestResults.AlertStatus -eq "Warning") { "Yellow" } else { "Green" })
    }

    Write-Host "`nNext Steps:" -ForegroundColor Green
    Write-Host "- Monitor budget in Azure Portal (Cost Management + Billing)" -ForegroundColor Green
    Write-Host "- Check email alerts when thresholds are reached" -ForegroundColor Green
    Write-Host "- Review and adjust budget amounts as needed" -ForegroundColor Green
    Write-Host "- Set up additional budgets for other scopes if required" -ForegroundColor Green

    Write-Host "`nBudget alert setup completed successfully!" -ForegroundColor Green
}


try {
    Write-Log "Starting Azure budget alerts setup"
    [string]$context = Test-AzureConnection

    if (-not $SubscriptionId) {
    [string]$SubscriptionId = $context.Subscription.Id
    }

    try {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-Log "Using subscription: $SubscriptionId"
    }
    catch {
        throw "Cannot access subscription $SubscriptionId. Please check your permissions."
    }

    if (-not $BudgetName) {
    [string]$ScopePrefix = if ($ResourceGroup) { "RG-$ResourceGroup" } else { "Sub" }
    [string]$DepartmentSuffix = if ($Department) { "-$Department" } else { "" }
    [string]$BudgetName = "$ScopePrefix-Budget$DepartmentSuffix-$(Get-Date -Format 'yyyyMM')"
    }

    Write-Log "Budget name: $BudgetName"

    if (-not $EndDate) {
    [string]$EndDate = $StartDate.AddYears(1)
    }

    if ($StartDate -ge $EndDate) {
        throw "Start date must be before end date"
    }

    if ($BudgetAmount -le 0) {
        throw "Budget amount must be greater than zero"
    }

    foreach ($threshold in $AlertThreshold) {
        if ($threshold -le 0 -or $threshold -gt 100) {
            throw "Alert thresholds must be between 1 and 100 percent"
        }
    }
$scope = Get-BudgetScope -Subscription $SubscriptionId -ResourceGroupName $ResourceGroup
$notifications = New-BudgetAlerts -Thresholds $AlertThreshold -EmailAddresses $Recipients
$budget = New-AzureBudget -Name $BudgetName -Scope $scope -Amount $BudgetAmount -Start $StartDate -End $EndDate -Notifications $notifications -DepartmentTag $Department -CostCenterTag $CostCenter
    [string]$TestResults = Test-BudgetConfiguration -Budget $budget -TestRecipients $Recipients

    Show-BudgetSummary -Budget $budget -TestResults $TestResults

    Write-Log "Budget alerts setup completed successfully" -Level "SUCCESS"
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error "Budget setup failed: $($_.Exception.Message)"
    throw
}
finally {
    Write-Log "Script execution completed"`n}
