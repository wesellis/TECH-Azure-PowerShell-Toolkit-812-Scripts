#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Alert Rule Creator

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    [string]$ErrorActionPreference = "Stop"
    [string]$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
    [string]$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    [string]$LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AlertRuleName,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TargetResourceId,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$MetricName,
    [Parameter(Mandatory)]
    [double]$Threshold,
    [Parameter()]
    [string]$Operator = "GreaterThan" ,
    [Parameter()]
    [string]$NotificationEmail
)
Write-Output "Creating Alert Rule: $AlertRuleName" "INFO"
if ($NotificationEmail) {
    [string]$ActionGroupName = " $AlertRuleName-actiongroup"
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name = $ActionGroupName
        Receiver = $EmailReceiver  Write-Output "Action Group created: $ActionGroupName" " INFO
        ShortName = "AlertAG"
        ErrorAction = "Stop"
        EmailAddress = $NotificationEmail  $ActionGroup = Set-AzActionGroup
    }
    [string]$EmailReceiver @params
}
    $params = @{
    Threshold = $Threshold
    ErrorAction = "Stop"
    MetricName = $MetricName
    TimeAggregation = "Average"
    Operator = $Operator
}
    [string]$Condition @params
    $params = @{
    ResourceGroupName = $ResourceGroupName
    Name = $AlertRuleName
    Severity = "2"
    Frequency = "PT1M"
    WindowSize = "PT5M"
    TargetResourceId = $TargetResourceId
    Condition = $Condition
}
    [string]$AlertRule @params
Write-Output "Alert Rule ID: $($AlertRule.Id)" "INFO"
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
Write-Output "Alert Rule created successfully:" "INFO"
Write-Output "Name: $AlertRuleName" "INFO"
Write-Output "Metric: $MetricName" "INFO"
Write-Output "Threshold: $Operator $Threshold" "INFO"
Write-Output "Target Resource: $($TargetResourceId.Split('/')[-1])" "INFO"
if ($NotificationEmail) {
    Write-Output "Notification Email: $NotificationEmail" "INFO"
}
Write-Output " `nAlert Rule Features:" "INFO"
Write-Output "Real-time monitoring" "INFO"
Write-Output "Configurable thresholds" "INFO"
Write-Output "Multiple notification channels" "INFO"
Write-Output "Auto-resolution" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw`n}
