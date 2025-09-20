<#
.SYNOPSIS
    Autosnooze Stopvm Child

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
 Script for deleting the resource groups
 Script for deleting the resource groups
.\AutoSnooze_StopVM_Child.ps1
Version History
v1.0   - redmond\balas - Initial Release
[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [object]$WebhookData
)
if ($null -ne $WebhookData) {
    # Collect properties of WebhookData.
    $WebhookName    =   $WebhookData.WebhookName
    $WebhookBody    =   $WebhookData.RequestBody
    $WebhookHeaders =   $WebhookData.RequestHeader
    # Information on the webhook name that called This
    Write-Output "This runbook was started from webhook $WebhookName."
    # Obtain the WebhookBody containing the AlertContext
    $WebhookBody = (ConvertFrom-Json -InputObject $WebhookBody)
    Write-Output " `nWEBHOOK BODY"
    Write-Output " ============="
    Write-Output $WebhookBody
    # Obtain the AlertContext
    $AlertContext = [object]$WebhookBody.context
    # Some selected AlertContext information
    Write-Output " `nALERT CONTEXT DATA"
    Write-Output " ==================="
    Write-Output $AlertContext.name
    Write-Output $AlertContext.subscriptionId
    Write-Output $AlertContext.resourceGroupName
    Write-Output $AlertContext.resourceName
    Write-Output $AlertContext.resourceType
    Write-Output $AlertContext.resourceId
    Write-Output $AlertContext.timestamp
    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName
        "Logging in to Azure..."
        $params = @{
            Message = $_.Exception throw $_.Exception } }  ;  $Status = Stop-AzureRmVM
            Name = $AlertContext.resourceName
            ApplicationId = $servicePrincipalConnection.ApplicationId
            Force = "if($null"
            eq = $Status) { Write-Output "Error occured while stopping the Virtual Machine. $AlertContext.resourceName" } else { Write-Output "Successfully stopped the VM $AlertContext.resourceName" }
            ResourceGroupName = $AlertContext.resourceGroupName
            TenantId = $servicePrincipalConnection.TenantId
            CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint } catch { if (!$servicePrincipalConnection) { ;  $ErrorMessage = "Connection $connectionName not found." throw $ErrorMessage } else{ Write-Error
        }
        Add-AzureRmAccount @params
}
else
{
    Write-Error "This runbook is meant to only be started from a webhook."
}\n