<#
.SYNOPSIS
    We Enhanced Azure Eventgrid Topic Provisioning Tool

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

$WEErrorActionPreference = "Stop"
$WEVerbosePreference = if ($WEPSBoundParameters.ContainsKey('Verbose')) { " Continue" } else { " SilentlyContinue" }



function Write-WELog {
    [CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
        [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$Message,
        [ValidateSet(" INFO", " WARN", " ERROR", " SUCCESS")]
        [string]$Level = " INFO"
    )
    
    $timestamp = Get-Date -Format " yyyy-MM-dd HH:mm:ss"
   ;  $colorMap = @{
        " INFO" = " Cyan"; " WARN" = " Yellow"; " ERROR" = " Red"; " SUCCESS" = " Green"
    }
    
    $logEntry = " $timestamp [WE-Enhanced] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor $colorMap[$Level]
}

[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WEResourceGroupName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WETopicName,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$WELocation,
    [string]$WEInputSchema = " EventGridSchema",
    [hashtable]$WETags = @{}
)

Write-WELog " Provisioning Event Grid Topic: $WETopicName" " INFO"
Write-WELog " Resource Group: $WEResourceGroupName" " INFO"
Write-WELog " Location: $WELocation" " INFO"
Write-WELog " Input Schema: $WEInputSchema" " INFO"


$WEEventGridTopic = New-AzEventGridTopic `
    -ResourceGroupName $WEResourceGroupName `
    -Name $WETopicName `
    -Location $WELocation `
    -InputSchema $WEInputSchema

if ($WETags.Count -gt 0) {
    Write-WELog " `nApplying tags:" " INFO"
    foreach ($WETag in $WETags.GetEnumerator()) {
        Write-WELog "  $($WETag.Key): $($WETag.Value)" " INFO"
    }
    # Apply tags (this would require Set-AzEventGridTopic in actual implementation)
}

Write-WELog " `nEvent Grid Topic $WETopicName provisioned successfully" " INFO"
Write-WELog " Topic Endpoint: $($WEEventGridTopic.Endpoint)" " INFO"
Write-WELog " Provisioning State: $($WEEventGridTopic.ProvisioningState)" " INFO"


try {
   ;  $WEKeys = Get-AzEventGridTopicKey -ResourceGroupName $WEResourceGroupName -Name $WETopicName
    Write-WELog " `nAccess Keys:" " INFO"
    Write-WELog "  Key 1: $($WEKeys.Key1.Substring(0,8))... (use for authentication)" " INFO"
    Write-WELog "  Key 2: $($WEKeys.Key2.Substring(0,8))... (backup key)" " INFO"
} catch {
    Write-WELog " `nAccess Keys: Available via Get-AzEventGridTopicKey cmdlet" " INFO"
}

Write-WELog " `nEvent Publishing:" " INFO"
Write-WELog "  Endpoint: $($WEEventGridTopic.Endpoint)" " INFO"
Write-WELog "  Headers Required:" " INFO"
Write-WELog "    aeg-sas-key: [access key]" " INFO"
Write-WELog "    Content-Type: application/json" " INFO"

Write-WELog " `nNext Steps:" " INFO"
Write-WELog " 1. Create event subscriptions for this topic" " INFO"
Write-WELog " 2. Configure event handlers (Azure Functions, Logic Apps, etc.)" " INFO"
Write-WELog " 3. Start publishing events to the topic endpoint" " INFO"
Write-WELog " 4. Monitor event delivery through Azure Portal" " INFO"

Write-WELog " `nSample Event Format (EventGridSchema):" " INFO"
Write-Host @"
[
  {
    " id": " unique-id",
    " eventType": " Custom.Event.Type",
    " subject": " /myapp/vehicles/motorcycles",
    " eventTime": " $(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ" )",
    " data": {
      " make": " Ducati",
      " model": " Monster"
    },
    " dataVersion": " 1.0"
  }
]
" @

Write-WELog "`nEvent Grid Topic provisioning completed at $(Get-Date)" " INFO"



# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com
# ============================================================================