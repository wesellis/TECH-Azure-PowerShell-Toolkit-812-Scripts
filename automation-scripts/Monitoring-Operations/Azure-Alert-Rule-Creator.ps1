# ============================================================================
# Script Name: Azure Alert Rule Creator
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Creates Azure Monitor alert rules for proactive monitoring
# ============================================================================

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

Write-Information "Creating Alert Rule: $AlertRuleName"

# Create action group if email is provided
if ($NotificationEmail) {
    $ActionGroupName = "$AlertRuleName-actiongroup"
    
    $EmailReceiver = New-AzActionGroupReceiver -ErrorAction Stop `
        -Name "EmailAlert" `
        -EmailReceiver `
        -EmailAddress $NotificationEmail
    
    $ActionGroup = Set-AzActionGroup -ErrorAction Stop `
        -ResourceGroupName $ResourceGroupName `
        -Name $ActionGroupName `
        -ShortName "AlertAG" `
        -Receiver $EmailReceiver
    
    Write-Information "Action Group created: $ActionGroupName"
}

# Create alert rule condition
$Condition = New-AzMetricAlertRuleV2Criteria -ErrorAction Stop `
    -MetricName $MetricName `
    -TimeAggregation "Average" `
    -Operator $Operator `
    -Threshold $Threshold

# Create alert rule
$AlertRule = Add-AzMetricAlertRuleV2 `
    -ResourceGroupName $ResourceGroupName `
    -Name $AlertRuleName `
    -TargetResourceId $TargetResourceId `
    -Condition $Condition `
    -Severity 2 `
    -WindowSize "PT5M" `
    -Frequency "PT1M"

Write-Information "Alert Rule ID: $($AlertRule.Id)"

if ($ActionGroup) {
    # Associate action group with alert rule
    Add-AzMetricAlertRuleV2 `
        -ResourceGroupName $ResourceGroupName `
        -Name $AlertRuleName `
        -TargetResourceId $TargetResourceId `
        -Condition $Condition `
        -ActionGroupId $ActionGroup.Id `
        -Severity 2 `
        -WindowSize "PT5M" `
        -Frequency "PT1M"
}

Write-Information "✅ Alert Rule created successfully:"
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
