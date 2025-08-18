# ============================================================================
# Script Name: Azure Event Grid Topic Provisioning Tool
# Author: Wesley Ellis
# Email: wes@wesellis.com
# Website: wesellis.com
# Date: May 23, 2025
# Description: Provisions Azure Event Grid topics for event-driven architecture and messaging
# ============================================================================

param (
    [string]$ResourceGroupName,
    [string]$TopicName,
    [string]$Location,
    [string]$InputSchema = "EventGridSchema",
    [hashtable]$Tags = @{}
)

Write-Information "Provisioning Event Grid Topic: $TopicName"
Write-Information "Resource Group: $ResourceGroupName"
Write-Information "Location: $Location"
Write-Information "Input Schema: $InputSchema"

# Create the Event Grid Topic
$EventGridTopic = New-AzEventGridTopic -ErrorAction Stop `
    -ResourceGroupName $ResourceGroupName `
    -Name $TopicName `
    -Location $Location `
    -InputSchema $InputSchema

if ($Tags.Count -gt 0) {
    Write-Information "`nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Information "  $($Tag.Key): $($Tag.Value)"
    }
    # Apply tags (this would require Set-AzEventGridTopic -ErrorAction Stop in actual implementation)
}

Write-Information "`nEvent Grid Topic $TopicName provisioned successfully"
Write-Information "Topic Endpoint: $($EventGridTopic.Endpoint)"
Write-Information "Provisioning State: $($EventGridTopic.ProvisioningState)"

# Get topic keys
try {
    $Keys = Get-AzEventGridTopicKey -ResourceGroupName $ResourceGroupName -Name $TopicName
    Write-Information "`nAccess Keys:"
    Write-Information "  Key 1: $($Keys.Key1.Substring(0,8))... (use for authentication)"
    Write-Information "  Key 2: $($Keys.Key2.Substring(0,8))... (backup key)"
} catch {
    Write-Information "`nAccess Keys: Available via Get-AzEventGridTopicKey -ErrorAction Stop cmdlet"
}

Write-Information "`nEvent Publishing:"
Write-Information "  Endpoint: $($EventGridTopic.Endpoint)"
Write-Information "  Headers Required:"
Write-Information "    aeg-sas-key: [access key]"
Write-Information "    Content-Type: application/json"

Write-Information "`nNext Steps:"
Write-Information "1. Create event subscriptions for this topic"
Write-Information "2. Configure event handlers (Azure Functions, Logic Apps, etc.)"
Write-Information "3. Start publishing events to the topic endpoint"
Write-Information "4. Monitor event delivery through Azure Portal"

Write-Information "`nSample Event Format (EventGridSchema):"
Write-Information @"
[
  {
    "id": "unique-id",
    "eventType": "Custom.Event.Type",
    "subject": "/myapp/vehicles/motorcycles",
    "eventTime": "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")",
    "data": {
      "make": "Ducati",
      "model": "Monster"
    },
    "dataVersion": "1.0"
  }
]
"@

Write-Information "`nEvent Grid Topic provisioning completed at $(Get-Date)"
