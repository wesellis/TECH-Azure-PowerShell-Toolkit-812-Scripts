#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure script

.DESCRIPTION
.DESCRIPTION`n    Automate Azure operations
    Author: Wes Ellis (wes@wesellis.com)#>
[CmdletBinding()]

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
Write-Host "Creating Alert Rule: $AlertRuleName"
# Create action group if email is provided
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
# Create alert rule condition
$params = @{
    Threshold = $Threshold
    ErrorAction = "Stop"
    MetricName = $MetricName
    TimeAggregation = "Average"
    Operator = $Operator
}
$Condition @params
# Create alert rule
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
Write-Host "Alert Rule ID: $($AlertRule.Id)"
if ($ActionGroup) {
    # Associate action group with alert rule
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
Write-Host "Alert Rule created successfully:"
Write-Host "Name: $AlertRuleName"
Write-Host "Metric: $MetricName"
Write-Host "Threshold: $Operator $Threshold"
Write-Host "Target Resource: $($TargetResourceId.Split('/')[-1])"
if ($NotificationEmail) {
    Write-Host "Notification Email: $NotificationEmail"
}
Write-Host "`nAlert Rule Features:"
Write-Host "Real-time monitoring"
Write-Host "Configurable thresholds"
Write-Host "Multiple notification channels"
Write-Host "Auto-resolution"

