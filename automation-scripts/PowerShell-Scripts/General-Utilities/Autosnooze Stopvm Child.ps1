#Requires -Version 7.0

<#
#endregion

#region Main-Execution
.SYNOPSIS
    Autosnooze Stopvm Child

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
    We Enhanced Autosnooze Stopvm Child

.DESCRIPTION
    Professional PowerShell script for enterprise automation.
    Optimized for performance, reliability, and error handling.

.AUTHOR
    Wes Ellis (wes@wesellis.com)

.VERSION
    1.0

.NOTES
    Requires appropriate permissions and modules


<#
.SYNOPSIS  
 Script for deleting the resource groups
.DESCRIPTION  
 Script for deleting the resource groups
.EXAMPLE  
.\AutoSnooze_StopVM_Child.ps1 
Version History  
v1.0   - redmond\balas - Initial Release  


[CmdletBinding()]
$ErrorActionPreference = "Stop"
param(
    [object]$WEWebhookData
)

#region Functions

if ($null -ne $WEWebhookData) {  
    # Collect properties of WebhookData.
    $WEWebhookName    =   $WEWebhookData.WebhookName
    $WEWebhookBody    =   $WEWebhookData.RequestBody
    $WEWebhookHeaders =   $WEWebhookData.RequestHeader
       
    # Information on the webhook name that called This
    Write-Output " This runbook was started from webhook $WEWebhookName."
       
    # Obtain the WebhookBody containing the AlertContext
    $WEWebhookBody = (ConvertFrom-Json -InputObject $WEWebhookBody)
    Write-Output " `nWEBHOOK BODY"
    Write-Output " ============="
    Write-Output $WEWebhookBody
       
    # Obtain the AlertContext
    $WEAlertContext = [object]$WEWebhookBody.context

    # Some selected AlertContext information
    Write-Output " `nALERT CONTEXT DATA"
    Write-Output " ==================="
    Write-Output $WEAlertContext.name
    Write-Output $WEAlertContext.subscriptionId
    Write-Output $WEAlertContext.resourceGroupName
    Write-Output $WEAlertContext.resourceName
    Write-Output $WEAlertContext.resourceType
    Write-Output $WEAlertContext.resourceId
    Write-Output $WEAlertContext.timestamp
      
    $connectionName = " AzureRunAsConnection"
    try
    {
        # Get the connection " AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

        " Logging in to Azure..."
        $params = @{
            Message = $_.Exception throw $_.Exception } }  ;  $WEStatus = Stop-AzureRmVM
            Name = $WEAlertContext.resourceName
            ApplicationId = $servicePrincipalConnection.ApplicationId
            Force = "if($null"
            eq = $WEStatus) { Write-Output " Error occured while stopping the Virtual Machine. $WEAlertContext.resourceName" } else { Write-Output " Successfully stopped the VM $WEAlertContext.resourceName" }
            ResourceGroupName = $WEAlertContext.resourceGroupName
            TenantId = $servicePrincipalConnection.TenantId
            CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint } catch { if (!$servicePrincipalConnection) { ;  $WEErrorMessage = " Connection $connectionName not found." throw $WEErrorMessage } else{ Write-Error
        }
        Add-AzureRmAccount @params
}
else 
{
    Write-Error " This runbook is meant to only be started from a webhook." 
}


# Wesley Ellis Enterprise PowerShell Toolkit
# Enhanced automation solutions: wesellis.com

#endregion
