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

Write-Host "Creating Alert Rule: $AlertRuleName"

# Create action group if email is provided
if ($NotificationEmail) {
    $ActionGroupName = "$AlertRuleName-actiongroup"
    
    $EmailReceiver = New-AzActionGroupReceiver `
        -Name "EmailAlert" `
        -EmailReceiver `
        -EmailAddress $NotificationEmail
    
    $ActionGroup = Set-AzActionGroup `
        -ResourceGroupName $ResourceGroupName `
        -Name $ActionGroupName `
        -ShortName "AlertAG" `
        -Receiver $EmailReceiver
    
    Write-Host "Action Group created: $ActionGroupName"
}

# Create alert rule condition
$Condition = New-AzMetricAlertRuleV2Criteria `
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

Write-Host "✅ Alert Rule created successfully:"
Write-Host "  Name: $AlertRuleName"
Write-Host "  Metric: $MetricName"
Write-Host "  Threshold: $Operator $Threshold"
Write-Host "  Target Resource: $($TargetResourceId.Split('/')[-1])"
if ($NotificationEmail) {
    Write-Host "  Notification Email: $NotificationEmail"
}

Write-Host "`nAlert Rule Features:"
Write-Host "• Real-time monitoring"
Write-Host "• Configurable thresholds"
Write-Host "• Multiple notification channels"
Write-Host "• Auto-resolution"
