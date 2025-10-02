#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    enable policy compliance scans
.DESCRIPTION
    enable policy compliance scans operation
    Author: Wes Ellis (wes@wesellis.com)

    Enables and configures periodic Azure Policy compliance scans

    Configures Azure Policy compliance scanning frequency and triggers
    on-demand compliance evaluations. Supports scheduling automatic
    scans and monitoring compliance state changes.
.parameter SubscriptionId
    Target subscription for compliance scans
.parameter ManagementGroupId
    Target management group for compliance scans
.parameter PolicyAssignmentName
    Specific policy assignment to scan
.parameter TriggerScan
    Trigger an immediate compliance scan
.parameter ScheduleScans
    Enable scheduled compliance scans
.parameter ScanFrequency
    Frequency for scheduled scans: Daily, Weekly, Monthly
.parameter NotificationEmail
    Email address for compliance notifications
.parameter ResourceGroupName
    Limit scans to specific resource group
.parameter ExcludeCompliant
    Exclude compliant resources from scan results

    .\enable-policy-compliance-scans.ps1 -TriggerScan -SubscriptionId "12345678-1234-1234-1234-123456789012"

    Triggers immediate compliance scan for subscription

    .\enable-policy-compliance-scans.ps1 -ScheduleScans -ScanFrequency Weekly -NotificationEmail "admin@example.com"

    Enables weekly scheduled scans with email notifications

[CmdletBinding()]
param(
    [parameter()]
    [ValidateScript({
        try { [System.Guid]::Parse($_) | Out-Null; $true }
        catch { throw "Invalid subscription ID format" }
    })]
    [string]$SubscriptionId,

    [parameter()]
    [string]$ManagementGroupId,

    [parameter()]
    [string]$PolicyAssignmentName,

    [parameter()]
    [switch]$TriggerScan,

    [parameter()]
    [switch]$ScheduleScans,

    [parameter()]
    [ValidateSet('Daily', 'Weekly', 'Monthly')]
    [string]$ScanFrequency = 'Weekly',

    [parameter()]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$NotificationEmail,

    [parameter()]
    [string]$ResourceGroupName,

    [parameter()]
    [switch]$ExcludeCompliant
)
    [string]$ErrorActionPreference = 'Stop'

[OutputType([PSCustomObject])] 
 {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Connecting to Azure..." -ForegroundColor Green
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
        Write-Host "Triggering compliance evaluation for scope: $Scope" -ForegroundColor Green
    $params = @{}
        if ($PolicyAssignment) {
    [string]$params['PolicyAssignmentName'] = $PolicyAssignment
    [string]$params['SubscriptionId'] = ($Scope -split '/')[2]
        }
        else {
            if ($Scope -match '/subscriptions/([^/]+)') {
    [string]$params['SubscriptionId'] = $Matches[1]
            }
        }
    [string]$job = Start-AzPolicyComplianceScan @params

        Write-Host "Compliance scan initiated successfully" -ForegroundColor Green
        Write-Host "Scan Job ID: $($job.Name)" -ForegroundColor Green

        return $job
    }
    catch {
        write-Error "Failed to trigger compliance scan: $_"
        throw
    }
}

