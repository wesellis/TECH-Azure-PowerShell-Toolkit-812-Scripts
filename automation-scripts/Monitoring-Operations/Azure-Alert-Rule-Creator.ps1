#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure automation script

.DESCRIPTION
    Professional PowerShell script for Azure automation

.NOTES
    Author: Wes Ellis (wes@wesellis.com)
    Version: 1.0.0
    LastModified: 2025-09-19
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$AlertRuleName,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetResourceId,
    
    [Parameter(Mandatory=$true)]
    [string]$MetricName,
    
    [Parameter(Mandatory=$true)]
    [double]$Threshold,
    
    [Parameter(Mandatory=$false)]
    [string]$Operator = "GreaterThan",
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationEmail
)

#region Functions

Write-Information "Creating Alert Rule: $AlertRuleName"

# Create action group if email is provided
if ($NotificationEmail) {
    $ActionGroupName = "$AlertRuleName-actiongroup"
    
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name = $ActionGroupName
        Receiver = $EmailReceiver  Write-Information "Action Group created: $ActionGroupName
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

Write-Information "Alert Rule ID: $($AlertRule.Id)"

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

Write-Information " Alert Rule created successfully:"
Write-Information "  Name: $AlertRuleName"
Write-Information "  Metric: $MetricName"
Write-Information "  Threshold: $Operator $Threshold"
Write-Information "  Target Resource: $($TargetResourceId.Split('/')[-1])"
if ($NotificationEmail) {
    Write-Information "  Notification Email: $NotificationEmail"
}

Write-Information "`nAlert Rule Features:"
Write-Information "• Real-time monitoring"
Write-Information "• Configurable thresholds"
Write-Information "• Multiple notification channels"
Write-Information "• Auto-resolution"


#endregion
