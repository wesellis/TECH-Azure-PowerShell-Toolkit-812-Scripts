#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    enable policy compliance scans
.DESCRIPTION
    enable policy compliance scans operation
    Author: Wes Ellis (wes@wesellis.com)
#>

    Enables and configures periodic Azure Policy compliance scans

    Configures Azure Policy compliance scanning frequency and triggers
    on-demand compliance evaluations. Supports scheduling automatic
    scans and monitoring compliance state changes.
.PARAMETER SubscriptionId
    Target subscription for compliance scans
.PARAMETER ManagementGroupId
    Target management group for compliance scans
.PARAMETER PolicyAssignmentName
    Specific policy assignment to scan
.PARAMETER TriggerScan
    Trigger an immediate compliance scan
.PARAMETER ScheduleScans
    Enable scheduled compliance scans
.PARAMETER ScanFrequency
    Frequency for scheduled scans: Daily, Weekly, Monthly
.PARAMETER NotificationEmail
    Email address for compliance notifications
.PARAMETER ResourceGroupName
    Limit scans to specific resource group
.PARAMETER ExcludeCompliant
    Exclude compliant resources from scan results

    .\enable-policy-compliance-scans.ps1 -TriggerScan -SubscriptionId "12345678-1234-1234-1234-123456789012"

    Triggers immediate compliance scan for subscription

    .\enable-policy-compliance-scans.ps1 -ScheduleScans -ScanFrequency Weekly -NotificationEmail "admin@example.com"

    Enables weekly scheduled scans with email notifications#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [Parameter()]
    [string]$ManagementGroupId,

    [Parameter()]
    [string]$PolicyAssignmentName,

    [Parameter()]
    [switch]$TriggerScan,

    [Parameter()]
    [switch]$ScheduleScans,

    [Parameter()]
    [ValidateSet('Daily', 'Weekly', 'Monthly')]
    [string]$ScanFrequency = 'Weekly',

    [Parameter()]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$NotificationEmail,

    [Parameter()]
    [string]$ResourceGroupName,

    [Parameter()]
    [switch]$ExcludeCompliant
)

$ErrorActionPreference = 'Stop'

[OutputType([PSCustomObject])]
 {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Yellow
        Connect-AzAccount
    }
    return Get-AzContext
}

function Get-ComplianceScope {
    param(
        [string]$SubscriptionId,
        [string]$ManagementGroupId,
        [string]$ResourceGroupName
    )

    if ($ManagementGroupId) {
        return "/providers/Microsoft.Management/managementGroups/$ManagementGroupId"
    }
    elseif ($SubscriptionId) {
        if ($ResourceGroupName) {
            return "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"
        }
        else {
            return "/subscriptions/$SubscriptionId"
        }
    }
    else {
        $context = Get-AzContext
        if ($ResourceGroupName) {
            return "/subscriptions/$($context.Subscription.Id)/resourceGroups/$ResourceGroupName"
        }
        else {
            return "/subscriptions/$($context.Subscription.Id)"
        }
    }
}

function Start-ComplianceScan {
    param(
        [string]$Scope,
        [string]$PolicyAssignment
    )

    try {
        Write-Host "Triggering compliance evaluation for scope: $Scope" -ForegroundColor Yellow

        $params = @{}
        if ($PolicyAssignment) {
            # Trigger scan for specific policy assignment
            $params['PolicyAssignmentName'] = $PolicyAssignment
            $params['SubscriptionId'] = ($Scope -split '/')[2]
        }
        else {
            # Trigger scan for entire scope
            if ($Scope -match '/subscriptions/([^/]+)') {
                $params['SubscriptionId'] = $Matches[1]
            }
        }

        # Start policy compliance evaluation
        $job = Start-AzPolicyComplianceScan @params

        Write-Host "Compliance scan initiated successfully" -ForegroundColor Green
        Write-Host "Scan Job ID: $($job.Name)" -ForegroundColor Cyan

        return $job
    }
    catch {
        Write-Error "Failed to trigger compliance scan: $_"
        throw
    }
}

