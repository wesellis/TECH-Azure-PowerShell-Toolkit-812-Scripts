<#
.SYNOPSIS
    Azure Alert Rule Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Alert Rule Creator

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Enterprise PowerShell Framework

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')
try {
    # Main script execution
) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO" , " WARN" , " ERROR" , " SUCCESS" )]
        [string]$Level = " INFO"
    )
    
   ;  $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan" ; " WARN" = " Yellow" ; " ERROR" = " Red" ; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = " Stop"
param(
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAlertRuleName,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETargetResourceId,
    
    [Parameter(Mandatory=$true)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEMetricName,
    
    [Parameter(Mandatory=$true)]
    [double]$WEThreshold,
    
    [Parameter(Mandatory=$false)]
    [string]$WEOperator = " GreaterThan" ,
    
    [Parameter(Mandatory=$false)]
    [string]$WENotificationEmail
)

Write-WELog " Creating Alert Rule: $WEAlertRuleName" " INFO"


if ($WENotificationEmail) {
    $WEActionGroupName = " $WEAlertRuleName-actiongroup"
    
    $WEEmailReceiver = New-AzActionGroupReceiver `
        -Name " EmailAlert" `
        -EmailReceiver `
        -EmailAddress $WENotificationEmail
    
    $WEActionGroup = Set-AzActionGroup `
        -ResourceGroupName $WEResourceGroupName `
        -Name $WEActionGroupName `
        -ShortName " AlertAG" `
        -Receiver $WEEmailReceiver
    
    Write-WELog " Action Group created: $WEActionGroupName" " INFO"
}

; 
$WECondition = New-AzMetricAlertRuleV2Criteria `
    -MetricName $WEMetricName `
    -TimeAggregation " Average" `
    -Operator $WEOperator `
    -Threshold $WEThreshold

; 
$WEAlertRule = Add-AzMetricAlertRuleV2 `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WEAlertRuleName `
    -TargetResourceId $WETargetResourceId `
    -Condition $WECondition `
    -Severity 2 `
    -WindowSize " PT5M" `
    -Frequency " PT1M"

Write-WELog " Alert Rule ID: $($WEAlertRule.Id)" " INFO"

if ($WEActionGroup) {
    # Associate action group with alert rule
    Add-AzMetricAlertRuleV2 `
        -ResourceGroupName $WEResourceGroupName `
        -Name $WEAlertRuleName `
        -TargetResourceId $WETargetResourceId `
        -Condition $WECondition `
        -ActionGroupId $WEActionGroup.Id `
        -Severity 2 `
        -WindowSize " PT5M" `
        -Frequency " PT1M"
}

Write-WELog " ✅ Alert Rule created successfully:" " INFO"
Write-WELog "  Name: $WEAlertRuleName" " INFO"
Write-WELog "  Metric: $WEMetricName" " INFO"
Write-WELog "  Threshold: $WEOperator $WEThreshold" " INFO"
Write-WELog "  Target Resource: $($WETargetResourceId.Split('/')[-1])" " INFO"
if ($WENotificationEmail) {
    Write-WELog "  Notification Email: $WENotificationEmail" " INFO"
}

Write-WELog " `nAlert Rule Features:" " INFO"
Write-WELog " • Real-time monitoring" " INFO"
Write-WELog " • Configurable thresholds" " INFO"
Write-WELog " • Multiple notification channels" " INFO"
Write-WELog " • Auto-resolution" " INFO"




} catch {
    Write-Error " Script execution failed: $($_.Exception.Message)"
    throw
}
