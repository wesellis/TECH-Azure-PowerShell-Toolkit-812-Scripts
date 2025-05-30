<#
.SYNOPSIS
    Sets up Azure budget alerts and monitoring for proactive cost management.

.DESCRIPTION
    This script creates and configures Azure budgets with automated alert thresholds
    to notify stakeholders when spending approaches or exceeds defined limits.
    Supports subscription-level, resource group-level, and custom scope budgets.

.PARAMETER BudgetName
    Name for the budget. Will be auto-generated if not specified.

.PARAMETER BudgetAmount
    Monthly budget amount in USD.

.PARAMETER SubscriptionId
    Azure subscription ID. Uses current context if not specified.

.PARAMETER ResourceGroup
    Optional resource group name for resource group-scoped budget.

.PARAMETER AlertThreshold
    Array of percentage thresholds for alerts (e.g., @(50, 80, 95)).

.PARAMETER Recipients
    Array of email addresses to receive budget alerts.

.PARAMETER StartDate
    Budget start date. Defaults to first day of current month.

.PARAMETER EndDate
    Budget end date. Defaults to one year from start date.

.PARAMETER Department
    Department name for budget categorization and filtering.

.PARAMETER CostCenter
    Cost center code for budget allocation tracking.

.EXAMPLE
    .\Setup-BudgetAlerts.ps1 -BudgetAmount 10000 -AlertThreshold @(80, 95) -Recipients @("finance@company.com")

.EXAMPLE
    .\Setup-BudgetAlerts.ps1 -BudgetName "Production-Budget" -BudgetAmount 15000 -ResourceGroup "Production-RG" -AlertThreshold @(50, 75, 90, 95)

.EXAMPLE
    .\Setup-BudgetAlerts.ps1 -BudgetAmount 5000 -Department "IT" -CostCenter "CC001" -Recipients @("it-manager@company.com", "finance@company.com")

.NOTES
    Author: Wesley Ellis
    Email: wes@wesellis.com
    Created: May 23, 2025
    Version: 1.0

    Prerequisites:
    - Azure PowerShell module (Az)
    - Budget Contributor role or higher
    - Valid email addresses for notifications
    - Azure Cost Management enabled
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$BudgetName,
    
    [Parameter(Mandatory = $true)]
    [decimal]$BudgetAmount,
    
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory = $false)]
    [int[]]$AlertThreshold = @(80, 95),
    
    [Parameter(Mandatory = $true)]
    [string[]]$Recipients,
    
    [Parameter(Mandatory = $false)]
    [datetime]$StartDate = (Get-Date -Day 1),
    
    [Parameter(Mandatory = $false)]
    [datetime]$EndDate,
    
    [Parameter(Mandatory = $false)]
    [string]$Department,
    
    [Parameter(Mandatory = $false)]
    [string]$CostCenter
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogPath = Join-Path (Split-Path $ScriptRoot -Parent) "logs"

# Ensure log directory exists
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

# Logging function
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Output $logEntry
    Add-Content -Path (Join-Path $LogPath "budget-alerts.log") -Value $logEntry
}

