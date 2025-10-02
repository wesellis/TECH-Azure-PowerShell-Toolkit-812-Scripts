#Requires -Version 7.4
#Requires -Modules Az.Resources

<#`n.SYNOPSIS
    Azure Eventgrid Topic Provisioning Tool

.DESCRIPTION
    Azure automation


    Author: Wes Ellis (wes@wesellis.com)
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
    $ErrorActionPreference = "Stop"
    $VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
function Write-Host {
    param(
        [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Message,
        [ValidateSet("INFO" , "WARN" , "ERROR" , "SUCCESS" )]
        $Level = "INFO"
    )
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "Cyan" ; "WARN" = "Yellow" ; "ERROR" = "Red" ; "SUCCESS" = "Green"
    }
    $LogEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Output $LogEntry -ForegroundColor $ColorMap[$Level]
}
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $TopicName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    $Location,
    $InputSchema = "EventGridSchema" ,
    [hashtable]$Tags = @{}
)
Write-Output "Provisioning Event Grid Topic: $TopicName"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "Location: $Location"
Write-Output "Input Schema: $InputSchema"
    $params = @{
    ErrorAction = "Stop"
    InputSchema = $InputSchema
    ResourceGroupName = $ResourceGroupName
    Name = $TopicName
    Location = $Location
}
    $EventGridTopic @params
if ($Tags.Count -gt 0) {
    Write-Output " `nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Output "  $($Tag.Key): $($Tag.Value)"
    }
}
Write-Output " `nEvent Grid Topic $TopicName provisioned successfully"
Write-Output "Topic Endpoint: $($EventGridTopic.Endpoint)"
Write-Output "Provisioning State: $($EventGridTopic.ProvisioningState)"
try {
    $Keys = Get-AzEventGridTopicKey -ResourceGroupName $ResourceGroupName -Name $TopicName
    Write-Output " `nAccess Keys:"
    Write-Output "Key 1: $($Keys.Key1.Substring(0,8))... (use for authentication)"
    Write-Output "Key 2: $($Keys.Key2.Substring(0,8))... (backup key)"
} catch {
    Write-Output " `nAccess Keys: Available via Get-AzEventGridTopicKey -ErrorAction Stop cmdlet"
}
Write-Output " `nEvent Publishing:"
Write-Output "Endpoint: $($EventGridTopic.Endpoint)"
Write-Output "Headers Required:"
Write-Output "    aeg-sas-key: [access key]"
Write-Output "    Content-Type: application/json"
Write-Output " `nNext Steps:"
Write-Output " 1. Create event subscriptions for this topic"
Write-Output " 2. Configure event handlers (Azure Functions, Logic Apps, etc.)"
Write-Output " 3. Start publishing events to the topic endpoint"
Write-Output " 4. Monitor event delivery through Azure Portal"
Write-Output " `nSample Event Format (EventGridSchema):"
Write-Information @"
[
  {
    " id" : " unique-id" ,
    " eventType" : "Custom.Event.Type" ,
    " subject" : "/myapp/vehicles/motorcycles" ,
    " eventTime" : " $(Get-Date -Format " yyyy-MM-ddTHH:mm:ssZ" )" ,
    " data" : {
      " make" : "Ducati" ,
      " model" : "Monster"
    },
    " dataVersion" : " 1.0"
  }
]
" @
Write-Output " `nEvent Grid Topic provisioning completed at $(Get-Date)"



