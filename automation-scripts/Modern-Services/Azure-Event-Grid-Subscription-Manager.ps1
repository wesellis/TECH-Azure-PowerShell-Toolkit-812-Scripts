# Azure Event Grid Subscription Manager
# Manage Event Grid topics and subscriptions
# Author: Wesley Ellis | wes@wesellis.com
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

Import-Module (Join-Path $PSScriptRoot "..\modules\AzureAutomationCommon\AzureAutomationCommon.psm1") -Force
Show-Banner -ScriptName "Azure Event Grid Subscription Manager" -Version "1.0" -Description "Manage Event Grid topics and subscriptions"

try {
    if (-not (Test-AzureConnection -RequiredModules @('Az.EventGrid'))) {
        throw "Azure connection validation failed"
    }

    switch ($Action) {
        "CreateTopic" {
            $topic = New-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Location $Location
            Write-Log "✓ Event Grid topic created: $TopicName" -Level SUCCESS
            Write-Host "Endpoint: $($topic.Endpoint)" -ForegroundColor Green
        }
        
        "CreateSubscription" {
            $subscription = New-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName -EventSubscriptionName $SubscriptionName -Endpoint $EndpointUrl
            Write-Log "✓ Event subscription created: $SubscriptionName" -Level SUCCESS
        }
        
        "ListEvents" {
            $topic = Get-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName
            $subscriptions = Get-AzEventGridSubscription -ResourceGroupName $ResourceGroupName -TopicName $TopicName
            
            Write-Host "Topic: $($topic.Name)" -ForegroundColor Cyan
            Write-Host "Subscriptions: $($subscriptions.Count)" -ForegroundColor White
            $subscriptions | Format-Table EventSubscriptionName, Destination
        }
        
        "DeleteTopic" {
            Remove-AzEventGridTopic -ResourceGroupName $ResourceGroupName -Name $TopicName -Force
            Write-Log "✓ Event Grid topic deleted: $TopicName" -Level SUCCESS
        }
    }

} catch {
    Write-Log "❌ Event Grid operation failed: $($_.Exception.Message)" -Level ERROR
    exit 1
}