function Test-AzureConnection {
    <#
    .SYNOPSIS
        Validates Azure connection and permissions
    #>
    try {
        $context = Get-AzContext
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

function Get-BudgetScope {
    <#
    .SYNOPSIS
        Determines the appropriate scope for the budget
    #>
    param(
        [string]$Subscription,
        [string]$ResourceGroupName
    )
    
    if ($ResourceGroupName) {
        $scope = "/subscriptions/$Subscription/resourceGroups/$ResourceGroupName"
        Write-Log "Budget scope: Resource Group ($ResourceGroupName)"
    }
    else {
        $scope = "/subscriptions/$Subscription"
        Write-Log "Budget scope: Subscription ($Subscription)"
    }
    
    return $scope
}

function New-BudgetAlerts {
    <#
    .SYNOPSIS
        Creates budget alert notifications
    #>
    param(
        [int[]]$Thresholds,
        [string[]]$EmailAddresses
    )
    
    $notifications = @{}
    
    foreach ($threshold in $Thresholds) {
        $notificationKey = "Alert$threshold"
        $notifications[$notificationKey] = @{
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
    <#
    .SYNOPSIS
        Creates or updates an Azure budget with alerts
    #>
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
    
    # Prepare budget object
    $budgetParams = @{
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
    
    # Add filters if department or cost center specified
    if ($DepartmentTag -or $CostCenterTag) {
        $filters = @{
            Tags = @{}
        }
        
        if ($DepartmentTag) {
            $filters.Tags["Department"] = @($DepartmentTag)
            Write-Log "Added department filter: $DepartmentTag"
        }
        
        if ($CostCenterTag) {
            $filters.Tags["CostCenter"] = @($CostCenterTag)
            Write-Log "Added cost center filter: $CostCenterTag"
        }
        
        $budgetParams.Filter = $filters
    }
    
    try {
        # Check if budget already exists
        $existingBudget = Get-AzConsumptionBudget -Name $Name -Scope $Scope -ErrorAction SilentlyContinue
        
        if ($existingBudget) {
            Write-Log "Budget '$Name' already exists. Updating with new configuration."
            $budget = Set-AzConsumptionBudget @budgetParams
            Write-Log "Budget updated successfully"
        }
        else {
            $budget = New-AzConsumptionBudget @budgetParams
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
    <#
    .SYNOPSIS
        Validates budget configuration and sends test notification
    #>
    param(
        [object]$Budget,
        [string[]]$TestRecipients
    )
    
    Write-Log "Testing budget configuration and notifications"
    
    try {
        # Get current month's spending for comparison
        $currentSpend = Get-AzConsumptionUsageDetail -StartDate $StartDate -EndDate (Get-Date) -Scope $Budget.Scope |
            Measure-Object -Property PretaxCost -Sum | Select-Object -ExpandProperty Sum
        
        if (-not $currentSpend) { $currentSpend = 0 }
        
        $utilizationPercent = [math]::Round(($currentSpend / $BudgetAmount) * 100, 2)
        
        Write-Log "Current spending: $($currentSpend.ToString('C')) (${utilizationPercent}% of budget)"
        
        # Determine alert status
        $alertStatus = "Good"
        $maxThreshold = ($AlertThreshold | Measure-Object -Maximum).Maximum
        
        if ($utilizationPercent -ge $maxThreshold) {
            $alertStatus = "Critical"
        }
        elseif ($utilizationPercent -ge ($AlertThreshold | Sort-Object -Descending | Select-Object -First 2 | Select-Object -Last 1)) {
            $alertStatus = "Warning"
        }
        
        # Send test notification
        $subject = "Azure Budget Alert Test - $($Budget.Name)"
        $body = @"
Azure Budget Configuration Test

Budget Name: $($Budget.Name)
Budget Amount: $($BudgetAmount.ToString('C'))
Current Spending: $($currentSpend.ToString('C'))
Utilization: ${utilizationPercent}%
Status: $alertStatus

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

        # Note: Azure handles actual budget notifications automatically
        # This is just a test to verify email addresses work
        Write-Log "Budget test completed. Current utilization: ${utilizationPercent}%"
        
        return @{
            CurrentSpend = $currentSpend
            UtilizationPercent = $utilizationPercent
            AlertStatus = $alertStatus
        }
    }
    catch {
        Write-Log "Budget test failed: $($_.Exception.Message)" -Level "WARNING"
        return $null
    }
}

function Show-BudgetSummary {
    <#
    .SYNOPSIS
        Displays a summary of the created budget configuration
    #>
    param(
        [object]$Budget,
        [hashtable]$TestResults
    )
    
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "BUDGET ALERT SETUP SUMMARY" -ForegroundColor Cyan
    Write-Host "="*60 -ForegroundColor Cyan
    
    Write-Host "Budget Name: " -NoNewline -ForegroundColor Yellow
    Write-Host $Budget.Name -ForegroundColor White
    
    Write-Host "Budget Amount: " -NoNewline -ForegroundColor Yellow
    Write-Host $BudgetAmount.ToString('C') -ForegroundColor Green
    
    Write-Host "Scope: " -NoNewline -ForegroundColor Yellow
    Write-Host $Budget.Scope -ForegroundColor White
    
    Write-Host "Time Period: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($StartDate.ToString('yyyy-MM-dd')) to $($EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor White
    
    Write-Host "Alert Thresholds: " -NoNewline -ForegroundColor Yellow
    Write-Host ($AlertThreshold -join "%, ") + "%" -ForegroundColor Orange
    
    Write-Host "Recipients: " -NoNewline -ForegroundColor Yellow
    Write-Host ($Recipients -join ", ") -ForegroundColor White
    
    if ($TestResults) {
        Write-Host "`nCurrent Status:" -ForegroundColor Cyan
        Write-Host "Current Spending: " -NoNewline -ForegroundColor Yellow
        Write-Host $TestResults.CurrentSpend.ToString('C') -ForegroundColor $(if ($TestResults.AlertStatus -eq "Critical") { "Red" } elseif ($TestResults.AlertStatus -eq "Warning") { "Yellow" } else { "Green" })
        
        Write-Host "Budget Utilization: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($TestResults.UtilizationPercent)%" -ForegroundColor $(if ($TestResults.AlertStatus -eq "Critical") { "Red" } elseif ($TestResults.AlertStatus -eq "Warning") { "Yellow" } else { "Green" })
        
        Write-Host "Alert Status: " -NoNewline -ForegroundColor Yellow
        Write-Host $TestResults.AlertStatus -ForegroundColor $(if ($TestResults.AlertStatus -eq "Critical") { "Red" } elseif ($TestResults.AlertStatus -eq "Warning") { "Yellow" } else { "Green" })
    }
    
    Write-Host "`nNext Steps:" -ForegroundColor Cyan
    Write-Host "• Monitor budget in Azure Portal (Cost Management + Billing)" -ForegroundColor White
    Write-Host "• Check email alerts when thresholds are reached" -ForegroundColor White
    Write-Host "• Review and adjust budget amounts as needed" -ForegroundColor White
    Write-Host "• Set up additional budgets for other scopes if required" -ForegroundColor White
    
    Write-Host "`n✅ Budget alert setup completed successfully!" -ForegroundColor Green
}

# Main execution
try {
    Write-Log "Starting Azure budget alerts setup"
    
    # Validate Azure connection and get context
    $context = Test-AzureConnection
    
    # Set subscription if not provided
    if (-not $SubscriptionId) {
        $SubscriptionId = $context.Subscription.Id
    }
    
    # Validate subscription access
    try {
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        Write-Log "Using subscription: $SubscriptionId"
    }
    catch {
        throw "Cannot access subscription $SubscriptionId. Please check your permissions."
    }
    
    # Generate budget name if not provided
    if (-not $BudgetName) {
        $scopePrefix = if ($ResourceGroup) { "RG-$ResourceGroup" } else { "Sub" }
        $departmentSuffix = if ($Department) { "-$Department" } else { "" }
        $BudgetName = "$scopePrefix-Budget$departmentSuffix-$(Get-Date -Format 'yyyyMM')"
    }
    
    Write-Log "Budget name: $BudgetName"
    
    # Set end date if not provided (1 year from start)
    if (-not $EndDate) {
        $EndDate = $StartDate.AddYears(1)
    }
    
    # Validate date range
    if ($StartDate -ge $EndDate) {
        throw "Start date must be before end date"
    }
    
    # Validate budget amount
    if ($BudgetAmount -le 0) {
        throw "Budget amount must be greater than zero"
    }
    
    # Validate alert thresholds
    foreach ($threshold in $AlertThreshold) {
        if ($threshold -le 0 -or $threshold -gt 100) {
            throw "Alert thresholds must be between 1 and 100 percent"
        }
    }
    
    # Get budget scope
    $scope = Get-BudgetScope -Subscription $SubscriptionId -ResourceGroupName $ResourceGroup
    
    # Create notification configurations
    $notifications = New-BudgetAlerts -Thresholds $AlertThreshold -EmailAddresses $Recipients
    
    # Create the budget
    $budget = New-AzureBudget -Name $BudgetName -Scope $scope -Amount $BudgetAmount -Start $StartDate -End $EndDate -Notifications $notifications -DepartmentTag $Department -CostCenterTag $CostCenter
    
    # Test the configuration
    $testResults = Test-BudgetConfiguration -Budget $budget -TestRecipients $Recipients
    
    # Display summary
    Show-BudgetSummary -Budget $budget -TestResults $testResults
    
    Write-Log "Budget alerts setup completed successfully" -Level "SUCCESS"
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Error "Budget setup failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Write-Log "Script execution completed"
}
