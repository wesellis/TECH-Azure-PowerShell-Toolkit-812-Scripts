#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)
[CmdletBinding()]

$ErrorActionPreference = 'Stop'

    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$AlertRuleName,
    [Parameter(Mandatory)]
    [string]$TargetResourceId,
    [Parameter(Mandatory)]
    [string]$MetricName,
    [Parameter(Mandatory)]
    [double]$Threshold,
    [Parameter()]
    [string]$Operator = "GreaterThan",
    [Parameter()]
    [string]$NotificationEmail
)
Write-Output "Creating Alert Rule: $AlertRuleName"
if ($NotificationEmail) {
    $ActionGroupName = "$AlertRuleName-actiongroup"
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name = $ActionGroupName
        Receiver = $EmailReceiver  Write-Host "Action Group created: $ActionGroupName
        ShortName = "AlertAG"
        ErrorAction = "Stop"
        EmailAddress = $NotificationEmail  $ActionGroup = Set-AzActionGroup
    }
    $EmailReceiver @params
}
$params = @{
    Threshold = $Threshold
    ErrorAction = "Stop"
    MetricName = $MetricName
    TimeAggregation = "Average"
    Operator = $Operator
}
$Condition @params
$params = @{
    ResourceGroupName = $ResourceGroupName
    Name = $AlertRuleName
    Severity = "2"
    Frequency = "PT1M"
    WindowSize = "PT5M"
    TargetResourceId = $TargetResourceId
    Condition = $Condition
}
$AlertRule @params
Write-Output "Alert Rule ID: $($AlertRule.Id)"
if ($ActionGroup) {
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name = $AlertRuleName
        Severity = "2"
        Condition = $Condition
        WindowSize = "PT5M"
        TargetResourceId = $TargetResourceId
        ActionGroupId = $ActionGroup.Id
        Frequency = "PT1M"
    }
    Add-AzMetricAlertRuleV2 @params
}
Write-Output "Alert Rule created successfully:"
Write-Output "Name: $AlertRuleName"
Write-Output "Metric: $MetricName"
Write-Output "Threshold: $Operator $Threshold"
Write-Output "Target Resource: $($TargetResourceId.Split('/')[-1])"
if ($NotificationEmail) {
    Write-Output "Notification Email: $NotificationEmail"
}
Write-Output "`nAlert Rule Features:"
Write-Output "Real-time monitoring"
Write-Output "Configurable thresholds"
Write-Output "Multiple notification channels"
Write-Output "Auto-resolution"