function Get-ComplianceStatus {
        param(
        [string]$Scope,
        [bool]$ExcludeCompliant
    )

    try {
        Write-Host "Retrieving compliance status..." -ForegroundColor Green
    $params = @{
            Scope = $Scope
            Top = 1000
        }

        if ($ExcludeCompliant) {
    [string]$params['Filter'] = "ComplianceState eq 'NonCompliant'"
        }
    $states = Get-AzPolicyState @params
    $summary = @{
            TotalResources = $states.Count
            Compliant = ($states | Where-Object { $_.ComplianceState -eq 'Compliant' }).Count
            NonCompliant = ($states | Where-Object { $_.ComplianceState -eq 'NonCompliant' }).Count
            Unknown = ($states | Where-Object { $_.ComplianceState -eq 'Unknown' }).Count
        }
    [string]$summary.CompliancePercentage = if ($summary.TotalResources -gt 0) {
            [Math]::Round(($summary.Compliant / $summary.TotalResources) * 100, 2)
        } else { 0 }

        return @{
            Summary = $summary
            Details = $states

} catch {
        write-Error "Failed to retrieve compliance status: $_"
        throw
    }
}

function Set-ComplianceSchedule {
        param(
        [string]$Frequency,
        [string]$Scope,
        [string]$NotificationEmail
    )

    Write-Host "Configuring compliance scan schedule..." -ForegroundColor Green
    $ScheduleConfig = @{
        Frequency = $Frequency
        Scope = $Scope
        LastConfigured = Get-Date
        NotificationEmail = $NotificationEmail
    }


    Write-Host "Schedule configuration:" -ForegroundColor Green
    Write-Output "Frequency: $Frequency"
    Write-Output "Scope: $Scope"
    if ($NotificationEmail) {
        Write-Output "Notifications: $NotificationEmail"
    }

    Write-Host "`nNote: Azure Policy automatically evaluates compliance." -ForegroundColor Green
    Write-Host "Consider setting up Logic Apps or Automation for custom scheduling." -ForegroundColor Green

    return $ScheduleConfig
}

function Send-ComplianceNotification {
        param(
        [object]$ComplianceData,
        [string]$EmailAddress
    )

    if (-not $EmailAddress) {
        return
    }
    [string]$summary = $ComplianceData.Summary

    Write-Host "`nWould send compliance notification to: $EmailAddress" -ForegroundColor Green
    Write-Host "Summary:" -ForegroundColor Green
    Write-Output "Total Resources: $($summary.TotalResources)"
    Write-Output "Compliant: $($summary.Compliant) ($($summary.CompliancePercentage)%)"
    Write-Output "Non-Compliant: $($summary.NonCompliant)"
    Write-Output "Unknown: $($summary.Unknown)"


    Write-Host "`nNote: Email functionality requires additional configuration" -ForegroundColor Green
}

function Show-ComplianceReport {
        param([object]$ComplianceData)
    [string]$summary = $ComplianceData.Summary

    Write-Host "`nCompliance Report" -ForegroundColor Green
    write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host "Generated: $(Get-Date)" -ForegroundColor Green

    Write-Host "`nSummary:" -ForegroundColor Green
    Write-Output "Total Resources: $($summary.TotalResources)"
    Write-Host "Compliant: $($summary.Compliant)" -ForegroundColor Green
    Write-Output "Non-Compliant: $($summary.NonCompliant)" -ForegroundColor $(if ($summary.NonCompliant -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Unknown: $($summary.Unknown)" -ForegroundColor Green
    Write-Output "Compliance Rate: $($summary.CompliancePercentage)%"

    if ($summary.NonCompliant -gt 0 -and $ComplianceData.Details) {
        Write-Host "`nTop Non-Compliant Resources:" -ForegroundColor Green
    [string]$ComplianceData.Details |
            Where-Object { $_.ComplianceState -eq 'NonCompliant' } |
            Select-Object -First 5 |
            ForEach-Object {
    [string]$ResourceName = ($_.ResourceId -split '/')[-1]
                Write-Host "  - $ResourceName ($($_.ResourceType))" -ForegroundColor Green
            }
    }
}

Write-Host "`nAzure Policy Compliance Scanner" -ForegroundColor Green
write-Host ("=" * 50) -ForegroundColor Cyan
    [string]$context = Test-AzureConnection
Write-Host "Connected to: $($context.Subscription.Name)" -ForegroundColor Green

if ($SubscriptionId) {
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
}
    $scope = Get-ComplianceScope -SubscriptionId $SubscriptionId -ManagementGroupId $ManagementGroupId -ResourceGroupName $ResourceGroupName
Write-Host "Compliance scope: $scope" -ForegroundColor Green

if ($TriggerScan) {
    [string]$ScanJob = Start-ComplianceScan -Scope $scope -PolicyAssignment $PolicyAssignmentName

    Write-Host "Waiting for scan to process..." -ForegroundColor Green
    Start-Sleep -Seconds 10
}
    $ComplianceData = Get-ComplianceStatus -Scope $scope -ExcludeCompliant $ExcludeCompliant

Show-ComplianceReport -ComplianceData $ComplianceData

if ($ScheduleScans) {
    [string]$ScheduleConfig = Set-ComplianceSchedule -Frequency $ScanFrequency -Scope $scope -NotificationEmail $NotificationEmail
}

if ($NotificationEmail) {
    Send-ComplianceNotification -ComplianceData $ComplianceData -EmailAddress $NotificationEmail
}

Write-Host "`nCompliance scan configuration completed!" -ForegroundColor Green

return $ComplianceData\n



