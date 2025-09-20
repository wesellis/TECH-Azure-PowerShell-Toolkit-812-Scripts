<#
.SYNOPSIS
    Azure Eventgrid Topic Provisioning Tool

.DESCRIPTION
    Azure automation
#>
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TopicName,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Location,
    [string]$InputSchema = "EventGridSchema" ,
    [hashtable]$Tags = @{}
)
Write-Host "Provisioning Event Grid Topic: $TopicName"
Write-Host "Resource Group: $ResourceGroupName"
Write-Host "Location: $Location"
Write-Host "Input Schema: $InputSchema"
$params = @{
    ErrorAction = "Stop"
    InputSchema = $InputSchema
    ResourceGroupName = $ResourceGroupName
    Name = $TopicName
    Location = $Location
}
$EventGridTopic @params
if ($Tags.Count -gt 0) {
    Write-Host " `nApplying tags:"
    foreach ($Tag in $Tags.GetEnumerator()) {
        Write-Host "  $($Tag.Key): $($Tag.Value)"
    }
    # Apply tags (this would require Set-AzEventGridTopic -ErrorAction Stop in actual implementation)
}
Write-Host " `nEvent Grid Topic $TopicName provisioned successfully"
Write-Host "Topic Endpoint: $($EventGridTopic.Endpoint)"
Write-Host "Provisioning State: $($EventGridTopic.ProvisioningState)"
try {
$Keys = Get-AzEventGridTopicKey -ResourceGroupName $ResourceGroupName -Name $TopicName
    Write-Host " `nAccess Keys:"
    Write-Host "Key 1: $($Keys.Key1.Substring(0,8))... (use for authentication)"
    Write-Host "Key 2: $($Keys.Key2.Substring(0,8))... (backup key)"
} catch {
    Write-Host " `nAccess Keys: Available via Get-AzEventGridTopicKey -ErrorAction Stop cmdlet"
}
Write-Host " `nEvent Publishing:"
Write-Host "Endpoint: $($EventGridTopic.Endpoint)"
Write-Host "Headers Required:"
Write-Host "    aeg-sas-key: [access key]"
Write-Host "    Content-Type: application/json"
Write-Host " `nNext Steps:"
Write-Host " 1. Create event subscriptions for this topic"
Write-Host " 2. Configure event handlers (Azure Functions, Logic Apps, etc.)"
Write-Host " 3. Start publishing events to the topic endpoint"
Write-Host " 4. Monitor event delivery through Azure Portal"
Write-Host " `nSample Event Format (EventGridSchema):"
Write-Information @"
[
  {
    " id" : " unique-id" ,
    " eventType" : "Custom.Event.Type" ,
    " subject" : " /myapp/vehicles/motorcycles" ,
    " eventTime" : " $(Get-Date -Format " yyyy-MM-ddTHH:mm:ssZ" )" ,
    " data" : {
      " make" : "Ducati" ,
      " model" : "Monster"
    },
    " dataVersion" : " 1.0"
  }
]
" @
Write-Host " `nEvent Grid Topic provisioning completed at $(Get-Date)"

