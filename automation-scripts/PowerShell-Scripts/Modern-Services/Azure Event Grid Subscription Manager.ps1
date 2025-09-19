#Requires -Version 7.0
#Requires -Module Az.Resources

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Azure Event Grid Subscription Manager

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules
#>

<#
.SYNOPSIS
    We Enhanced Azure Event Grid Subscription Manager

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }

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
    [ValidateSet(" CreateTopic" , " CreateSubscription" , " ListEvents" , " DeleteTopic" )]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEAction,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETopicName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WESubscriptionName,
    
    [Parameter(Mandatory=$false)]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEEndpointUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$WELocation = " East US"
)

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName " Azure Event Grid Subscription Manager" -Version " 1.0" -Description " Manage Event Grid topics and subscriptions"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.EventGrid'))) {
        throw " Azure connection validation failed"
    }

    switch ($WEAction) {
        " CreateTopic" {
            $topic = New-AzEventGridTopic -ResourceGroupName $WEResourceGroupName -Name $WETopicName -Location $WELocation
            Write-Log " [OK] Event Grid topic created: $WETopicName" -Level SUCCESS
            Write-WELog " Endpoint: $($topic.Endpoint)" " INFO" -ForegroundColor Green
        }
        
        " CreateSubscription" {
            $subscription = New-AzEventGridSubscription -ResourceGroupName $WEResourceGroupName -TopicName $WETopicName -EventSubscriptionName $WESubscriptionName -Endpoint $WEEndpointUrl
            Write-Log " [OK] Event subscription created: $($subscription.EventSubscriptionName)" -Level SUCCESS
        }
        
        " ListEvents" {
           ;  $topic = Get-AzEventGridTopic -ResourceGroupName $WEResourceGroupName -Name $WETopicName
           ;  $subscriptions = Get-AzEventGridSubscription -ResourceGroupName $WEResourceGroupName -TopicName $WETopicName
            
            Write-WELog " Topic: $($topic.Name)" " INFO" -ForegroundColor Cyan
            Write-WELog " Subscriptions: $($subscriptions.Count)" " INFO" -ForegroundColor White
            $subscriptions | Format-Table EventSubscriptionName, Destination
        }
        
        " DeleteTopic" {
            Remove-AzEventGridTopic -ResourceGroupName $WEResourceGroupName -Name $WETopicName -Force
            Write-Log " [OK] Event Grid topic deleted: $WETopicName" -Level SUCCESS
        }
    }

} catch {
    Write-Log "  Event Grid operation failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
