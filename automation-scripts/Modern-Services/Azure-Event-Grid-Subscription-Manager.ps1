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
# Azure Event Grid Subscription Manager
# Manage Event Grid topics and subscriptions
# Version: 1.0

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("CreateTopic", "CreateSubscription", "ListEvents", "DeleteTopic")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$TopicName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionName,
    
    [Parameter(Mandatory=$false)]
    [string]$EndpointUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US"
)

#region Functions

# Module import removed - use #Requires instead
Show-Banner -ScriptName "Azure Event Grid Subscription Manager" -Version "1.0" -Description "Manage Event Grid topics and subscriptions"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.EventGrid'))) {
        throw "Azure connection validation failed"
    }

    switch ($Action) {
        "CreateTopic" {
            $topic = New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Location $Location
            Write-Log "[OK] Event Grid topic created: $TopicName" -Level SUCCESS
            Write-Information "Endpoint: $($topic.Endpoint)"
        }
        
        "CreateSubscription" {
            $subscription = New-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName -EventSubscriptionName $SubscriptionName -Endpoint $EndpointUrl
            Write-Log "[OK] Event subscription created: $($subscription.EventSubscriptionName)" -Level SUCCESS
        }
        
        "ListEvents" {
            $topic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName
            $subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
            
            Write-Information "Topic: $($topic.Name)"
            Write-Information "Subscriptions: $($subscriptions.Count)"
            $subscriptions | Format-Table EventSubscriptionName, Destination
        }
        
        "DeleteTopic" {
            Remove-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Force
            Write-Log "[OK] Event Grid topic deleted: $TopicName" -Level SUCCESS
        }
    }

} catch {
    Write-Log " Event Grid operation failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}


#endregion