function Get-ComplianceStatus {
    param(
        [string]$Scope,
        [bool]$ExcludeCompliant
    )

    try {
        Write-Host "Retrieving compliance status..." -ForegroundColor Yellow

        $params = @{
            Scope = $Scope
            Top = 1000
        }

        if ($ExcludeCompliant) {
            $params['Filter'] = "ComplianceState eq 'NonCompliant'"
        }

        $states = Get-AzPolicyState @params

        $summary = @{
            TotalResources = $states.Count
            Compliant = ($states | Where-Object { $_.ComplianceState -eq 'Compliant' }).Count
            NonCompliant = ($states | Where-Object { $_.ComplianceState -eq 'NonCompliant' }).Count
            Unknown = ($states | Where-Object { $_.ComplianceState -eq 'Unknown' }).Count
        }

        $summary.CompliancePercentage = if ($summary.TotalResources -gt 0) {
            [Math]::Round(($summary.Compliant / $summary.TotalResources) * 100, 2)
        } else { 0 }

        return @{
            Summary = $summary
            Details = $states
        
} catch {
        Write-Error "Failed to retrieve compliance status: $_"
        throw
    }
}

function Set-ComplianceSchedule {
    param(
        [string]$Frequency,
        [string]$Scope,
        [string]$NotificationEmail
    )

    Write-Host "Configuring compliance scan schedule..." -ForegroundColor Yellow

    # Note: Azure Policy compliance scans run automatically
    # This function demonstrates how you could set up additional automation

    $scheduleConfig = @{
        Frequency = $Frequency
        Scope = $Scope
        LastConfigured = Get-Date
        NotificationEmail = $NotificationEmail
    }

    # In a real implementation, you might:
    # 1. Create an Azure Logic App for scheduled scanning
    # 2. Set up Azure Automation runbooks
    # 3. Configure monitoring alerts

    Write-Host "Schedule configuration:" -ForegroundColor Cyan
    Write-Host "Frequency: $Frequency"
    Write-Host "Scope: $Scope"
    if ($NotificationEmail) {
        Write-Host "Notifications: $NotificationEmail"
    }

    Write-Host "`nNote: Azure Policy automatically evaluates compliance." -ForegroundColor Yellow
    Write-Host "Consider setting up Logic Apps or Automation for custom scheduling." -ForegroundColor Yellow

    return $scheduleConfig
}

function Send-ComplianceNotification {
    param(
        [object]$ComplianceData,
        [string]$EmailAddress
    )

    if (-not $EmailAddress) {
        return
    }

    $summary = $ComplianceData.Summary

    Write-Host "`nWould send compliance notification to: $EmailAddress" -ForegroundColor Yellow
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "Total Resources: $($summary.TotalResources)"
    Write-Host "Compliant: $($summary.Compliant) ($($summary.CompliancePercentage)%)"
    Write-Host "Non-Compliant: $($summary.NonCompliant)"
    Write-Host "Unknown: $($summary.Unknown)"

    # In a real implementation, you would use:
    # - Send-MailMessage (if SMTP is configured)
    # - Azure Logic Apps for email
    # - Azure Monitor Action Groups
    # - Microsoft Graph API for Office 365

    Write-Host "`nNote: Email functionality requires additional configuration" -ForegroundColor Yellow
}

function Show-ComplianceReport {
    param([object]$ComplianceData)

    $summary = $ComplianceData.Summary

    Write-Host "`nCompliance Report" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host "Generated: $(Get-Date)" -ForegroundColor Gray

    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "Total Resources: $($summary.TotalResources)"
    Write-Host "Compliant: $($summary.Compliant)" -ForegroundColor Green
    Write-Host "Non-Compliant: $($summary.NonCompliant)" -ForegroundColor $(if ($summary.NonCompliant -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Unknown: $($summary.Unknown)" -ForegroundColor Yellow
    Write-Host "Compliance Rate: $($summary.CompliancePercentage)%"

    if ($summary.NonCompliant -gt 0 -and $ComplianceData.Details) {
        Write-Host "`nTop Non-Compliant Resources:" -ForegroundColor Red
        $ComplianceData.Details |
            Where-Object { $_.ComplianceState -eq 'NonCompliant' } |
            Select-Object -First 5 |
            ForEach-Object {
                $resourceName = ($_.ResourceId -split '/')[-1]
                Write-Host "  - $resourceName ($($_.ResourceType))" -ForegroundColor Red
            }
    }
}

# Main execution
Write-Host "`nAzure Policy Compliance Scanner" -ForegroundColor Cyan
Write-Host ("=" * 50) -ForegroundColor Cyan

$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

# Set subscription context if provided
if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
}

# Determine compliance scope
$scope = Get-ComplianceScope -SubscriptionId $SubscriptionId -ManagementGroupId $ManagementGroupId -ResourceGroupName $ResourceGroupName
Write-Host "Compliance scope: $scope" -ForegroundColor Cyan

# Trigger compliance scan if requested
if ($TriggerScan) {
    $scanJob = Start-ComplianceScan -Scope $scope -PolicyAssignment $PolicyAssignmentName

    # Wait a moment for scan to process
    Write-Host "Waiting for scan to process..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
}

# Get current compliance status
$complianceData = Get-ComplianceStatus -Scope $scope -ExcludeCompliant $ExcludeCompliant

# Show compliance report
Show-ComplianceReport -ComplianceData $complianceData

# Configure scheduled scans if requested
if ($ScheduleScans) {
    $scheduleConfig = Set-ComplianceSchedule -Frequency $ScanFrequency -Scope $scope -NotificationEmail $NotificationEmail
}

# Send notification if email is provided
if ($NotificationEmail) {
    Send-ComplianceNotification -ComplianceData $complianceData -EmailAddress $NotificationEmail
}

Write-Host "`nCompliance scan configuration completed!" -ForegroundColor Green

# Return compliance data
return $complianceData\n

