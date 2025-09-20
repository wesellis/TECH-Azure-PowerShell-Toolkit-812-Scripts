<#
.SYNOPSIS
    Stop Azurev2Vmrunbook

.DESCRIPTION
    Azure automation
    Wes Ellis (wes@wesellis.com)

    1.0
    Requires appropriate permissions and modules
#>
$ErrorActionPreference = "Stop"
$VerbosePreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }
  Azure Automation runbook that stops of all VMs in the specified Azure subscription or resource group
  This Azure runbook connects to Azure and stops all VMs in an Azure subscription or resource group.
  You can attach a schedule to this runbook to run it at a specific time. Note that this runbook does not stop
  Azure classic VMs. Use https://gallery.technet.microsoft.com/scriptcenter/Stop-Azure-Classic-VMs-7a4ae43e for that.
.PARAMETER automationConnectionName
   Optional with default of "AzureRunAsConnection" .
   The name of an Automation Connection used to authenticate
.PARAMETER ResourceGroupName
   Required
   Allows you to specify the resource group containing the VMs to stop.
   If this parameter is included, only VMs in the specified resource group will be stopped, otherwise all VMs in the subscription will be stopped.
   AUTHOR: Jeff Bowles
   LASTEDIT: Sept 6, 2016
[CmdletBinding()]
param(
    [Parameter()]
    [string]$automationConnectionName = 'AzureRunAsConnection',
    [Parameter()]
    [String] $ResourceGroupName
)
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $automationConnectionName
    # Log into Azure
    $params = @{
        ApplicationId = $servicePrincipalConnection.ApplicationId
        TenantId = $servicePrincipalConnection.TenantId
        CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
    }
    $login @params
}
catch
{
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
write-output "Logged in as $($login.Context.Account.id) to subscriptionID $($login.Context.Subscription.SubscriptionId)."
if ($ResourceGroupName)
{
	$VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
}
else
{
	$VMs = Get-AzureRmVM -ErrorAction Stop
}
foreach ($VM in $VMs)
{
	$vmName = $vm.Name
    $ResourceGroupName = $vm.resourceGroupName
$status = ((Get-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $vmName -status).Statuses|where{$_.Code -like 'PowerState*'}).DisplayStatus
    if($status -ne 'VM deallocated')
    {
$stopRtn = Stop-AzureRMVM -Name $VMName -ResourceGroupName $resourceGroupName -force -ea SilentlyContinue
		if (-not($StopRtn))
		{
			# The VM failed to stop, so send notice
        	Write-Output ($VMName + " failed to stop" )
        	Write-Error ($VMName + " failed to stop. Error was:" ) -ErrorAction Continue
			Write-Error (ConvertTo-Json $StopRtn.Error) -ErrorAction Continue
		}
		else
		{
			# The VM stopped, so send notice
			Write-Output ($VMName + " has been stopped" )
		}
	}
	else
	{
		Write-Output ($VMName + " is already stopped" )
	}
}\n