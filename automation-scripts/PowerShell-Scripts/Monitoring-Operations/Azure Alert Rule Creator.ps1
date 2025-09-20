#Requires -Version 7.0
#Requires -Modules Az.Resources

<#
.SYNOPSIS
    Azure Alert Rule Creator

.DESCRIPTION
    Azure automation\n    Author: Wes Ellis (wes@wesellis.com)\n#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { "Continue" } else { "SilentlyContinue" }
[CmdletBinding()]
function Write-Host {
    [CmdletBinding()]
param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        [string]$Level = "INFO"
    )
$timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
$colorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}
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
Write-Host "Creating Alert Rule: $AlertRuleName" "INFO"
if ($NotificationEmail) {
    $ActionGroupName = " $AlertRuleName-actiongroup"
    $params = @{
        ResourceGroupName = $ResourceGroupName
        Name = $ActionGroupName
        Receiver = $EmailReceiver  Write-Host "Action Group created: $ActionGroupName" " INFO
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
Write-Host "Alert Rule ID: $($AlertRule.Id)" "INFO"
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
Write-Host "Alert Rule created successfully:" "INFO"
Write-Host "Name: $AlertRuleName" "INFO"
Write-Host "Metric: $MetricName" "INFO"
Write-Host "Threshold: $Operator $Threshold" "INFO"
Write-Host "Target Resource: $($TargetResourceId.Split('/')[-1])" "INFO"
if ($NotificationEmail) {
    Write-Host "Notification Email: $NotificationEmail" "INFO"
}
Write-Host " `nAlert Rule Features:" "INFO"
Write-Host "Real-time monitoring" "INFO"
Write-Host "Configurable thresholds" "INFO"
Write-Host "Multiple notification channels" "INFO"
Write-Host "Auto-resolution" "INFO"
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    throw
}\n

